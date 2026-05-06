import AppKit
import Foundation
import UserNotifications

@MainActor
final class NotificationCenterAdapter {
    let canUseUserNotifications: Bool

    init(canUseUserNotifications: Bool = Bundle.main.bundleURL.pathExtension == "app") {
        self.canUseUserNotifications = canUseUserNotifications
    }

    func requestPermission(update: @escaping @MainActor @Sendable (Bool) -> Void) {
        guard canUseUserNotifications else { return }
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            switch settings.authorizationStatus {
            case .notDetermined:
                UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
                    if let error {
                        NSLog("EyePause failed to request notification authorization: \(error.localizedDescription)")
                    }
                    Task { @MainActor in
                        update(granted)
                    }
                }
            case .authorized, .provisional:
                Task { @MainActor in
                    update(true)
                }
            case .denied:
                Task { @MainActor in
                    update(false)
                }
            @unknown default:
                Task { @MainActor in
                    update(false)
                }
            }
        }
    }

    func showNotification(title: String, body: String, fallback: @escaping @MainActor () -> Void) {
        guard canUseUserNotifications else {
            fallback()
            return
        }
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }
}
