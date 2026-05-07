# Break Window Presentation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a persisted setting that lets non-forced break screens use either the current centered window or a full-screen window, while forced mode remains full screen.

**Architecture:** Store the display mode in `SettingsStore` as a small `Codable` enum with an old-snapshot fallback. Route App UI changes through `AppModel`, and keep final window frame selection inside `WindowCoordinator`.

**Tech Stack:** Swift 5.9, SwiftUI, AppKit, XCTest, Swift Package Manager.

---

### Task 1: Persisted Core Setting

**Files:**
- Modify: `Sources/EyePauseCore/SettingsStore.swift`
- Test: `Tests/EyePauseCoreTests/StoreTests.swift`

- [ ] **Step 1: Write failing tests**

Add tests that require the new setting to default to centered and decode old JSON without the new field:

```swift
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
```

- [ ] **Step 2: Run tests and verify RED**

Run: `swift test --filter StoreTests`

Expected: fails because `breakWindowPresentationMode` and `BreakWindowPresentationMode` do not exist.

- [ ] **Step 3: Implement minimal core setting**

In `SettingsStore.swift`, add:

```swift
public enum BreakWindowPresentationMode: String, CaseIterable, Codable, Equatable, Identifiable, Sendable {
    case centeredWindow
    case fullScreen

    public var id: String { rawValue }

    public func title(language: AppLanguage) -> String {
        switch self {
        case .centeredWindow:
            switch language {
            case .english: return "Centered window"
            case .traditionalChinese: return "置中視窗"
            case .simplifiedChinese: return "居中窗口"
            case .japanese: return "中央ウィンドウ"
            case .korean: return "가운데 창"
            }
        case .fullScreen:
            switch language {
            case .english: return "Full screen"
            case .traditionalChinese: return "滿版全螢幕"
            case .simplifiedChinese: return "全屏满版"
            case .japanese: return "全画面"
            case .korean: return "전체 화면"
            }
        }
    }
}
```

Then add `public var breakWindowPresentationMode: BreakWindowPresentationMode`, a coding key, init parameter defaulting to `.centeredWindow`, `decodeIfPresent(... ) ?? .centeredWindow`, and encode it.

- [ ] **Step 4: Run tests and verify GREEN**

Run: `swift test --filter StoreTests`

Expected: all `StoreTests` pass.

### Task 2: Settings UI and AppModel Setter

**Files:**
- Modify: `Sources/EyePauseApp/AppModel.swift`
- Modify: `Sources/EyePauseApp/SettingsView.swift`
- Modify: `Sources/EyePauseApp/AppStrings.swift`

- [ ] **Step 1: Add AppModel setter**

Add:

```swift
func setBreakWindowPresentationMode(_ mode: BreakWindowPresentationMode) {
    settings.breakWindowPresentationMode = mode
    markDirty()
    save()
}
```

- [ ] **Step 2: Add localized row label**

Add `case breakWindowPresentation` to `AppString`, and add localized values:

```swift
.breakWindowPresentation: "Break screen",
.breakWindowPresentation: "休息畫面",
.breakWindowPresentation: "休息画面",
.breakWindowPresentation: "休憩画面",
.breakWindowPresentation: "휴식 화면",
```

- [ ] **Step 3: Add Settings picker**

In `SettingsView`, add a `settingRow` near the duration settings:

```swift
settingRow(model.text(.breakWindowPresentation)) {
    Picker(model.text(.breakWindowPresentation), selection: Binding(
        get: { model.settings.breakWindowPresentationMode },
        set: { model.setBreakWindowPresentationMode($0) }
    )) {
        ForEach(BreakWindowPresentationMode.allCases) { mode in
            Text(mode.title(language: model.settings.language)).tag(mode)
        }
    }
    .labelsHidden()
    .frame(width: 180, alignment: .leading)
}
```

- [ ] **Step 4: Build to verify UI code compiles**

Run: `swift build`

Expected: build succeeds.

### Task 3: Window Frame Decision

**Files:**
- Modify: `Sources/EyePauseApp/AppModel.swift`
- Modify: `Sources/EyePauseApp/WindowCoordinator.swift`

- [ ] **Step 1: Thread the setting into the coordinator**

Update `AppModel.presentReminderWindow()` to pass `settings.breakWindowPresentationMode`.

- [ ] **Step 2: Apply mode in frame calculation**

Update `WindowCoordinator.presentReminderWindow` and `reminderWindowFrame` so the frame decision is:

```swift
let shouldUseFullScreen = isForcedPresentation || presentationMode == .fullScreen
```

Return the full target screen frame when `shouldUseFullScreen` is true, otherwise return the existing centered frame.

- [ ] **Step 3: Run full tests and build**

Run: `swift test`

Expected: all tests pass.

Run: `swift build`

Expected: build succeeds.
