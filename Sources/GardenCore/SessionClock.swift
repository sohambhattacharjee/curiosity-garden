import Foundation

/// Wall time persists absence; monotonic uptime measures foreground play.
public struct SessionClock: Codable, Sendable {
    public private(set) var id = UUID()
    public private(set) var used: TimeInterval = 0
    public private(set) var awaySince: Date?
    public private(set) var awayUptime: TimeInterval?
    public private(set) var lastWall: Date?
    public private(set) var lastUptime: TimeInterval?
    public private(set) var playing = false
    public private(set) var sessionGrade: Int?
    public private(set) var totalPlay: TimeInterval = 0
    public static let breakLength: TimeInterval = 1800
    public init() {}
    public static func cap(grade: Int) -> TimeInterval { Double([20,25,30,40,50,60][min(5,max(0,grade))]) * 60 }
    public mutating func update(now: Date, uptime: TimeInterval, wantsPlay: Bool, grade: Int, restored: Bool = false) {
        if sessionGrade == nil { sessionGrade = grade }
        let limit = Self.cap(grade: sessionGrade ?? grade)
        let rollback = lastWall.map { now < $0 } ?? false
        let discontinuity: Bool
        if let previousWall = lastWall, let previousTick = lastUptime { discontinuity = abs(now.timeIntervalSince(previousWall) - (uptime - previousTick)) > 5 } else { discontinuity = false }
        let reboot = (lastUptime.map { uptime < $0 } ?? false) || discontinuity
        if rollback || reboot { awaySince = now; awayUptime = uptime }
        if playing, let previous = lastUptime {
            // A killed process must not restore allowance. Charge uncheckpointed time
            // conservatively (including unknown background) until the next launch.
            let elapsed = !reboot && uptime >= previous ? uptime - previous : limit
            let charged = min(max(0, limit - used), max(0, elapsed))
            used += charged; totalPlay += charged
            if used >= limit { awaySince = now; awayUptime = uptime }
        }
        if restored && playing { playing = false; awaySince = now; awayUptime = uptime }
        if let away = awaySince, let awayTick = awayUptime, !rollback, !reboot, min(now.timeIntervalSince(away), uptime - awayTick) >= Self.breakLength {
            id = UUID(); used = 0; awaySince = nil; awayUptime = nil; sessionGrade = grade
        }
        let allowed = used < Self.cap(grade: sessionGrade ?? grade)
        if wantsPlay && allowed {
            playing = true; awaySince = nil; awayUptime = nil
        } else {
            if playing || awaySince == nil { awaySince = now; awayUptime = uptime }
            playing = false
        }
        lastWall = now; lastUptime = uptime
    }
    public func remainingBreak(now: Date, grade: Int) -> TimeInterval {
        guard used >= Self.cap(grade: sessionGrade ?? grade) else { return 0 }
        return max(0, Self.breakLength - max(0, min(now.timeIntervalSince(awaySince ?? now), (lastUptime ?? 0) - (awayUptime ?? (lastUptime ?? 0)))))
    }
}
public struct GardenState: Codable, Sendable {
    public var grade: Int?
    public var progress: [Subject: SubjectProgress] = [:]
    public var history: [AnswerRecord] = []
    public var round: Round?
    public var clock = SessionClock()
    public init() {}
    /// Recheck persisted content on configuration changes, including Debug → Release.
    public mutating func validateResumedContent(allowDrafts: Bool) {
        guard let round else { return }
        let snapshots = round.answers.map(\.question) + [round.pending].compactMap { $0 }
        if snapshots.contains(where: { !$0.valid || (!allowDrafts && $0.status != .reviewed) }) {
            self.round = nil
        }
    }
    public mutating func prune(now: Date) { history.removeAll { $0.date < now.addingTimeInterval(-90 * 86400) }; if let round, round.answers.contains(where: { $0.date < now.addingTimeInterval(-90 * 86400) }) { self.round = nil } }
}
