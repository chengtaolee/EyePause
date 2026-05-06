import Foundation

public enum ReminderState: Codable, Equatable, Sendable {
    case active
    case due
    case escalated
    case exerciseRunning(Exercise)
    case paused(until: Date)
    case meetingSuppressed
    case forced
}

public enum ReminderEvent: Equatable, Sendable {
    case showNotification
    case showProminentReminder(forced: Bool)
    case recordMeetingSuppression
}

public struct ReminderEngine: Sendable {
    public private(set) var state: ReminderState
    public var settings: SettingsStore
    public var meetingDetector: MeetingDetector

    private var nextReminderAt: Date
    private var dueSince: Date?
    private var catchUpAt: Date?
    private var hasRecordedCurrentSuppression: Bool

    public var nextReminderDate: Date {
        nextReminderAt
    }

    public init(
        now: Date = Date(),
        settings: SettingsStore = SettingsStore(),
        meetingDetector: MeetingDetector = MeetingDetector()
    ) {
        self.state = .active
        self.settings = settings
        self.meetingDetector = meetingDetector
        self.nextReminderAt = now.addingTimeInterval(settings.interval.seconds)
        self.dueSince = nil
        self.catchUpAt = nil
        self.hasRecordedCurrentSuppression = false
    }

    public mutating func advance(to now: Date, stats: inout StatsStore) -> [ReminderEvent] {
        stats.rolloverIfNeeded(now: now)

        if case .paused(let until) = state {
            if now < until { return [] }
            state = .active
            nextReminderAt = now.addingTimeInterval(settings.interval.seconds)
        }

        if case .meetingSuppressed = state {
            guard !meetingDetector.isMeetingActive(at: now) else {
                catchUpAt = nil
                return []
            }
            if catchUpAt == nil {
                let meetingEndedAt = meetingDetector.knownMeetingEnd(at: now) ?? now
                catchUpAt = meetingEndedAt.addingTimeInterval(120)
                if let catchUpAt, now >= catchUpAt {
                    state = .escalated
                    dueSince = now
                    self.catchUpAt = nil
                    hasRecordedCurrentSuppression = false
                    return [.showProminentReminder(forced: false)]
                }
                return []
            }
            guard let catchUpAt, now >= catchUpAt else { return [] }
            state = .escalated
            dueSince = now
            self.catchUpAt = nil
            hasRecordedCurrentSuppression = false
            return [.showProminentReminder(forced: false)]
        }

        guard state == .active || state == .due || state == .escalated || state == .forced else {
            return []
        }

        if state == .due || state == .escalated || state == .forced,
           meetingDetector.isMeetingActive(at: now) {
            state = .meetingSuppressed
            dueSince = nil
            catchUpAt = nil
            if !hasRecordedCurrentSuppression {
                hasRecordedCurrentSuppression = true
                stats.recordMeetingSuppression(now: now)
                return [.recordMeetingSuppression]
            }
            return []
        }

        if state == .active, now >= nextReminderAt {
            if meetingDetector.isMeetingActive(at: now) {
                state = .meetingSuppressed
                catchUpAt = nil
                if !hasRecordedCurrentSuppression {
                    hasRecordedCurrentSuppression = true
                    stats.recordMeetingSuppression(now: now)
                    return [.recordMeetingSuppression]
                }
                return []
            }
            state = .due
            dueSince = now
            return [.showNotification]
        }

        if state == .due, let dueSince, now.timeIntervalSince(dueSince) >= 120 {
            if meetingDetector.isMeetingActive(at: now) {
                state = .meetingSuppressed
                catchUpAt = nil
                if !hasRecordedCurrentSuppression {
                    hasRecordedCurrentSuppression = true
                    stats.recordMeetingSuppression(now: now)
                    return [.recordMeetingSuppression]
                }
                return []
            }
            state = settings.isForcedModeEnabled ? .forced : .escalated
            return [.showProminentReminder(forced: settings.isForcedModeEnabled)]
        }

        return []
    }

    public mutating func beginExercise(_ exercise: Exercise) {
        state = .exerciseRunning(exercise)
        dueSince = nil
        catchUpAt = nil
    }

    public mutating func delay(minutes: Int, now: Date = Date()) {
        state = .active
        nextReminderAt = now.addingTimeInterval(TimeInterval(minutes * 60))
        dueSince = nil
        catchUpAt = nil
        hasRecordedCurrentSuppression = false
    }

    public mutating func pause(minutes: Int, now: Date = Date()) {
        state = .paused(until: now.addingTimeInterval(TimeInterval(minutes * 60)))
        dueSince = nil
        catchUpAt = nil
    }

    public mutating func completeExercise(_ exercise: Exercise, now: Date = Date(), stats: inout StatsStore) {
        state = .active
        nextReminderAt = now.addingTimeInterval(settings.interval.seconds)
        dueSince = nil
        catchUpAt = nil
        hasRecordedCurrentSuppression = false
        stats.recordCompletedBreak(now: now)
    }

    public mutating func skip(now: Date = Date(), stats: inout StatsStore) {
        state = .active
        nextReminderAt = now.addingTimeInterval(settings.interval.seconds)
        dueSince = nil
        catchUpAt = nil
        hasRecordedCurrentSuppression = false
        stats.recordSkippedBreak(now: now)
    }
}
