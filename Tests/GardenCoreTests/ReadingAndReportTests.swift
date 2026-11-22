import XCTest
@testable import GardenCore

final class ReadingAndReportTests: XCTestCase {
    let now = Date(timeIntervalSince1970: 1_800_000_000)
    var calendar: Calendar { var value = Calendar(identifier: .gregorian); value.timeZone = TimeZone(secondsFromGMT: 0)!; return value }
    func record(id: String, correct: Bool, date: Date, subject: Subject = .math) -> AnswerRecord {
        let question = Question(id: id, subject: subject, level: 0, readingGrade: 0, prompt: id, choices: ["A", "B"], correct: 0, explanation: "Fact \(id)", source: "Original fixture")
        return AnswerRecord(roundID: UUID(), question: question, response: correct ? .choice(0) : .unsure, date: date, levelAfter: 0)
    }
    func testReadingPreferencesAreLargeScalableInputsAndCodable() throws {
        XCTAssertEqual(GardenState().reading, ReadingPreferences())
        XCTAssertEqual(ReadingFont.allCases.map(\.title), ["Standard sans serif", "Rounded sans serif"])
        XCTAssertEqual(ReadingSize.allCases.map(\.title), ["Large", "Extra large"])
        let large = ReadingPreferences(), extra = ReadingPreferences(font: .rounded, size: .extraLarge)
        XCTAssertEqual(ReadingRole.allCases.map { large.points(for: $0) }, [26, 22, 20, 14])
        XCTAssertEqual(ReadingRole.allCases.map { extra.points(for: $0) }, [28, 24, 22, 16])
        var state = GardenState(); state.readingPreferences = extra
        let restored = try JSONDecoder().decode(GardenState.self, from: JSONEncoder().encode(state))
        XCTAssertEqual(restored.reading, extra)
    }
    func testReportPeriodsIncludeTodayAndRespectDateBoundaries() {
        for period in ReportWindow.allCases {
            XCTAssertEqual(period.title, "Last \(period.days) days")
            let start = period.start(now: now, calendar: calendar)
            let history = [record(id: "before", correct: true, date: start - 1), record(id: "start", correct: true, date: start), record(id: "today", correct: false, date: now), record(id: "future", correct: true, date: now + 1)]
            XCTAssertEqual(period.history(history, now: now, calendar: calendar).map { $0.question.id }, ["start", "today"])
            let days = [PlayDay(date: start - 86400, seconds: 40), PlayDay(date: start, seconds: 20), PlayDay(date: calendar.startOfDay(for: now), seconds: 60), PlayDay(date: now + 86400, seconds: 90)]
            XCTAssertEqual(period.seconds(in: days, now: now, calendar: calendar), 80)
            XCTAssertEqual(period.seconds(in: [], now: now, calendar: calendar), 0)
        }
    }
    func testReportWindowUsesCalendarDaysAcrossDaylightSaving() {
        var local = Calendar(identifier: .gregorian); local.timeZone = TimeZone(identifier: "America/Los_Angeles")!
        let date = local.date(from: DateComponents(year: 2026, month: 3, day: 9, hour: 12))!
        let start = ReportWindow.week.start(now: date, calendar: local)
        XCTAssertEqual(local.dateComponents([.year, .month, .day, .hour], from: start), DateComponents(year: 2026, month: 3, day: 3, hour: 0))
    }
    func testPlayLedgerAggregatesPersistsAndPrunesWithoutResettingLearning() throws {
        var state = GardenState(); state.progress[.math] = SubjectProgress(level: 3)
        for seconds in [0.0, -1, .nan, .infinity] { state.recordPlay(seconds: seconds, on: now, calendar: calendar) }
        XCTAssertNil(state.playDays)
        state.recordPlay(seconds: 15, on: now, calendar: calendar)
        state.recordPlay(seconds: 25, on: now + 1, calendar: calendar)
        state.recordPlay(seconds: 30, on: now - 86400, calendar: calendar)
        state.recordPlay(seconds: 50, on: now - 100 * 86400, calendar: calendar)
        state = try JSONDecoder().decode(GardenState.self, from: JSONEncoder().encode(state))
        XCTAssertEqual(state.playDays?.count, 3)
        XCTAssertEqual(state.playDays?.first?.seconds, 40)
        state.prune(now: now)
        XCTAssertEqual(state.playDays?.count, 2); XCTAssertEqual(state.progress[.math]?.level, 3)
    }
    func testParentPlayTimeLabels() {
        XCTAssertEqual(SubjectReport.playTimeText(0), "No play recorded")
        XCTAssertEqual(SubjectReport.playTimeText(-1), "No play recorded")
        XCTAssertEqual(SubjectReport.playTimeText(59), "Less than 1 minute")
        XCTAssertEqual(SubjectReport.playTimeText(60), "1 minute")
        XCTAssertEqual(SubjectReport.playTimeText(120), "2 minutes")
    }
    func testPracticeFactsAreUniqueAndStableWhenDatesMatch() {
        var first = record(id: "a", correct: false, date: now)
        var duplicate = record(id: "b", correct: false, date: now)
        let other = record(id: "c", correct: false, date: now)
        first.question.explanation = "Shared fact"
        duplicate.question.explanation = "Shared fact"
        for history in [[first, duplicate, other], [other, duplicate, first]] {
            let report = SubjectReport(subject: .math, level: 0, history: history)
            XCTAssertEqual(report.practiceFacts, ["Shared fact", "Fact c"])
        }
    }
    func testPracticeFactsUseLatestAttemptAndRemainSubjectSpecific() {
        let history = [record(id: "resolved", correct: false, date: now - 5), record(id: "resolved", correct: true, date: now), record(id: "old", correct: false, date: now - 4), record(id: "middle", correct: false, date: now - 3), record(id: "latest", correct: false, date: now - 2), record(id: "other", correct: false, date: now, subject: .science)]
        let report = SubjectReport(subject: .math, level: 0, history: history)
        XCTAssertEqual(report.practiceFacts, ["Fact latest", "Fact middle"])
        XCTAssertEqual(SubjectReport(subject: .reading, level: 0, history: history).practiceFacts, [])
    }
}
