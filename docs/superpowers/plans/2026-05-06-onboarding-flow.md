# Onboarding Flow Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Show a first-launch onboarding flow for notification authorization, launch at login, reminder interval, and language.

**Architecture:** Persist a single `hasCompletedOnboarding` flag in `SettingsStore`. Present onboarding from `AppModel` using the existing `WindowCoordinator` pattern, and reuse existing setters so onboarding changes follow current persistence and localization behavior.

**Tech Stack:** Swift 5.9, SwiftUI, AppKit window coordination, SwiftPM, XCTest.

---

## Assumptions

- Onboarding appears only when `settings.hasCompletedOnboarding == false`.
- The default language remains English until the user chooses another language.
- Notification authorization remains requested on startup as currently implemented; onboarding exposes a button to request/check permission again.
- The flow is a compact single window, not a multi-page wizard, to keep the first version small.

## File Structure

- Modify: `Sources/EyePauseCore/SettingsStore.swift`
  - Add `hasCompletedOnboarding`.
- Modify: `Sources/EyePauseCore/Persistence.swift`
  - Bump schema to `2` and keep legacy decode fallback.
- Modify: `Tests/EyePauseCoreTests/StoreTests.swift`
  - Verify default onboarding flag.
- Modify: `Tests/EyePauseCoreTests/PersistenceTests.swift`
  - Verify new schema version.
- Create: `Sources/EyePauseApp/OnboardingView.swift`
  - Single-window onboarding UI.
- Modify: `Sources/EyePauseApp/AppModel.swift`
  - Present onboarding and expose completion/request methods.
- Modify: `Sources/EyePauseApp/WindowCoordinator.swift`
  - Add onboarding window management.
- Modify: `Sources/EyePauseApp/AppStrings.swift`
  - Add onboarding strings in all current languages.

## Success Criteria

- `swift test` passes.
- First launch opens onboarding once.
- Completing onboarding writes settings and does not show onboarding on next launch.

### Task 1: Persist Onboarding Completion

**Files:**
- Modify: `Sources/EyePauseCore/SettingsStore.swift`
- Modify: `Sources/EyePauseCore/Persistence.swift`
- Test: `Tests/EyePauseCoreTests/StoreTests.swift`
- Test: `Tests/EyePauseCoreTests/PersistenceTests.swift`

- [ ] **Step 1: Write failing settings test**

Add to `Tests/EyePauseCoreTests/StoreTests.swift`:

```swift
func testSettingsDefaultToOnboardingIncomplete() {
    let settings = SettingsStore()

    XCTAssertFalse(settings.hasCompletedOnboarding)
}
```

- [ ] **Step 2: Write failing persistence schema test update**

In `Tests/EyePauseCoreTests/PersistenceTests.swift`, change:

```swift
XCTAssertEqual(json["schemaVersion"] as? Int, 1)
```

to:

```swift
XCTAssertEqual(json["schemaVersion"] as? Int, 2)
```

- [ ] **Step 3: Run tests to verify failure**

Run:

```bash
swift test --filter StoreTests/testSettingsDefaultToOnboardingIncomplete
```

Expected: FAIL with `value of type 'SettingsStore' has no member 'hasCompletedOnboarding'`.

- [ ] **Step 4: Add setting**

In `SettingsStore`, add property:

```swift
public var hasCompletedOnboarding: Bool
```

Update the initializer signature:

```swift
hasCompletedOnboarding: Bool = false,
```

Then assign it in the initializer body:

```swift
self.hasCompletedOnboarding = hasCompletedOnboarding
```

- [ ] **Step 5: Bump schema**

In `Sources/EyePauseCore/Persistence.swift`, change:

```swift
static let currentSchemaVersion = 1
```

to:

```swift
static let currentSchemaVersion = 2
```

- [ ] **Step 6: Run tests**

Run:

```bash
swift test --filter StoreTests/testSettingsDefaultToOnboardingIncomplete
swift test --filter PersistenceTests/testSaveWritesVersionedEnvelope
```

Expected: PASS.

- [ ] **Step 7: Commit**

```bash
git add Sources/EyePauseCore/SettingsStore.swift Sources/EyePauseCore/Persistence.swift Tests/EyePauseCoreTests/StoreTests.swift Tests/EyePauseCoreTests/PersistenceTests.swift
git commit -m "feat: persist onboarding completion"
```

### Task 2: Onboarding Window and Model Hooks

**Files:**
- Create: `Sources/EyePauseApp/OnboardingView.swift`
- Modify: `Sources/EyePauseApp/AppModel.swift`
- Modify: `Sources/EyePauseApp/WindowCoordinator.swift`

- [ ] **Step 1: Inspect existing coordinator**

Run:

```bash
sed -n '1,260p' Sources/EyePauseApp/WindowCoordinator.swift
```

Expected: file contains reminder and settings presentation methods.

- [ ] **Step 2: Add AppModel onboarding hooks**

In `AppModel.init`, after `startTimer()`, add:

```swift
showOnboardingIfNeeded()
```

Add these methods near `showSettings()`:

```swift
func requestNotificationPermissionFromOnboarding() {
    requestNotificationPermission()
}

func completeOnboarding() {
    settings.hasCompletedOnboarding = true
    markDirty()
    save()
    dismissOnboardingWindow()
}
```

Add these private methods near window presentation helpers:

```swift
private func showOnboardingIfNeeded() {
    guard !settings.hasCompletedOnboarding else { return }
    presentOnboardingWindow()
}

private func presentOnboardingWindow() {
    windowCoordinator.presentOnboardingWindow(model: self)
}

private func dismissOnboardingWindow() {
    windowCoordinator.dismissOnboardingWindow()
}
```

