import Foundation

public enum AnswerChoiceState: Equatable, Sendable {
    case available, selectedCorrect, selectedIncorrect, revealedCorrect, unselected

    public init(option: Int, correct: Int, response: Response?) {
        guard let response else { self = .available; return }
        if response == .choice(option) {
            self = option == correct ? .selectedCorrect : .selectedIncorrect
        } else {
            self = option == correct ? .revealedCorrect : .unselected
        }
    }

    public var annotation: String? {
        switch self {
        case .selectedCorrect: "Your answer · Correct"
        case .selectedIncorrect: "Your answer · Not quite"
        case .revealedCorrect: "Correct answer"
        case .available, .unselected: nil
        }
    }
}
