import Foundation

public enum Subject: String, Codable, CaseIterable, Sendable {
    case math, reading, science, world, nature, everyday
    public var isSchool: Bool { [.math, .reading, .science].contains(self) }
    public var title: String { rawValue.capitalized }
}
public enum Response: Codable, Equatable, Sendable { case choice(Int), unsure }
public enum ReviewStatus: String, Codable, Sendable { case draft, reviewed }
public struct Question: Codable, Identifiable, Equatable, Sendable {
    public var id: String
    public var subject: Subject
    public var level: Int
    public var readingGrade: Int
    public var prompt: String
    public var choices: [String]
    public var correct: Int
    public var explanation: String
    public var status: ReviewStatus
    public var source: String
    public var reviewer: String?
    public var reviewedAt: Date?
    public init(id: String, subject: Subject, level: Int, readingGrade: Int, prompt: String, choices: [String], correct: Int, explanation: String, status: ReviewStatus = .draft, source: String, reviewer: String? = nil, reviewedAt: Date? = nil) {
        self.id = id; self.subject = subject; self.level = level; self.readingGrade = readingGrade; self.prompt = prompt; self.choices = choices; self.correct = correct; self.explanation = explanation; self.status = status; self.source = source; self.reviewer = reviewer; self.reviewedAt = reviewedAt
    }
    public var valid: Bool { (0...5).contains(level) && (0...5).contains(readingGrade) && (2...4).contains(choices.count) && choices.indices.contains(correct) && Set(choices).count == choices.count && !prompt.isEmpty && !explanation.isEmpty && !source.isEmpty && (status == .draft || (reviewer?.isEmpty == false && reviewedAt != nil)) }
}
public struct SubjectProgress: Codable, Equatable, Sendable {
    public var level: Int
    public var streak = 0
    public init(level: Int) { self.level = min(5, max(0, level)) }
    public mutating func answer(correct: Bool) {
        if correct { streak += 1; if streak == 10 { level = min(5, level + 1); streak = 0 } }
        else { streak = 0; level = max(0, level - 1) }
    }
}
public struct AnswerRecord: Codable, Identifiable, Sendable {
    public var id = UUID()
    public var sessionID: UUID?
    public var roundID: UUID
    public var question: Question
    public var response: Response
    public var date: Date
    public var levelAfter: Int
    public var correct: Bool { response == .choice(question.correct) }
    public init(roundID: UUID, question: Question, response: Response, date: Date, levelAfter: Int, sessionID: UUID? = nil) { self.sessionID = sessionID; self.roundID = roundID; self.question = question; self.response = response; self.date = date; self.levelAfter = levelAfter }
}
public enum RoundEndReason: String, Codable, Sendable { case completed, sessionLimit, contentUnavailable }
public struct Round: Codable, Sendable {
    public var endReason: RoundEndReason?
    public var needsRecap: Bool { endReason != nil || pending == nil }
    public mutating func end(_ reason: RoundEndReason) { endReason = reason; pending = nil; response = nil }
    public var id = UUID()
    public var answers: [AnswerRecord] = []
    public var pending: Question?
    public var response: Response?
    public var calibration: [Subject: Int] = [:]
    public init() {}
    public mutating func record(_ answer: AnswerRecord, oldLevel: Int) {
        answers.append(answer); response = answer.response
        if oldLevel != answer.levelAfter { calibration[answer.question.subject] = 0 }
        else if let count = calibration[answer.question.subject], answer.question.level == answer.levelAfter { calibration[answer.question.subject] = count + 1 }
    }
    public func finished(grade: Int) -> Bool {
        let count = answers.count
        let maximum = grade <= 2 ? 14 : 20
        // Finish extensions in pairs to preserve the even mix within the 15/20 bounds.
        return count >= maximum || (count >= 10 && count.isMultiple(of: 2) && calibration.values.allSatisfy { $0 >= 2 })
    }
}
public enum QuestionPicker {
    public static func pick(bank: [Question], grade: Int, progress: [Subject: SubjectProgress], round: Round, history: [AnswerRecord], allowDrafts: Bool, now: Date, sessionID: UUID? = nil) -> Question? {
        let school = round.answers.count.isMultiple(of: 2)
        let used = Set(round.answers.map { $0.question.id })
        let eligible = bank.filter { $0.valid && (allowDrafts || $0.status == .reviewed) && $0.readingGrade <= grade && $0.subject.isSchool == school && !used.contains($0.id) }
        let needsCalibration = Set(round.calibration.filter { $0.value < 2 }.map(\.key))
        let seen = Dictionary(grouping: history, by: { $0.question.id })
        // Every fifth position alternates school/general across a ten-question round.
        let reviewSlot = round.answers.count % 5 == 4
        let nearest = Dictionary(grouping: eligible, by: \.subject).mapValues { questions in
            questions.map { abs($0.level - (progress[$0.subject]?.level ?? grade)) }.min() ?? 0
        }
        return eligible.sorted { a, b in
            func rank(_ q: Question) -> [Int] {
                let records = seen[q.id] ?? []
                let latest = records.max(by: { $0.date < $1.date })
                let distance = abs(q.level - (progress[q.subject]?.level ?? grade))
                let review: Bool
                if let latest {
                    review = reviewSlot && !latest.correct && latest.roundID != round.id
                        && (sessionID == nil || latest.sessionID != sessionID)
                        && now.timeIntervalSince(latest.date) >= 1800 && distance == nearest[q.subject]
                } else { review = false }
                let uses = round.answers.filter { $0.question.subject == q.subject }.count
                return [needsCalibration.contains(q.subject) ? 0 : 1, review ? 0 : 1, uses, distance, records.isEmpty ? 0 : 1]
            }
            let ar = rank(a), br = rank(b)
            if ar != br { return ar.lexicographicallyPrecedes(br) }
            return a.id < b.id
        }.first
    }
}
