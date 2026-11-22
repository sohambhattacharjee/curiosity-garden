import Foundation

public enum ReportWindow: String, CaseIterable, Sendable {
    case week, month, ninetyDays
    public var days: Int { switch self { case .week: 7; case .month: 30; case .ninetyDays: 90 } }
    public var title: String { "Last \(days) days" }
    public func start(now: Date, calendar: Calendar = .current) -> Date {
        calendar.date(byAdding: .day, value: 1 - days, to: calendar.startOfDay(for: now))!
    }
    public func contains(_ date: Date, now: Date, calendar: Calendar = .current) -> Bool {
        date >= start(now: now, calendar: calendar) && date <= now
    }
    public func history(_ history: [AnswerRecord], now: Date, calendar: Calendar = .current) -> [AnswerRecord] {
        history.filter { contains($0.date, now: now, calendar: calendar) }
    }
    public func seconds(in days: [PlayDay], now: Date, calendar: Calendar = .current) -> TimeInterval {
        days.filter { contains($0.date, now: now, calendar: calendar) }.reduce(0) { $0 + $1.seconds }
    }
}
public struct PlayDay: Codable, Equatable, Sendable {
    public var date: Date
    public var seconds: TimeInterval
    public init(date: Date, seconds: TimeInterval) { self.date = date; self.seconds = seconds }
}
