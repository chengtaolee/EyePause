import Foundation

public struct DailyStats: Codable, Equatable, Identifiable, Sendable {
    public var id: Date { day }
    public var day: Date
    public var completedCount: Int
    public var skippedCount: Int
    public var meetingSuppressedCount: Int

    public init(
        day: Date,
        completedCount: Int = 0,
        skippedCount: Int = 0,
        meetingSuppressedCount: Int = 0
    ) {
        self.day = Calendar.current.startOfDay(for: day)
        self.completedCount = completedCount
        self.skippedCount = skippedCount
        self.meetingSuppressedCount = meetingSuppressedCount
    }
}

public struct StatsStore: Codable, Equatable, Sendable {
    public private(set) var today: DailyStats
    public private(set) var sevenDayTrend: [DailyStats]
    public var activeWorkStartedAt: Date

    public init(today: Date = Date(), sevenDayTrend: [DailyStats] = []) {
        let todayStats = DailyStats(day: today)
        self.today = todayStats
        self.sevenDayTrend = sevenDayTrend.isEmpty ? [todayStats] : sevenDayTrend
        self.activeWorkStartedAt = today
    }

    public mutating func recordCompletedBreak(now: Date = Date()) {
        rolloverIfNeeded(now: now)
        today.completedCount += 1
        activeWorkStartedAt = now
        replaceTodayInTrend()
    }

    public mutating func recordSkippedBreak(now: Date = Date()) {
        rolloverIfNeeded(now: now)
        today.skippedCount += 1
        replaceTodayInTrend()
    }

    public mutating func recordMeetingSuppression(now: Date = Date()) {
        rolloverIfNeeded(now: now)
        today.meetingSuppressedCount += 1
        replaceTodayInTrend()
    }

    public mutating func recordSystemInterruption(now: Date = Date()) {
        rolloverIfNeeded(now: now)
        activeWorkStartedAt = now
        replaceTodayInTrend()
    }

    public mutating func rolloverIfNeeded(now: Date) {
        let currentDay = Calendar.current.startOfDay(for: now)
        guard currentDay != today.day else { return }
        appendOrReplace(today)
        today = DailyStats(day: now)
        activeWorkStartedAt = now
        appendOrReplace(today)
        trimTrend()
    }

    public func continuousWorkDuration(now: Date = Date()) -> TimeInterval {
        now.timeIntervalSince(activeWorkStartedAt)
    }

    public mutating func resetActiveWorkStart(now: Date = Date()) {
        activeWorkStartedAt = now
    }

    public mutating func resetActiveWorkIfStale(now: Date, threshold: TimeInterval) {
        if now.timeIntervalSince(activeWorkStartedAt) > threshold {
            activeWorkStartedAt = now
        }
    }

    public var todayAttemptedBreakCount: Int {
        today.completedCount + today.skippedCount
    }

    public var todayCompletionRatePercent: Int {
        guard todayAttemptedBreakCount > 0 else { return 0 }
        return Int((Double(today.completedCount) / Double(todayAttemptedBreakCount) * 100).rounded())
    }

    public var sevenDayCompletedBreakCount: Int {
        sevenDayTrend.reduce(0) { $0 + $1.completedCount }
    }

    public var sevenDayAttemptedBreakCount: Int {
        sevenDayTrend.reduce(0) { $0 + $1.completedCount + $1.skippedCount }
    }

    private mutating func replaceTodayInTrend() {
        appendOrReplace(today)
        trimTrend()
    }

    private mutating func appendOrReplace(_ stats: DailyStats) {
        sevenDayTrend.removeAll { $0.day == stats.day }
        sevenDayTrend.append(stats)
        sevenDayTrend.sort { $0.day < $1.day }
    }

    private mutating func trimTrend() {
        if sevenDayTrend.count > 7 {
            sevenDayTrend = Array(sevenDayTrend.suffix(7))
        }
    }
}
