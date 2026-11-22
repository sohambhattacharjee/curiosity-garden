import Foundation

public enum ReadingFont: String, Codable, CaseIterable, Sendable {
    case standard, rounded
    public var title: String { self == .standard ? "Standard sans serif" : "Rounded sans serif" }
}
public enum ReadingSize: String, Codable, CaseIterable, Sendable {
    case large, extraLarge
    public var title: String { self == .large ? "Large" : "Extra large" }
}
public enum ReadingRole: CaseIterable, Sendable { case question, answer, body, note }
public struct ReadingPreferences: Codable, Equatable, Sendable {
    public var font: ReadingFont
    public var size: ReadingSize
    public init(font: ReadingFont = .standard, size: ReadingSize = .large) { self.font = font; self.size = size }
    public func points(for role: ReadingRole) -> Double {
        let base: Double
        switch role { case .question: base = 26; case .answer: base = 22; case .body: base = 20; case .note: base = 14 }
        return base + (size == .extraLarge ? 2 : 0)
    }
}
