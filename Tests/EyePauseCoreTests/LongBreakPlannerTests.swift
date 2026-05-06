import XCTest
@testable import EyePauseCore

final class LongBreakPlannerTests: XCTestCase {
    func testStartsLongBreakAfterFourShortBreaks() {
        var stats = StatsStore(today: Date(timeIntervalSince1970: 0))
        stats.resetActiveWorkStart(now: Date(timeIntervalSince1970: 60))
        var planner = LongBreakPlanner()
        planner.recordCompletedShortBreak()
        planner.recordCompletedShortBreak()
        planner.recordCompletedShortBreak()
        planner.recordCompletedShortBreak()

        XCTAssertTrue(planner.shouldStartLongBreak(now: Date(timeIntervalSince1970: 120), stats: stats))
    }

    func testStartsLongBreakAfterContinuousWorkThreshold() {
        let start = Date(timeIntervalSince1970: 0)
        var stats = StatsStore(today: start)
        stats.resetActiveWorkStart(now: start)
        let planner = LongBreakPlanner()

        XCTAssertTrue(planner.shouldStartLongBreak(now: Date(timeIntervalSince1970: 2 * 60 * 60), stats: stats))
    }

    func testCompletingLongBreakResetsShortBreakProgress() {
        var planner = LongBreakPlanner()
        planner.recordCompletedShortBreak()
        planner.recordCompletedShortBreak()

        planner.recordCompletedLongBreak()

        XCTAssertEqual(planner.shortBreaksSinceLongBreak, 0)
    }
}
