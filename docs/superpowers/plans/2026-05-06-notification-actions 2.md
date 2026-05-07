# Notification Actions Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add macOS notification buttons for Start Break, Delay 5 Minutes, and Skip.

**Architecture:** Keep notification category/delegate code inside `NotificationCenterAdapter`. Route user actions back into `AppModel` through explicit closures so `NotificationCenterAdapter` stays UI-framework-light and does not import `EyePauseCore`.

**Tech Stack:** Swift 5.9, UserNotifications, SwiftUI/AppKit app target, XCTest only for non-UI compile coverage.

---

## Assumptions

- "開始休息" maps to `AppModel.startBreakNow()`.
- "延後 5 分鐘" maps to `AppModel.delayCurrentReminder()` and should be ignored when `canDelayCurrentReminder == false`.
- "跳過" maps to existing non-forced skip behavior. Forced breaks still require the code gate in the reminder window, so notification skip should not bypass forced mode.
- Notification action text uses the existing localization table.

## File Structure

- Modify: `Sources/EyePauseApp/NotificationCenterAdapter.swift`
  - Add `UNUserNotificationCenterDelegate`.
  - Register a category with three actions.
  - Dispatch action identifiers through closures.
- Modify: `Sources/EyePauseApp/AppModel.swift`
  - Install notification action handlers.
  - Add a safe `skipCurrentReminderFromNotification()` wrapper.
- Modify: `Sources/EyePauseApp/AppStrings.swift`
  - Reuse existing `startBreakNow`, `delayFiveMinutes`, and `skip` strings.

## Success Criteria

- `swift test` passes.
- Manual: packaged `.app` notification displays three buttons.
- Manual: each action updates state without opening the menu first.

### Task 1: Notification Action Identifiers and Category

**Files:**
- Modify: `Sources/EyePauseApp/NotificationCenterAdapter.swift`

- [ ] **Step 1: Add identifiers**

Inside `NotificationCenterAdapter`, directly after `let canUseUserNotifications: Bool`, add:

```swift
private enum ActionIdentifier {
    static let category = "EYEPAUSE_BREAK_REMINDER"
    static let startBreak = "EYEPAUSE_START_BREAK"
    static let delayFiveMinutes = "EYEPAUSE_DELAY_FIVE_MINUTES"
    static let skip = "EYEPAUSE_SKIP"
}
```

- [ ] **Step 2: Add action closure storage**

Add this property after the identifiers:

```swift
private var actionHandler: ((NotificationAction) -> Void)?
```

Then add this public nested enum inside `NotificationCenterAdapter`:

```swift
enum NotificationAction {
    case startBreak
    case delayFiveMinutes
    case skip
}
```

- [ ] **Step 3: Register notification category**

Add this method to `NotificationCenterAdapter`:

```swift
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
        UNNotificationAction(
            identifier: ActionIdentifier.startBreak,
            title: startBreakTitle,
            options: [.foreground]
        ),
        UNNotificationAction(
            identifier: ActionIdentifier.delayFiveMinutes,
            title: delayTitle,
            options: []
        ),
        UNNotificationAction(
            identifier: ActionIdentifier.skip,
            title: skipTitle,
            options: [.destructive]
        )
    ]
    let category = UNNotificationCategory(
        identifier: ActionIdentifier.category,
        actions: actions,
        intentIdentifiers: [],
        options: []
    )
    UNUserNotificationCenter.current().setNotificationCategories([category])
    UNUserNotificationCenter.current().delegate = self
}
```

- [ ] **Step 4: Attach category to notifications**

In `showNotification(title:body:fallback:)`, after `content.sound = .default`, add:

```swift
content.categoryIdentifier = ActionIdentifier.category
```

- [ ] **Step 5: Add delegate conformance**

At the end of `NotificationCenterAdapter.swift`, add:

```swift
extension NotificationCenterAdapter: UNUserNotificationCenterDelegate {
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
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

        guard let action else { return }
        await MainActor.run {
            actionHandler?(action)
        }
    }
}
```

- [ ] **Step 6: Compile**

Run:

```bash
swift test
```

Expected: PASS. If Swift complains about actor isolation for `actionHandler`, mark `NotificationCenterAdapter` as `final class NotificationCenterAdapter: NSObject` and call `super.init()` from `init`.

- [ ] **Step 7: Commit**

```bash
git add Sources/EyePauseApp/NotificationCenterAdapter.swift
git commit -m "feat: register break reminder notification actions"
```

### Task 2: AppModel Action Routing

**Files:**
- Modify: `Sources/EyePauseApp/AppModel.swift`

- [ ] **Step 1: Install handlers during init**

In `AppModel.init`, immediately after `requestNotificationPermission()`, add:

```swift
configureNotificationActions()
```

- [ ] **Step 2: Add action configuration method**

Add this method near `requestNotificationPermission()`:

```swift
private func configureNotificationActions() {
    notificationAdapter.configureActions(
        startBreakTitle: text(.startBreakNow),
        delayTitle: text(.delayFiveMinutes),
        skipTitle: text(.skip)
    ) { [weak self] action in
        switch action {
        case .startBreak:
            self?.startBreakNow()
        case .delayFiveMinutes:
            self?.delayCurrentReminder()
        case .skip:
            self?.skipCurrentReminderFromNotification()
        }
    }
}
```

- [ ] **Step 3: Add safe skip wrapper**

Add this method near `skipForcedBreak()`:

```swift
func skipCurrentReminderFromNotification() {
    guard currentExercise == nil else { return }
    guard !isForcedPresentation else {
        presentReminderWindow()
        return
    }
    switch state {
    case .due, .escalated:
        reminderEngine.skip(now: Date(), stats: &stats)
        state = reminderEngine.state
        dismissReminderWindow()
        markDirty()
        save()
    case .active, .exerciseRunning, .paused, .meetingSuppressed, .forced:
        break
    }
}
```

- [ ] **Step 4: Reconfigure action labels after language changes**

In `setLanguage(_:)`, after `updateMeetingStatus(now: Date())`, add:

```swift
configureNotificationActions()
```

- [ ] **Step 5: Run tests**

Run:

```bash
swift test
```

Expected: PASS.

- [ ] **Step 6: Manual verification**

Run from packaged app, not only `swift run`, because `NotificationCenterAdapter.canUseUserNotifications` is false for SwiftPM development runs:

```bash
swift build
```

Expected:
- Build succeeds.
- In a signed/package app run, due notifications show Start Break, Delay 5 Minutes, and Skip actions.
- Start Break opens the reminder flow.
- Delay moves the next reminder 5 minutes out.
- Skip records one skipped break only for non-forced due/escalated reminders.

- [ ] **Step 7: Commit**

```bash
git add Sources/EyePauseApp/AppModel.swift
git commit -m "feat: route notification break actions"
```

## Self-Review

- Spec coverage: includes Start Break, Delay 5 Minutes, Skip.
- Placeholder scan: no deferred action behavior.
- Type consistency: `NotificationAction` is defined in `NotificationCenterAdapter` and used by `AppModel`.
