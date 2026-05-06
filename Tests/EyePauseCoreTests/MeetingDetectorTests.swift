import XCTest
@testable import EyePauseCore

final class MeetingDetectorTests: XCTestCase {
    func testForegroundMeetingSignalIsActiveWhenCameraSignalIsUnavailable() {
        let detector = MeetingDetector(
            foregroundAppSuggestsMeeting: true,
            microphoneOrCameraActive: false
        )

        XCTAssertTrue(detector.isMeetingActive(at: Date(timeIntervalSince1970: 0)))
    }

    func testKnownMeetingEndReturnsManualMeetingUntilWhenSet() {
        let future = Date(timeIntervalSince1970: 60 * 60)
        let detector = MeetingDetector(manualMeetingUntil: future)
        let now = Date(timeIntervalSince1970: 0)

        XCTAssertEqual(detector.knownMeetingEnd(at: now), future)
    }

    func testKnownMeetingEndReturnsNilWhileForegroundMeetingSignalIsActive() {
        let detector = MeetingDetector(foregroundAppSuggestsMeeting: true)
        XCTAssertNil(detector.knownMeetingEnd(at: Date(timeIntervalSince1970: 0)))
    }

    func testKnownMeetingEndIgnoresExpiredManualMeetingWhileActiveSignalRemains() {
        let detector = MeetingDetector(
            manualMeetingUntil: Date(timeIntervalSince1970: 60),
            microphoneOrCameraActive: true
        )

        XCTAssertNil(detector.knownMeetingEnd(at: Date(timeIntervalSince1970: 120)))
    }

    func testKnownMeetingEndReturnsNowWhenIdle() {
        let detector = MeetingDetector()
        let now = Date(timeIntervalSince1970: 60 * 60)
        XCTAssertEqual(detector.knownMeetingEnd(at: now), now)
    }
}
