import Foundation
import SwiftUI
import GardenCore
import Darwin

@MainActor final class GardenStore: ObservableObject {
    @Published var state = GardenState()
    @Published var error: String?
    @Published var parentOpen = false
    @Published var parentUnlocked = false
    @Published var recap = false
    @Published var active = true
    let bank: [Question]
    let allowsDrafts: Bool
    private let url: URL
    private let now: () -> Date
    private let uptime: () -> TimeInterval
    init(url: URL? = nil, bank: [Question]? = nil, allowsDrafts: Bool? = nil,
         now: @escaping () -> Date = Date.init, uptime: (() -> TimeInterval)? = nil) {
        self.now = now
        self.uptime = uptime ?? { Self.continuousTime }
        #if DEBUG
        self.allowsDrafts = allowsDrafts ?? true
        #else
        self.allowsDrafts = allowsDrafts ?? false
        #endif
        self.url = url ?? URL.applicationSupportDirectory.appending(path: "CuriosityGarden/state.json")
        if let bank { self.bank = bank }
        else if let bankURL = Bundle.main.url(forResource: "questions", withExtension: "json"),
           let data = try? Data(contentsOf: bankURL), let decoded = try? JSONDecoder().decode([Question].self, from: data) {
            self.bank = decoded
        } else { self.bank = [] }
        do { state = try JSONDecoder().decode(GardenState.self, from: Data(contentsOf: self.url)) }
        catch { if FileManager.default.fileExists(atPath: self.url.path) { self.error = "Saved progress could not be read. Play is paused to protect your session limit." } }
        state.prune(now: now())
        state.validateResumedContent(allowDrafts: self.allowsDrafts)
        recap = state.round?.needsRecap ?? false
        if let grade = state.grade {
            let previous = state.clock.totalPlay
            state.clock.update(now: now(), uptime: self.uptime(), wantsPlay: false, grade: grade, restored: true)
            state.recordPlay(seconds: state.clock.totalPlay - previous, on: now()); save()
        }
    }
    // Continuous boot time includes device sleep, so an ordinary locked-device
    // break is not mistaken for a clock change or restart.
    private static var continuousTime: TimeInterval {
        var scale = mach_timebase_info_data_t()
        mach_timebase_info(&scale)
        return Double(mach_continuous_time()) * Double(scale.numer) / Double(scale.denom) / 1_000_000_000
    }
    var blocked: Bool { state.clock.remainingBreak(now: now(), grade: state.grade ?? 0) > 0 }
    var wantsPlay: Bool { active && !parentOpen && state.grade != nil && error == nil }
    func save() {
        do {
            try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            try JSONEncoder().encode(state).write(to: url, options: [.atomic, .completeFileProtection])
            var directory = url.deletingLastPathComponent(); var values = URLResourceValues(); values.isExcludedFromBackup = true; try directory.setResourceValues(values)
        } catch { self.error = "Progress could not be saved. Play is paused. Please free device storage and reopen the app." }
    }
    func tick() {
        guard let grade = state.grade else { return }
        let previous = state.clock.totalPlay
        state.clock.update(now: now(), uptime: self.uptime(), wantsPlay: wantsPlay, grade: grade)
        state.recordPlay(seconds: state.clock.totalPlay - previous, on: now())
        state.prune(now: now())
        if blocked { recap = true; state.round?.end(.sessionLimit) }
        save()
    }
    func setup(grade: Int) {
        state.grade = grade
        for subject in Subject.allCases where state.progress[subject] == nil { state.progress[subject] = SubjectProgress(level: grade) }
        save()
    }
    func updateReading(_ preferences: ReadingPreferences) {
        guard parentUnlocked else { return }
        state.readingPreferences = preferences; save()
    }
    func reportHistory(_ window: ReportWindow) -> [AnswerRecord] { window.history(state.history, now: now()) }
    func reportSeconds(_ window: ReportWindow) -> TimeInterval { window.seconds(in: state.playDays ?? [], now: now()) }
    func start() {
        tick(); guard !blocked && error == nil else { return }
        if state.round == nil || state.round!.finished(grade: state.grade ?? 0) || recap { state.round = Round() }
        recap = false; next(); tick()
    }
    func next() {
        tick(); guard !blocked, let grade = state.grade, var round = state.round, error == nil else { return }
        if round.finished(grade: grade) {
            round.end(.completed); state.round = round; recap = true; save(); return
        }
        round.response = nil
        round.pending = QuestionPicker.pick(bank: bank, grade: grade, progress: state.progress, round: round, history: state.history, allowDrafts: allowsDrafts, now: now(), sessionID: state.clock.id)
        if round.pending == nil { round.end(.contentUnavailable); recap = true }
        state.round = round
        save()
    }
    func answer(_ response: Response) {
        tick(); guard !blocked, var round = state.round, let question = round.pending, round.response == nil, error == nil else { return }
        var progress = state.progress[question.subject] ?? SubjectProgress(level: state.grade ?? 0)
        let oldLevel = progress.level
        progress.answer(correct: response == .choice(question.correct))
        state.progress[question.subject] = progress
        let record = AnswerRecord(roundID: round.id, question: question, response: response, date: now(), levelAfter: progress.level, sessionID: state.clock.id)
        round.record(record, oldLevel: oldLevel); state.history.append(record); state.round = round; save()
    }
    func lifecycle(_ phase: ScenePhase) {
        active = phase == .active
        if !active { parentUnlocked = false; parentOpen = false }
        tick()
    }
}
