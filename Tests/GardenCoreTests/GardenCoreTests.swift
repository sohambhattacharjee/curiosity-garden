import XCTest
@testable import GardenCore

final class GardenCoreTests: XCTestCase {
    let date = Date(timeIntervalSince1970: 1_000_000)
    func question(_ subject: Subject = .math, level: Int = 0, id: String = "q") -> Question {
        Question(id: id, subject: subject, level: level, readingGrade: 0, prompt: "One plus one?", choices: ["Two", "Three"], correct: 0, explanation: "One and one make two.", source: "Original test fixture")
    }
    func testPromotionExactlyTenAndBoundaries() {
        var progress = SubjectProgress(level: 2)
        for _ in 0..<9 { progress.answer(correct: true) }
        XCTAssertEqual(progress.level, 2); XCTAssertEqual(progress.streak, 9)
        progress.answer(correct: true); XCTAssertEqual(progress.level, 3); XCTAssertEqual(progress.streak, 0)
        progress.answer(correct: false); XCTAssertEqual(progress.level, 2)
        var floor = SubjectProgress(level: 0); floor.answer(correct: false); XCTAssertEqual(floor.level, 0)
        var ceiling = SubjectProgress(level: 5); for _ in 0..<20 { ceiling.answer(correct: true) }; XCTAssertEqual(ceiling.level, 5)
    }
    func testIndependentStreaksSurviveSerialization() throws {
        var state = GardenState(); state.progress[.math] = SubjectProgress(level: 1); state.progress[.science] = SubjectProgress(level: 4)
        for _ in 0..<9 { state.progress[.math]!.answer(correct: true) }
        state.progress[.science]!.answer(correct: false)
        state = try JSONDecoder().decode(GardenState.self, from: JSONEncoder().encode(state))
        XCTAssertEqual(state.progress[.math]?.streak, 9); XCTAssertEqual(state.progress[.science]?.level, 3)
        state.progress[.math]!.answer(correct: true); XCTAssertEqual(state.progress[.math]?.level, 2)
    }
    func testMixReadingLevelAndReleaseContentGate() {
        let bank = [question(), question(.nature, id: "n")]
        var round = Round()
        XCTAssertNil(QuestionPicker.pick(bank: bank, grade: 0, progress: [:], round: round, history: [], allowDrafts: false, now: date))
        let q = QuestionPicker.pick(bank: bank, grade: 0, progress: [:], round: round, history: [], allowDrafts: true, now: date)!
        XCTAssertTrue(q.subject.isSchool)
        round.record(AnswerRecord(roundID: round.id, question: q, response: .unsure, date: date, levelAfter: 0), oldLevel: 0)
        XCTAssertFalse(QuestionPicker.pick(bank: bank, grade: 0, progress: [:], round: round, history: [], allowDrafts: true, now: date)!.subject.isSchool)
        var hardReading = question(); hardReading.readingGrade = 5
        XCTAssertNil(QuestionPicker.pick(bank: [hardReading], grade: 0, progress: [:], round: Round(), history: [], allowDrafts: true, now: date))
    }
    func testCalibrationExtendsOnlyAfterChangeAndStopsAtLimits() {
        var round = Round()
        for i in 0..<10 { round.record(AnswerRecord(roundID: round.id, question: question(), response: .choice(0), date: date, levelAfter: i == 9 ? 1 : 0), oldLevel: 0) }
        XCTAssertFalse(round.finished(grade: 0))
        for _ in 0..<2 { round.record(AnswerRecord(roundID: round.id, question: question(level: 1), response: .choice(0), date: date, levelAfter: 1), oldLevel: 1) }
        XCTAssertTrue(round.finished(grade: 0))
        round.calibration[.science] = 0
        for _ in 12..<15 { round.answers.append(round.answers[0]) }
        XCTAssertTrue(round.finished(grade: 0)); XCTAssertFalse(round.finished(grade: 3))
        for _ in 15..<20 { round.answers.append(round.answers[0]) }
        XCTAssertTrue(round.finished(grade: 3))
        var normal = Round(); normal.answers = Array(round.answers.prefix(10)); XCTAssertTrue(normal.finished(grade: 5))
    }
    func testCapsAndForegroundAcrossRounds() {
        XCTAssertEqual((0...5).map(SessionClock.cap), [1200,1500,1800,2400,3000,3600])
        var clock = SessionClock()
        clock.update(now: date, uptime: 100, wantsPlay: true, grade: 0)
        clock.update(now: date.addingTimeInterval(600), uptime: 700, wantsPlay: true, grade: 0)
        XCTAssertEqual(clock.used, 600)
        clock.update(now: date.addingTimeInterval(1200), uptime: 1300, wantsPlay: true, grade: 0)
        XCTAssertEqual(clock.used, 1200); XCTAssertFalse(clock.playing)
        XCTAssertEqual(clock.remainingBreak(now: date.addingTimeInterval(1200), grade: 0), 1800)
        clock.update(now: date.addingTimeInterval(2999), uptime: 3099, wantsPlay: true, grade: 0)
        XCTAssertFalse(clock.playing)
        clock.update(now: date.addingTimeInterval(3000), uptime: 3100, wantsPlay: true, grade: 0)
        XCTAssertTrue(clock.playing); XCTAssertEqual(clock.used, 0)
    }
    func testShortAbsencePausesAndLongAbsenceRefreshes() throws {
        var clock = SessionClock()
        clock.update(now: date, uptime: 100, wantsPlay: true, grade: 0)
        clock.update(now: date.addingTimeInterval(100), uptime: 200, wantsPlay: false, grade: 0)
        clock = try JSONDecoder().decode(SessionClock.self, from: JSONEncoder().encode(clock))
        clock.update(now: date.addingTimeInterval(1899), uptime: 1999, wantsPlay: false, grade: 0, restored: true)
        XCTAssertEqual(clock.used, 100)
        clock.update(now: date.addingTimeInterval(1900), uptime: 2000, wantsPlay: true, grade: 0)
        XCTAssertEqual(clock.used, 0)
    }
    func testKilledProcessRebootAndClockRollbackFailClosed() throws {
        var clock = SessionClock(); clock.update(now: date, uptime: 100, wantsPlay: true, grade: 0)
        clock = try JSONDecoder().decode(SessionClock.self, from: JSONEncoder().encode(clock))
        clock.update(now: date.addingTimeInterval(10), uptime: 110, wantsPlay: false, grade: 0, restored: true)
        XCTAssertEqual(clock.used, 10)
        clock.update(now: date.addingTimeInterval(11), uptime: 111, wantsPlay: true, grade: 0)
        clock.update(now: date.addingTimeInterval(12), uptime: 2, wantsPlay: false, grade: 0, restored: true)
        XCTAssertEqual(clock.used, 1200)
        clock.update(now: date.addingTimeInterval(-100), uptime: 3, wantsPlay: true, grade: 0)
        XCTAssertFalse(clock.playing); XCTAssertEqual(clock.remainingBreak(now: date.addingTimeInterval(-100), grade: 0), 1800)
    }
    func testChangingGradeDoesNotBypassBreak() {
        var clock = SessionClock(); clock.update(now: date, uptime: 100, wantsPlay: true, grade: 0)
        clock.update(now: date.addingTimeInterval(1200), uptime: 1300, wantsPlay: false, grade: 0)
        clock.update(now: date.addingTimeInterval(1201), uptime: 1301, wantsPlay: true, grade: 5)
        XCTAssertFalse(clock.playing); XCTAssertGreaterThan(clock.remainingBreak(now: date.addingTimeInterval(1201), grade: 5), 0)
    }
    func testRetentionKeepsProgressAndRemovesOldAnswers() {
        var state = GardenState(); state.progress[.math] = SubjectProgress(level: 3)
        state.history = [AnswerRecord(roundID: UUID(), question: question(), response: .unsure, date: date.addingTimeInterval(-91*86400), levelAfter: 0), AnswerRecord(roundID: UUID(), question: question(), response: .choice(0), date: date, levelAfter: 3)]
        state.prune(now: date); XCTAssertEqual(state.history.count, 1); XCTAssertEqual(state.progress[.math]?.level, 3)
    }

