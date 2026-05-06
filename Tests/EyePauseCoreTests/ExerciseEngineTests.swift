import XCTest
@testable import EyePauseCore

final class ExerciseEngineTests: XCTestCase {
    func testExerciseDurationsMatchMVPDefaults() {
        XCTAssertEqual(Exercise.distantLook.durationSeconds, 20)
        XCTAssertEqual(Exercise.nearFarFocus.durationSeconds, 30)
        XCTAssertEqual(Exercise.closeEyes.durationSeconds, 30)
    }

    func testExercisesRotateInDefinedOrder() {
        var engine = ExerciseEngine()

        XCTAssertEqual(engine.nextExercise(), .distantLook)
        XCTAssertEqual(engine.nextExercise(), .nearFarFocus)
        XCTAssertEqual(engine.nextExercise(), .closeEyes)
        XCTAssertEqual(engine.nextExercise(), .distantLook)
    }

    func testForcedSkipOnlyValidatesDisplayedFourDigitCode() {
        let stats = StatsStore(today: Date(timeIntervalSince1970: 0))
        let gate = ForcedSkipGate(code: "4821")

        XCTAssertFalse(gate.canSkip(with: "4820"))
        XCTAssertEqual(stats.today.skippedCount, 0)

        XCTAssertTrue(gate.canSkip(with: "4821"))
        XCTAssertEqual(stats.today.skippedCount, 0)
    }
}
