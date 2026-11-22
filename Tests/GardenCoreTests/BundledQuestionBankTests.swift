import XCTest
@testable import GardenCore

final class BundledQuestionBankTests: XCTestCase {
    private func bank() throws -> [Question] {
        let url = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
            .deletingLastPathComponent().appending(path: "App/questions.json")
        return try JSONDecoder().decode([Question].self, from: Data(contentsOf: url))
    }
    func testEverySubjectAndDifficultyHasContentAcrossReadingCeilings() throws {
        let questions = try bank()
        for subject in Subject.allCases {
            for level in 0...5 {
                let matching = questions.filter { $0.subject == subject && $0.level == level }
                XCTAssertGreaterThanOrEqual(matching.count, 40)
                for reading in 0...5 {
                    XCTAssertGreaterThanOrEqual(matching.filter { $0.readingGrade <= reading }.count, 8,
                                                "\(subject) level \(level), reading ceiling \(reading)")
                }
            }
        }
    }
    func testBankSuppliesMaximumMixedRoundsAtEveryReadingCeilingAndDifficulty() throws {
        let questions = try bank()
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        for grade in 0...5 {
            for level in 0...5 {
                let progress = Dictionary(uniqueKeysWithValues: Subject.allCases.map { ($0, SubjectProgress(level: level)) })
                var round = Round()
                while !round.finished(grade: grade) {
                    let question = try XCTUnwrap(QuestionPicker.pick(bank: questions, grade: grade, progress: progress,
                        round: round, history: [], allowDrafts: false, now: now))
                    XCTAssertEqual(question.level, level)
                    XCTAssertLessThanOrEqual(question.readingGrade, grade)
                    // Keep calibration pending to exercise the full allowed round capacity.
                    round.record(AnswerRecord(roundID: round.id, question: question, response: .choice(question.correct),
                        date: now, levelAfter: level), oldLevel: level == 0 ? 1 : level - 1)
                }
                let maximum = grade <= 2 ? 14 : 20
                XCTAssertEqual(round.answers.count, maximum)
                XCTAssertEqual(round.answers.filter { $0.question.subject.isSchool }.count, maximum / 2)
                XCTAssertEqual(Set(round.answers.map { $0.question.id }).count, maximum)
            }
        }
    }
}
