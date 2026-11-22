import Foundation
import SwiftUI
import GardenCore
import Darwin
import LocalAuthentication

@MainActor final class GardenStore: ObservableObject {
    @Published var state = GardenState()
    @Published var error: String?
    @Published var parentOpen = false
    @Published var parentUnlocked = false
    @Published var recap = false
    @Published var active = true
    @Published private(set) var recoveringPIN = false
    let bank: [Question]
    let allowsDrafts: Bool
    private let url: URL
    private let now: () -> Date
    private let uptime: () -> TimeInterval
    private let authenticationContext: () -> LAContext
    private let pinService: String
    private var recoveryContext: LAContext?
    private var recoveryID: UUID?
    init(url: URL? = nil, bank: [Question]? = nil, allowsDrafts: Bool? = nil,
         now: @escaping () -> Date = Date.init, uptime: (() -> TimeInterval)? = nil,
         authenticationContext: @escaping () -> LAContext = LAContext.init, pinService: String = ParentPIN.service) {
        self.now = now
        self.uptime = uptime ?? { Self.continuousTime }
        self.authenticationContext = authenticationContext
        self.pinService = pinService
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
        state.validateResumedContent(allowDrafts: hasDraftContent)
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
    var reviewedQuestionCount: Int { bank.filter { $0.status == .reviewed && $0.valid }.count }
    var draftQuestionCount: Int { bank.filter { $0.status == .draft && $0.valid }.count }
    var hasDraftContent: Bool { allowsDrafts && draftQuestionCount > 0 }
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
    enum PINRecoveryResult: Equatable {
        case success, invalidPIN, unavailable, cancelled, saveFailed
        var message: String {
            switch self {
            case .success: "PIN reset. Enter your new PIN to unlock."
            case .invalidPIN: "Choose matching six-digit PINs."
            case .unavailable: "Device authentication is unavailable. Make sure a device passcode is set up in Settings, then try again."
            case .cancelled: "PIN not changed. Device authentication was cancelled or unsuccessful."
            case .saveFailed: "PIN could not be saved. Try again."
            }
        }
    }
    func recoverParentPIN(replacement: String, confirmation: String) async -> PINRecoveryResult {
        guard active, parentOpen, !parentUnlocked, !recoveringPIN else { return .cancelled }
        guard replacement == confirmation, ParentPIN.isValid(replacement) else { return .invalidPIN }
        guard ParentPIN.hasPIN(service: pinService) else { return .saveFailed }
        let context = authenticationContext()
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: nil) else {
            context.invalidate(); return .unavailable
        }
        let attempt = UUID()
        recoveryID = attempt; recoveryContext = context; recoveringPIN = true
        defer {
            context.invalidate()
            if recoveryID == attempt { recoveryID = nil; recoveryContext = nil; recoveringPIN = false }
        }
        // Keep LAContext on the main actor. Only the Boolean result crosses
        // from the system callback; older Swift 6 SDKs don't mark LAContext Sendable.
        let authenticated = await withCheckedContinuation { continuation in
            context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: "Reset your Curiosity Garden parent PIN.") { success, _ in
                continuation.resume(returning: success)
            }
        }
        // A late reply after closing or backgrounding must never replace the PIN.
        guard authenticated, !Task.isCancelled, recoveryID == attempt, parentOpen else { return .cancelled }
        return ParentPIN.create(replacement, service: pinService) ? .success : .saveFailed
    }
    func closeParent() {
        recoveryID = nil; recoveryContext?.invalidate(); recoveryContext = nil; recoveringPIN = false
        parentUnlocked = false; parentOpen = false; tick()
    }
    func lifecycle(_ phase: ScenePhase) {
        active = phase == .active
        if !active {
            parentUnlocked = false
            // The system authentication prompt can temporarily make the app inactive.
            // Keep only the locked recovery form; backgrounding always cancels it.
            if phase == .background || !recoveringPIN { closeParent() }
        }
        tick()
    }
}
