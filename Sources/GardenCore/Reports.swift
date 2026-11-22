import Foundation

public struct SubjectReport: Sendable {
    public let subject: Subject
    public let level: Int
    public let records: [AnswerRecord]
    public init(subject: Subject, level: Int, history: [AnswerRecord]) {
        self.subject = subject; self.level = level
        records = history.filter { $0.question.subject == subject }.sorted { $0.date < $1.date }
    }
    public var accuracyText: String {
        guard !records.isEmpty else { return "No answers yet" }
        let correct = records.filter(\.correct).count
        let percent = Int(Double(correct) / Double(records.count) * 100)
        return "\(correct) correct of \(records.count) attempts (\(percent)%)"
    }
    public var difficultyText: String {
        let trend: String
        if let first = records.first, let last = records.last {
            trend = last.levelAfter > first.levelAfter ? "Moving to harder material" : last.levelAfter < first.levelAfter ? "Practicing foundations" : "Steady"
        } else { trend = "No trend yet" }
        return "Difficulty: \(Self.gradeName(level)) · \(trend)"
    }
    public var needsPractice: Bool { records.suffix(5).contains { !$0.correct } }
    public static func gradeName(_ grade: Int) -> String { grade == 0 ? "K" : "Grade \(grade)" }
    public static func answerText(_ record: AnswerRecord) -> String {
        guard case let .choice(index) = record.response else { return "I'm not sure" }
        guard record.question.choices.indices.contains(index) else { return "Answer unavailable" }
        return record.question.choices[index]
    }
}
