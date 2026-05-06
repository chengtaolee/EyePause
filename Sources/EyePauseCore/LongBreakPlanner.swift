import Foundation

public struct LongBreakPlanner: Equatable, Sendable {
    public private(set) var shortBreaksSinceLongBreak: Int
    public var shortBreaksBeforeLongBreak: Int
    public var continuousWorkThreshold: TimeInterval

    public init(
        shortBreaksSinceLongBreak: Int = 0,
        shortBreaksBeforeLongBreak: Int = 4,
        continuousWorkThreshold: TimeInterval = 2 * 60 * 60
    ) {
        self.shortBreaksSinceLongBreak = shortBreaksSinceLongBreak
        self.shortBreaksBeforeLongBreak = shortBreaksBeforeLongBreak
        self.continuousWorkThreshold = continuousWorkThreshold
    }

    public func shouldStartLongBreak(now: Date, stats: StatsStore) -> Bool {
        shortBreaksSinceLongBreak >= shortBreaksBeforeLongBreak
            || stats.continuousWorkDuration(now: now) >= continuousWorkThreshold
    }

    public mutating func recordCompletedShortBreak() {
        shortBreaksSinceLongBreak += 1
    }

    public mutating func recordCompletedLongBreak() {
        shortBreaksSinceLongBreak = 0
    }
}
