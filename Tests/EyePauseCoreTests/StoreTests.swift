import XCTest
@testable import EyePauseCore

final class StoreTests: XCTestCase {
    func testStatsRollIntoSevenDayTrendAndResetDailyCountsForNewDay() {
        let dayOne = Date(timeIntervalSince1970: 0)
        let dayTwo = Date(timeIntervalSince1970: 24 * 60 * 60)
        var store = StatsStore(today: dayOne)

        store.recordCompletedBreak(now: dayOne)
        store.recordSkippedBreak(now: dayOne)
        store.recordMeetingSuppression(now: dayOne)
        store.rolloverIfNeeded(now: dayTwo)

        XCTAssertEqual(store.today.completedCount, 0)
        XCTAssertEqual(store.today.skippedCount, 0)
        XCTAssertEqual(store.today.meetingSuppressedCount, 0)
        XCTAssertEqual(store.sevenDayTrend.count, 2)
        XCTAssertEqual(store.sevenDayTrend.first?.completedCount, 1)
    }

    func testSettingsStoreKeepsSelectableAppLanguage() {
        let settings = SettingsStore(language: .traditionalChinese)

        XCTAssertEqual(settings.language, .traditionalChinese)
        XCTAssertEqual(AppLanguage.allCases, [.english, .traditionalChinese, .simplifiedChinese, .japanese, .korean])
    }

    func testSettingsDefaultToOnboardingIncomplete() {
        let settings = SettingsStore()

        XCTAssertFalse(settings.hasCompletedOnboarding)
    }

    func testSettingsStoreDefaultsBreakWindowPresentationToCenteredWindow() {
        let settings = SettingsStore()

        XCTAssertEqual(settings.breakWindowPresentationMode, .centeredWindow)
    }

    func testSettingsStoreDecodesMissingBreakWindowPresentationModeAsCenteredWindow() throws {
        let json = """
        {
          "interval": 25,
          "isForcedModeEnabled": false
        }
        """
        let data = try XCTUnwrap(json.data(using: .utf8))

        let settings = try JSONDecoder().decode(SettingsStore.self, from: data)

        XCTAssertEqual(settings.breakWindowPresentationMode, .centeredWindow)
    }

    func testReminderIntervalTitleUsesSelectedLanguage() {
        XCTAssertEqual(ReminderInterval.twentyFiveMinutes.title(language: .english), "25 min")
        XCTAssertEqual(ReminderInterval.twentyFiveMinutes.title(language: .traditionalChinese), "25分鐘")
        XCTAssertEqual(ReminderInterval.twentyFiveMinutes.title(language: .simplifiedChinese), "25分钟")
        XCTAssertEqual(ReminderInterval.twentyFiveMinutes.title(language: .japanese), "25分")
        XCTAssertEqual(ReminderInterval.twentyFiveMinutes.title(language: .korean), "25분")
    }

    func testArbitraryMinuteTextUsesSelectedLanguage() {
        XCTAssertEqual(AppLanguage.english.minutesText(30), "30 min")
        XCTAssertEqual(AppLanguage.traditionalChinese.minutesText(30), "30分鐘")
        XCTAssertEqual(AppLanguage.simplifiedChinese.minutesText(30), "30分钟")
        XCTAssertEqual(AppLanguage.japanese.minutesText(30), "30分")
        XCTAssertEqual(AppLanguage.korean.minutesText(30), "30분")
    }

    func testSettingsIncludeExerciseDurationLongBreakAndShortcutDefaults() {
        let settings = SettingsStore()

        XCTAssertEqual(ExerciseDuration.allCases.map(\.rawValue), [20, 30, 45, 60])
        XCTAssertEqual(LongBreakDuration.allCases.map(\.rawValue), [2, 3, 5])
        XCTAssertEqual(settings.exerciseDuration, .thirtySeconds)
        XCTAssertEqual(settings.longBreakDuration, .threeMinutes)
        XCTAssertFalse(settings.startBreakShortcut.isConfigured)
    }

    func testExerciseDurationTitleUsesSelectedLanguage() {
        XCTAssertEqual(ExerciseDuration.fortyFiveSeconds.title(language: .english), "45 sec")
        XCTAssertEqual(ExerciseDuration.fortyFiveSeconds.title(language: .traditionalChinese), "45秒")
        XCTAssertEqual(ExerciseDuration.fortyFiveSeconds.title(language: .korean), "45초")
    }

    func testBreakDurationUsesSettingsAsTheSingleSourceOfTruth() {
        let settings = SettingsStore(
            exerciseDuration: .fortyFiveSeconds,
            longBreakDuration: .fiveMinutes
        )

        XCTAssertEqual(settings.breakDurationSeconds(isLongBreak: false), 45)
        XCTAssertEqual(settings.breakDurationSeconds(isLongBreak: true), 5 * 60)
    }

    func testKeyboardShortcutDefaultIsEmptyAndNotConfigured() {
        let shortcut = KeyboardShortcutSetting()

        XCTAssertEqual(shortcut.key, "")
        XCTAssertEqual(shortcut.modifiers, [])
        XCTAssertFalse(shortcut.isConfigured)
    }

