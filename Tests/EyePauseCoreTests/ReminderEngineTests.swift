import XCTest
@testable import EyePauseCore

final class ReminderEngineTests: XCTestCase {
    func testDefaultSettingsUseTwentyFiveMinuteIntervalAndForcedModeOff() {
        let settings = SettingsStore()

        XCTAssertEqual(settings.interval, .twentyFiveMinutes)
        XCTAssertFalse(settings.isForcedModeEnabled)
    }

    func testReminderBecomesDueWhenIntervalElapses() {
        var stats = StatsStore(today: Date(timeIntervalSince1970: 0))
        var engine = ReminderEngine(
            now: Date(timeIntervalSince1970: 0),
            settings: SettingsStore(interval: .twentyFiveMinutes)
        )

        let events = engine.advance(to: Date(timeIntervalSince1970: 25 * 60), stats: &stats)

        XCTAssertEqual(engine.state, .due)
        XCTAssertEqual(events, [.showNotification])
    }

    func testDueReminderEscalatesAfterTwoUnhandledMinutes() {
        var stats = StatsStore(today: Date(timeIntervalSince1970: 0))
        var engine = ReminderEngine(
            now: Date(timeIntervalSince1970: 0),
            settings: SettingsStore(interval: .twentyFiveMinutes)
        )

        _ = engine.advance(to: Date(timeIntervalSince1970: 25 * 60), stats: &stats)
        let events = engine.advance(to: Date(timeIntervalSince1970: 27 * 60), stats: &stats)

        XCTAssertEqual(engine.state, .escalated)
        XCTAssertEqual(events, [.showProminentReminder(forced: false)])
    }

    func testForcedModeEscalatesToForcedOverlay() {
        var stats = StatsStore(today: Date(timeIntervalSince1970: 0))
        var engine = ReminderEngine(
            now: Date(timeIntervalSince1970: 0),
            settings: SettingsStore(interval: .twentyFiveMinutes, isForcedModeEnabled: true)
        )

        _ = engine.advance(to: Date(timeIntervalSince1970: 25 * 60), stats: &stats)
        let events = engine.advance(to: Date(timeIntervalSince1970: 27 * 60), stats: &stats)

        XCTAssertEqual(engine.state, .forced)
        XCTAssertEqual(events, [.showProminentReminder(forced: true)])
    }

    func testMeetingSuppressionRecordsMissedBreakAndShowsCatchUpTwoMinutesAfterMeetingEnds() {
        var stats = StatsStore(today: Date(timeIntervalSince1970: 0))
        var detector = MeetingDetector()
        detector.manualMeetingUntil = Date(timeIntervalSince1970: 40 * 60)
        var engine = ReminderEngine(
            now: Date(timeIntervalSince1970: 0),
            settings: SettingsStore(interval: .twentyFiveMinutes),
            meetingDetector: detector
        )

        let dueEvents = engine.advance(to: Date(timeIntervalSince1970: 25 * 60), stats: &stats)

        XCTAssertEqual(engine.state, .meetingSuppressed)
        XCTAssertEqual(dueEvents, [.recordMeetingSuppression])
        XCTAssertEqual(stats.today.meetingSuppressedCount, 1)

        let stillQuietEvents = engine.advance(to: Date(timeIntervalSince1970: 41 * 60), stats: &stats)
        XCTAssertTrue(stillQuietEvents.isEmpty)
        XCTAssertEqual(engine.state, .meetingSuppressed)

        let catchUpEvents = engine.advance(to: Date(timeIntervalSince1970: 42 * 60), stats: &stats)
        XCTAssertEqual(engine.state, .escalated)
        XCTAssertEqual(catchUpEvents, [.showProminentReminder(forced: false)])
    }

    func testMeetingSuppressionRecalculatesCatchUpAfterDetectorFlickersBackToActive() {
        var stats = StatsStore(today: Date(timeIntervalSince1970: 0))
        var detector = MeetingDetector(manualMeetingUntil: Date(timeIntervalSince1970: 40 * 60))
        var engine = ReminderEngine(
            now: Date(timeIntervalSince1970: 0),
            settings: SettingsStore(interval: .twentyFiveMinutes),
            meetingDetector: detector
        )

        _ = engine.advance(to: Date(timeIntervalSince1970: 25 * 60), stats: &stats)
        detector.manualMeetingUntil = nil
        engine.meetingDetector = detector
        XCTAssertTrue(engine.advance(to: Date(timeIntervalSince1970: 41 * 60), stats: &stats).isEmpty)

        detector.manualMeetingUntil = Date(timeIntervalSince1970: 45 * 60)
        engine.meetingDetector = detector
        XCTAssertTrue(engine.advance(to: Date(timeIntervalSince1970: 42 * 60), stats: &stats).isEmpty)

        XCTAssertTrue(engine.advance(to: Date(timeIntervalSince1970: 46 * 60), stats: &stats).isEmpty)

        let catchUpEvents = engine.advance(to: Date(timeIntervalSince1970: 47 * 60), stats: &stats)
        XCTAssertEqual(engine.state, .escalated)
        XCTAssertEqual(catchUpEvents, [.showProminentReminder(forced: false)])
    }

