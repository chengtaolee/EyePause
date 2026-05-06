import AppKit
import EyePauseCore
import Foundation

@MainActor
final class SystemMeetingSignal {
    var manualMeetingUntil: Date?

    private let nativeMeetingBundleIdentifiers: Set<String> = [
        "us.zoom.xos",
        "com.microsoft.teams",
        "com.microsoft.teams2",
        "com.apple.FaceTime"
    ]

    func meetingDetector(now: Date) -> MeetingDetector {
        MeetingDetector(
            manualMeetingUntil: manualMeetingUntil,
            foregroundAppSuggestsMeeting: foregroundAppSuggestsMeeting,
            microphoneOrCameraActive: false
        )
    }

    private var foregroundAppSuggestsMeeting: Bool {
        guard let bundleIdentifier = NSWorkspace.shared.frontmostApplication?.bundleIdentifier else {
            return false
        }
        return nativeMeetingBundleIdentifiers.contains(bundleIdentifier)
    }
}
