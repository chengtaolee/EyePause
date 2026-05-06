import AppKit
import Foundation
import UserNotifications

@MainActor
final class NotificationCenterAdapter: NSObject {
    let canUseUserNotifications: Bool

    private enum ActionIdentifier {
        static let category = "EYEPAUSE_BREAK_REMINDER"
        static let startBreak = "EYEPAUSE_START_BREAK"
        static let delayFiveMinutes = "EYEPAUSE_DELAY_FIVE_MINUTES"
        static let skip = "EYEPAUSE_SKIP"
    }

    private var actionHandler: ((NotificationAction) -> Void)?

    enum NotificationAction {
        case startBreak
        case delayFiveMinutes
        case skip
    }

    init(canUseUserNotifications: Bool = Bundle.main.bundleURL.pathExtension == "app") {
        self.canUseUserNotifications = canUseUserNotifications
        super.init()
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

    func configureActions(
        startBreakTitle: String,
        delayTitle: String,
        skipTitle: String,
        handler: @escaping @MainActor (NotificationAction) -> Void
    ) {
        guard canUseUserNotifications else { return }
        actionHandler = { action in
            Task { @MainActor in
                handler(action)
            }
        }

        let actions = [
            UNNotificationAction(identifier: ActionIdentifier.startBreak, title: startBreakTitle, options: []),
            UNNotificationAction(identifier: ActionIdentifier.delayFiveMinutes, title: delayTitle, options: []),
            UNNotificationAction(identifier: ActionIdentifier.skip, title: skipTitle, options: [])
        ]
        let category = UNNotificationCategory(
            identifier: ActionIdentifier.category,
            actions: actions,
            intentIdentifiers: [],
            options: []
        )
        let center = UNUserNotificationCenter.current()
        center.setNotificationCategories([category])
        center.delegate = self
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
        content.categoryIdentifier = ActionIdentifier.category
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }
}

extension NotificationCenterAdapter: UNUserNotificationCenterDelegate {
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let action: NotificationAction?
        switch response.actionIdentifier {
        case ActionIdentifier.startBreak, UNNotificationDefaultActionIdentifier:
            action = .startBreak
        case ActionIdentifier.delayFiveMinutes:
            action = .delayFiveMinutes
        case ActionIdentifier.skip:
            action = .skip
        default:
            action = nil
        }

        if let action {
            Task { @MainActor in
                actionHandler?(action)
            }
        }
        completionHandler()
    }
}