    func testForwardClockCannotSkipBreak() {
        var clock = SessionClock(); clock.update(now: date, uptime: 100, wantsPlay: true, grade: 0)
        clock.update(now: date.addingTimeInterval(1200), uptime: 1300, wantsPlay: false, grade: 0)
        clock.update(now: date.addingTimeInterval(10000), uptime: 1301, wantsPlay: true, grade: 0)
        XCTAssertFalse(clock.playing); XCTAssertEqual(clock.remainingBreak(now: date.addingTimeInterval(10000), grade: 0), 1800)
    }
    func testRestartWithHigherUptimeCannotResetAllowance() {
        var clock = SessionClock(); clock.update(now: date, uptime: 100, wantsPlay: true, grade: 0)
        clock.update(now: date.addingTimeInterval(100), uptime: 200, wantsPlay: false, grade: 0)
        clock.update(now: date.addingTimeInterval(10000), uptime: 1000, wantsPlay: true, grade: 0, restored: true)
        XCTAssertEqual(clock.used, 100)
        XCTAssertTrue(clock.playing) // pause persisted: remaining allowance resumes conservatively
        XCTAssertEqual(clock.sessionGrade, 0)
    }

    func testWrongAndUnsureUseSameLearningRule() {
        for response in [Response.unsure, .choice(1)] {
            let q = question(level: 3)
            var progress = SubjectProgress(level: 3); progress.streak = 9
            progress.answer(correct: response == .choice(q.correct))
            XCTAssertEqual(progress.level, 2); XCTAssertEqual(progress.streak, 0)
        }
    }
    func testMissedReviewComesFromPreviousSession() {
        let oldSession = UUID(), newSession = UUID()
        var round = Round()
        for i in 0..<9 { round.answers.append(AnswerRecord(roundID: round.id, question: question(id: "used-\(i)"), response: .choice(0), date: date, levelAfter: 0)) }
        let missed = question(.nature, id: "missed"), fresh = question(.nature, id: "fresh")
        let history = [AnswerRecord(roundID: UUID(), question: missed, response: .unsure, date: date.addingTimeInterval(-1800), levelAfter: 0, sessionID: oldSession)]
        XCTAssertEqual(QuestionPicker.pick(bank: [fresh,missed], grade: 0, progress: [:], round: round, history: history, allowDrafts: true, now: date, sessionID: newSession)?.id, "missed")
        XCTAssertEqual(QuestionPicker.pick(bank: [fresh,missed], grade: 0, progress: [:], round: round, history: history, allowDrafts: true, now: date, sessionID: oldSession)?.id, "fresh")
    }

