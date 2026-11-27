import XCTest
@testable import GardenCore

final class AnswerChoiceStateTests: XCTestCase {
    func testUnansweredChoicesDoNotRevealTheAnswer() {
        for option in 0..<4 {
            let state = AnswerChoiceState(option: option, correct: 2, response: nil)
            XCTAssertEqual(state, .available)
            XCTAssertNil(state.annotation)
        }
    }
    func testWrongResponseMarksBothTheChosenOptionAndTheCorrectAnswer() {
        let states = (0..<4).map { AnswerChoiceState(option: $0, correct: 2, response: .choice(1)) }
        XCTAssertEqual(states, [.unselected, .selectedIncorrect, .revealedCorrect, .unselected])
        XCTAssertEqual(states[1].annotation, "Your answer · Not quite")
        XCTAssertEqual(states[2].annotation, "Correct answer")
        XCTAssertNil(states[0].annotation)
    }
    func testCorrectResponseMarksOnlyTheChosenCorrectOption() {
        let states = (0..<3).map { AnswerChoiceState(option: $0, correct: 0, response: .choice(0)) }
        XCTAssertEqual(states, [.selectedCorrect, .unselected, .unselected])
        XCTAssertEqual(states[0].annotation, "Your answer · Correct")
    }
    func testUnsureRevealsCorrectAnswerWithoutMarkingAMistake() {
        let states = (0..<2).map { AnswerChoiceState(option: $0, correct: 1, response: .unsure) }
        XCTAssertEqual(states, [.unselected, .revealedCorrect])
        XCTAssertNil(states[0].annotation)
        XCTAssertEqual(states[1].annotation, "Correct answer")
    }
    func testEveryChoicePositionSupportsWrongAndCorrectFeedback() {
        for count in 2...4 {
            for correct in 0..<count {
                for selected in 0..<count {
                    let states = (0..<count).map { AnswerChoiceState(option: $0, correct: correct, response: .choice(selected)) }
                    XCTAssertEqual(states.filter { $0 == .selectedIncorrect }.count, selected == correct ? 0 : 1)
                    XCTAssertEqual(states.filter { $0 == .selectedCorrect || $0 == .revealedCorrect }.count, 1)
                    XCTAssertEqual(states[selected], selected == correct ? .selectedCorrect : .selectedIncorrect)
                    XCTAssertEqual(states[correct], selected == correct ? .selectedCorrect : .revealedCorrect)
                }
            }
        }
    }
}