- [ ] **Step 3: Add coordinator methods**

In `WindowCoordinator.swift`, add storage:

```swift
private var onboardingWindow: NSWindow?
```

Add methods:

```swift
func presentOnboardingWindow(model: AppModel) {
    if let onboardingWindow {
        onboardingWindow.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        return
    }

    let window = NSWindow(
        contentRect: NSRect(x: 0, y: 0, width: 460, height: 420),
        styleMask: [.titled, .closable],
        backing: .buffered,
        defer: false
    )
    window.title = model.text(.onboardingTitle)
    window.center()
    window.contentView = NSHostingView(rootView: OnboardingView(model: model))
    onboardingWindow = window
    window.makeKeyAndOrderFront(nil)
    NSApp.activate(ignoringOtherApps: true)
}

func dismissOnboardingWindow() {
    onboardingWindow?.close()
    onboardingWindow = nil
}
```

- [ ] **Step 4: Create OnboardingView**

Create `Sources/EyePauseApp/OnboardingView.swift`:

```swift
import EyePauseCore
import SwiftUI

struct OnboardingView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text(model.text(.onboardingTitle))
                .font(.title2)
                .fontWeight(.semibold)

            Picker(model.text(.language), selection: Binding(
                get: { model.settings.language },
                set: { model.setLanguage($0) }
            )) {
                ForEach(AppLanguage.allCases) { language in
                    Text(language.displayName).tag(language)
                }
            }

            Picker(model.text(.reminderInterval), selection: Binding(
                get: { model.settings.interval },
                set: { model.setInterval($0) }
            )) {
                ForEach(ReminderInterval.allCases) { interval in
                    Text(interval.title(language: model.settings.language)).tag(interval)
                }
            }

            Toggle(model.text(.launchAtLogin), isOn: Binding(
                get: { model.settings.launchAtLoginEnabled },
                set: { model.setLaunchAtLogin($0) }
            ))

            VStack(alignment: .leading, spacing: 8) {
                Text(model.text(.notifications))
                    .font(.headline)
                Text(model.notificationStatusText)
                    .foregroundStyle(.secondary)
                Button(model.text(.onboardingEnableNotifications)) {
                    model.requestNotificationPermissionFromOnboarding()
                }
            }

            Spacer()

            HStack {
                Spacer()
                Button(model.text(.onboardingComplete)) {
                    model.completeOnboarding()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(24)
        .frame(width: 460, height: 420)
    }
}
```

- [ ] **Step 5: Compile to reveal missing strings**

Run:

```bash
swift test
```

Expected: FAIL with missing `AppString.onboardingTitle`, `onboardingEnableNotifications`, and `onboardingComplete`.

- [ ] **Step 6: Commit AppModel/coordinator/view changes after strings task passes**

Do not commit yet; proceed to Task 3 first because this task intentionally does not compile until strings are added.

### Task 3: Onboarding Strings

**Files:**
- Modify: `Sources/EyePauseApp/AppStrings.swift`

- [ ] **Step 1: Add AppString cases**

Add cases near the notification strings:

```swift
case onboardingTitle
case onboardingEnableNotifications
case onboardingComplete
```

- [ ] **Step 2: Add English strings**

In the `.english` table, add:

```swift
.onboardingTitle: "Set up EyePause",
.onboardingEnableNotifications: "Enable Notifications",
.onboardingComplete: "Start Using EyePause",
```

- [ ] **Step 3: Add Traditional Chinese strings**

In the `.traditionalChinese` table, add:

```swift
.onboardingTitle: "設定 EyePause",
.onboardingEnableNotifications: "啟用通知",
.onboardingComplete: "開始使用 EyePause",
```

- [ ] **Step 4: Add Simplified Chinese strings**

In the `.simplifiedChinese` table, add:

```swift
.onboardingTitle: "设置 EyePause",
.onboardingEnableNotifications: "启用通知",
.onboardingComplete: "开始使用 EyePause",
```

- [ ] **Step 5: Add Japanese strings**

In the `.japanese` table, add:

```swift
.onboardingTitle: "EyePause を設定",
.onboardingEnableNotifications: "通知を有効にする",
.onboardingComplete: "EyePause を使い始める",
```

- [ ] **Step 6: Add Korean strings**

In the `.korean` table, add:

```swift
.onboardingTitle: "EyePause 설정",
.onboardingEnableNotifications: "알림 켜기",
.onboardingComplete: "EyePause 시작하기",
```

- [ ] **Step 7: Run tests**

Run:

```bash
swift test
```

Expected: PASS.

- [ ] **Step 8: Manual verification**

Run:

```bash
swift run EyePause
```

Expected:
- On first launch with a fresh defaults store, onboarding appears.
- Selecting interval/language updates UI labels.
- Toggle launch at login calls the existing `setLaunchAtLogin`.
- Complete closes the onboarding window.

- [ ] **Step 9: Commit**

```bash
git add Sources/EyePauseApp/AppModel.swift Sources/EyePauseApp/WindowCoordinator.swift Sources/EyePauseApp/OnboardingView.swift Sources/EyePauseApp/AppStrings.swift
git commit -m "feat: add first launch onboarding"
```

## Self-Review

- Spec coverage: notification authorization, launch at login, interval, language.
- Placeholder scan: no deferred-work markers or generic "add UI" steps.
- Type consistency: `hasCompletedOnboarding` is persisted and referenced consistently.