    func testMeetingSuppressesAlreadyEscalatedReminder() {
        var stats = StatsStore(today: Date(timeIntervalSince1970: 0))
        var engine = ReminderEngine(
            now: Date(timeIntervalSince1970: 0),
            settings: SettingsStore(interval: .twentyFiveMinutes)
        )
        _ = engine.advance(to: Date(timeIntervalSince1970: 25 * 60), stats: &stats)
        _ = engine.advance(to: Date(timeIntervalSince1970: 27 * 60), stats: &stats)

        engine.meetingDetector = MeetingDetector(manualMeetingUntil: Date(timeIntervalSince1970: 40 * 60))
        let events = engine.advance(to: Date(timeIntervalSince1970: 28 * 60), stats: &stats)

        XCTAssertEqual(engine.state, .meetingSuppressed)
        XCTAssertEqual(events, [.recordMeetingSuppression])
        XCTAssertEqual(stats.today.meetingSuppressedCount, 1)
    }

    func testMeetingSuppressesAlreadyForcedReminder() {
        var stats = StatsStore(today: Date(timeIntervalSince1970: 0))
        var engine = ReminderEngine(
            now: Date(timeIntervalSince1970: 0),
            settings: SettingsStore(interval: .twentyFiveMinutes, isForcedModeEnabled: true)
        )
        _ = engine.advance(to: Date(timeIntervalSince1970: 25 * 60), stats: &stats)
        _ = engine.advance(to: Date(timeIntervalSince1970: 27 * 60), stats: &stats)

        engine.meetingDetector = MeetingDetector(manualMeetingUntil: Date(timeIntervalSince1970: 40 * 60))
        let events = engine.advance(to: Date(timeIntervalSince1970: 28 * 60), stats: &stats)

        XCTAssertEqual(engine.state, .meetingSuppressed)
        XCTAssertEqual(events, [.recordMeetingSuppression])
        XCTAssertEqual(stats.today.meetingSuppressedCount, 1)
    }

    func testDelayMovesNextReminderFiveMinutesFromNow() {
        var stats = StatsStore(today: Date(timeIntervalSince1970: 0))
        var engine = ReminderEngine(
            now: Date(timeIntervalSince1970: 0),
            settings: SettingsStore(interval: .twentyFiveMinutes)
        )
        _ = engine.advance(to: Date(timeIntervalSince1970: 25 * 60), stats: &stats)

        engine.delay(minutes: 5, now: Date(timeIntervalSince1970: 25 * 60))
        let quietEvents = engine.advance(to: Date(timeIntervalSince1970: 29 * 60 + 59), stats: &stats)

        XCTAssertEqual(engine.state, .active)
        XCTAssertTrue(quietEvents.isEmpty)

        let dueEvents = engine.advance(to: Date(timeIntervalSince1970: 30 * 60), stats: &stats)
        XCTAssertEqual(dueEvents, [.showNotification])
        XCTAssertEqual(engine.state, .due)
    }

    func testNextReminderDateReflectsTimerChanges() {
        var stats = StatsStore(today: Date(timeIntervalSince1970: 0))
        var engine = ReminderEngine(
            now: Date(timeIntervalSince1970: 0),
            settings: SettingsStore(interval: .twentyFiveMinutes)
        )

        XCTAssertEqual(engine.nextReminderDate, Date(timeIntervalSince1970: 25 * 60))

        engine.delay(minutes: 10, now: Date(timeIntervalSince1970: 5 * 60))
        XCTAssertEqual(engine.nextReminderDate, Date(timeIntervalSince1970: 15 * 60))

        engine.completeExercise(.distantLook, now: Date(timeIntervalSince1970: 20 * 60), stats: &stats)
        XCTAssertEqual(engine.nextReminderDate, Date(timeIntervalSince1970: 45 * 60))

        engine.skip(now: Date(timeIntervalSince1970: 30 * 60), stats: &stats)
        XCTAssertEqual(engine.nextReminderDate, Date(timeIntervalSince1970: 55 * 60))
    }

    func testBeginExerciseSetsExerciseRunningStateAndSuppressesAdvance() {
        var stats = StatsStore(today: Date(timeIntervalSince1970: 0))
        var engine = ReminderEngine(
            now: Date(timeIntervalSince1970: 0),
            settings: SettingsStore(interval: .twentyFiveMinutes)
        )
        _ = engine.advance(to: Date(timeIntervalSince1970: 25 * 60), stats: &stats)
        XCTAssertEqual(engine.state, .due)

        engine.beginExercise(.distantLook)

        XCTAssertEqual(engine.state, .exerciseRunning(.distantLook))
        let events = engine.advance(to: Date(timeIntervalSince1970: 30 * 60), stats: &stats)
        XCTAssertTrue(events.isEmpty, "advance should return no events while exercise is running")
        XCTAssertEqual(engine.state, .exerciseRunning(.distantLook), "state must remain exerciseRunning until completeExercise is called")
    }

    func testCompletingExerciseRestartsTimerAndUpdatesStats() {
        var stats = StatsStore(today: Date(timeIntervalSince1970: 0))
        var engine = ReminderEngine(
            now: Date(timeIntervalSince1970: 0),
            settings: SettingsStore(interval: .twentyFiveMinutes)
        )
        _ = engine.advance(to: Date(timeIntervalSince1970: 25 * 60), stats: &stats)

        engine.completeExercise(.distantLook, now: Date(timeIntervalSince1970: 26 * 60), stats: &stats)

        XCTAssertEqual(engine.state, .active)
        XCTAssertEqual(stats.today.completedCount, 1)
        XCTAssertTrue(engine.advance(to: Date(timeIntervalSince1970: 50 * 60 + 59), stats: &stats).isEmpty)
        XCTAssertEqual(engine.advance(to: Date(timeIntervalSince1970: 51 * 60), stats: &stats), [.showNotification])
    }
}
