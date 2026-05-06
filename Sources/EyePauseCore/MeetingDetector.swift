import Foundation

public struct MeetingDetector: Codable, Equatable, Sendable {
    public var manualMeetingUntil: Date?
    public var foregroundAppSuggestsMeeting: Bool
    public var microphoneOrCameraActive: Bool

    public init(
        manualMeetingUntil: Date? = nil,
        foregroundAppSuggestsMeeting: Bool = false,
        microphoneOrCameraActive: Bool = false
    ) {
        self.manualMeetingUntil = manualMeetingUntil
        self.foregroundAppSuggestsMeeting = foregroundAppSuggestsMeeting
        self.microphoneOrCameraActive = microphoneOrCameraActive
    }

    public func isMeetingActive(at date: Date) -> Bool {
        if let manualMeetingUntil, manualMeetingUntil > date {
            return true
        }
        return foregroundAppSuggestsMeeting || microphoneOrCameraActive
    }

    public func knownMeetingEnd(at date: Date) -> Date? {
        if let manualMeetingUntil {
            if manualMeetingUntil > date {
                return manualMeetingUntil
            }
            if !foregroundAppSuggestsMeeting && !microphoneOrCameraActive {
                return manualMeetingUntil
            }
        }
        return isMeetingActive(at: date) ? nil : date
    }
}