    func testReviewsReachSchoolAndGeneralEvenWithSubjectBalancing() throws {
        for (position, subject) in [(4, Subject.math), (9, Subject.nature)] {
            var round = Round()
            for index in 0..<position {
                // Give the missed subject more use; its due review must still be reachable.
                round.answers.append(AnswerRecord(roundID: round.id, question: question(subject, id: "used-\(index)"), response: .choice(0), date: date, levelAfter: 0))
            }
            let session = UUID()
            let missed = question(subject, id: "missed")
            let freshSubject: Subject = subject.isSchool ? .science : .world
            let history = [AnswerRecord(roundID: UUID(), question: missed, response: .unsure, date: date.addingTimeInterval(-1800), levelAfter: 0, sessionID: UUID())]
            let result = try XCTUnwrap(QuestionPicker.pick(bank: [question(freshSubject, id: "fresh"), missed], grade: 0, progress: [:], round: round, history: history, allowDrafts: true, now: date, sessionID: session))
            XCTAssertEqual(result.id, "missed")
            XCTAssertEqual(result.subject.isSchool, position.isMultiple(of: 2))
        }
    }
    func testReleaseRejectsPersistedDraftQuestionAndDraftRecap() throws {
        var state = GardenState(); state.grade = 0
        var round = Round(); round.pending = question()
        state.round = round
        let data = try JSONEncoder().encode(state)
        var debug = try JSONDecoder().decode(GardenState.self, from: data)
        debug.validateResumedContent(allowDrafts: true); XCTAssertNotNil(debug.round)
        state.validateResumedContent(allowDrafts: false); XCTAssertNil(state.round)
        let answer = AnswerRecord(roundID: round.id, question: question(), response: .unsure, date: date, levelAfter: 0)
        round.answers = [answer]; round.end(.completed)
        state.round = round; state.history = [answer]
        state.validateResumedContent(allowDrafts: false)
        XCTAssertNil(state.round); XCTAssertEqual(state.history.count, 1)
        var reviewed = question(); reviewed.status = .reviewed; reviewed.reviewer = "Test reviewer"; reviewed.reviewedAt = date
        var valid = Round(); valid.pending = reviewed; state.round = valid
        state.validateResumedContent(allowDrafts: false); XCTAssertNotNil(state.round)
    }
    func testFinalExplanationAndEndedRecapPersistSeparately() throws {
        var round = Round(); round.pending = question()
        for _ in 0..<10 {
            round.record(AnswerRecord(roundID: round.id, question: question(), response: .choice(0), date: date, levelAfter: 0), oldLevel: 0)
        }
        round = try JSONDecoder().decode(Round.self, from: JSONEncoder().encode(round))
        XCTAssertTrue(round.finished(grade: 0))
        XCTAssertFalse(round.needsRecap) // Explanation remains until Next.
        for reason in [RoundEndReason.completed, .sessionLimit, .contentUnavailable] {
            var ended = round; ended.end(reason)
            ended = try JSONDecoder().decode(Round.self, from: JSONEncoder().encode(ended))
            XCTAssertEqual(ended.endReason, reason); XCTAssertTrue(ended.needsRecap)
            XCTAssertNil(ended.pending); XCTAssertEqual(ended.answers.count, 10)
        }
    }
    func testDraftBankIsValidAndMixedRoundCompletes() throws {
        let url = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().appending(path: "App/questions.json")
        let bank = try JSONDecoder().decode([Question].self, from: Data(contentsOf: url))
        XCTAssertTrue(bank.allSatisfy(\.valid)); XCTAssertTrue(bank.allSatisfy { $0.status == .draft }); XCTAssertEqual(Set(bank.map(\.id)).count, bank.count)
        for grade in 0...5 {
            var round = Round()
            while !round.finished(grade: grade) {
                let q = try XCTUnwrap(QuestionPicker.pick(bank: bank, grade: grade, progress: [:], round: round, history: [], allowDrafts: true, now: date))
                round.record(AnswerRecord(roundID: round.id, question: q, response: .choice(q.correct), date: date, levelAfter: grade), oldLevel: grade)
            }
            XCTAssertEqual(round.answers.count, 10); XCTAssertEqual(round.answers.filter { $0.question.subject.isSchool }.count, 5)
        }
    }
}