    func testKeyboardShortcutRequiresKeyAndModifier() {
        XCTAssertFalse(KeyboardShortcutSetting(key: "b").isConfigured)
        XCTAssertFalse(KeyboardShortcutSetting(modifiers: [.command]).isConfigured)
        XCTAssertTrue(KeyboardShortcutSetting(key: "b", modifiers: [.command]).isConfigured)
    }

    func testKeyboardShortcutEncodesModifiersAsStrings() throws {
        let shortcut = KeyboardShortcutSetting(key: "b", modifiers: [.command, .shift])
        let data = try JSONEncoder().encode(shortcut)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])

        XCTAssertEqual(json["modifiers"] as? [String], ["shift", "command"])
    }

    func testKeyboardShortcutDecodesLegacyModifierBitmask() throws {
        let legacyCommand = 1 << 20
        let legacyShift = 1 << 17
        let legacyCapsLock = 1 << 16
        let data = Data(#"{"key":"b","modifiers":\#(legacyCommand | legacyShift | legacyCapsLock)}"#.utf8)

        let shortcut = try JSONDecoder().decode(KeyboardShortcutSetting.self, from: data)

        XCTAssertEqual(shortcut.modifiers, [.shift, .command])
    }

    func testResetActiveWorkIfStaleResetsWhenGapExceedsThreshold() {
        let start = Date(timeIntervalSince1970: 0)
        var store = StatsStore(today: start)
        let later = Date(timeIntervalSince1970: 2 * 60 * 60)

        store.resetActiveWorkIfStale(now: later, threshold: 60 * 60)

        XCTAssertEqual(store.activeWorkStartedAt, later)
        XCTAssertEqual(store.continuousWorkDuration(now: later), 0)
    }

    func testResetActiveWorkIfStaleKeepsTimestampWhenWithinThreshold() {
        let start = Date(timeIntervalSince1970: 0)
        var store = StatsStore(today: start)
        let later = Date(timeIntervalSince1970: 30 * 60)

        store.resetActiveWorkIfStale(now: later, threshold: 60 * 60)

        XCTAssertEqual(store.activeWorkStartedAt, start)
        XCTAssertEqual(store.continuousWorkDuration(now: later), 30 * 60)
    }

    func testSystemInterruptionResetsContinuousWorkWithoutChangingBreakCounts() {
        let start = Date(timeIntervalSince1970: 0)
        let interruptedAt = Date(timeIntervalSince1970: 30 * 60)
        var store = StatsStore(today: start)

        store.recordCompletedBreak(now: start)
        store.recordSkippedBreak(now: start)
        store.recordSystemInterruption(now: interruptedAt)

        XCTAssertEqual(store.activeWorkStartedAt, interruptedAt)
        XCTAssertEqual(store.continuousWorkDuration(now: interruptedAt), 0)
        XCTAssertEqual(store.today.completedCount, 1)
        XCTAssertEqual(store.today.skippedCount, 1)
        XCTAssertEqual(store.today.meetingSuppressedCount, 0)
    }

    func testStatsSummariesCompletionRateAndSevenDayTotals() {
        let dayOne = Date(timeIntervalSince1970: 0)
        let dayTwo = Date(timeIntervalSince1970: 24 * 60 * 60)
        var store = StatsStore(today: dayOne)

        store.recordCompletedBreak(now: dayOne)
        store.recordCompletedBreak(now: dayOne)
        store.recordSkippedBreak(now: dayOne)
        store.rolloverIfNeeded(now: dayTwo)
        store.recordCompletedBreak(now: dayTwo)

        XCTAssertEqual(store.todayAttemptedBreakCount, 1)
        XCTAssertEqual(store.todayCompletionRatePercent, 100)
        XCTAssertEqual(store.sevenDayCompletedBreakCount, 3)
        XCTAssertEqual(store.sevenDayAttemptedBreakCount, 4)
    }

    func testRecordCompletedBreakAcrossDayRecordsOnlyNewDayAndResetsActiveWork() {
        let calendar = Calendar.current
        let dayOne = calendar.startOfDay(for: Date(timeIntervalSince1970: 0))
        let dayOneLate = calendar.date(byAdding: .hour, value: 23, to: dayOne)!
        let dayTwoEarly = calendar.date(byAdding: .hour, value: 25, to: dayOne)!
        var store = StatsStore(today: dayOneLate)

        store.recordSkippedBreak(now: dayOneLate)
        store.recordCompletedBreak(now: dayTwoEarly)

        XCTAssertEqual(store.today.day, Calendar.current.startOfDay(for: dayTwoEarly))
        XCTAssertEqual(store.today.completedCount, 1)
        XCTAssertEqual(store.today.skippedCount, 0)
        XCTAssertEqual(store.activeWorkStartedAt, dayTwoEarly)
        XCTAssertEqual(store.sevenDayTrend.first?.skippedCount, 1)
        XCTAssertEqual(store.sevenDayTrend.last?.completedCount, 1)
    }
}
