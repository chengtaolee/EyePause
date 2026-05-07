# App Group Widget Countdown Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Share the next break countdown through an App Group and show it in a macOS Widget.

**Architecture:** Put widget-readable state in `EyePauseCore` as a small Codable snapshot stored in an App Group `UserDefaults`. Have `AppModel` publish the current next-break state every tick; the Widget extension reads only the shared snapshot.

**Tech Stack:** Swift 5.9, SwiftPM core tests, WidgetKit extension in Xcode app target, App Group entitlement, UserDefaults suite.

---

## Assumptions

- App Group identifier is `group.com.eyepause.shared`. Change it once if the final bundle identifier requires a different prefix.
- The current SwiftPM package does not define an Xcode app target or Widget extension. The Core sharing layer can be implemented and tested in SwiftPM; the actual Widget extension must be added in Xcode or a generated `.xcodeproj`.
- Widget displays only "next break countdown" and current status text; it does not provide controls.
- Widget refresh can be coarse. EyePause writes once per second while running, but WidgetKit decides render cadence.

## File Structure

- Create: `Sources/EyePauseCore/WidgetSnapshot.swift`
  - Codable widget state and App Group persistence wrapper.
- Modify: `Tests/EyePauseCoreTests/PersistenceTests.swift`
  - Add in-memory tests for widget snapshot encoding.
- Modify: `Sources/EyePauseApp/AppModel.swift`
  - Publish widget snapshot during `tick`, state changes, and initialization.
- Create: `Sources/EyePauseWidget/EyePauseWidget.swift`
  - WidgetKit provider and view. This requires adding a Widget extension target outside current `Package.swift` for distribution.
- Modify outside SwiftPM package: Xcode project entitlements
  - Add App Group to main app and widget extension.

## Success Criteria

- `swift test --filter WidgetSnapshotTests` passes after adding tests.
- `swift test` passes.
- Manual: widget shows the same next break countdown/status as menu bar within WidgetKit refresh limits.

### Task 1: Core Widget Snapshot

**Files:**
- Create: `Sources/EyePauseCore/WidgetSnapshot.swift`
- Test: `Tests/EyePauseCoreTests/WidgetSnapshotTests.swift`

- [ ] **Step 1: Write failing tests**

Create `Tests/EyePauseCoreTests/WidgetSnapshotTests.swift`:

```swift
import XCTest
@testable import EyePauseCore

final class WidgetSnapshotTests: XCTestCase {
    func testWidgetSnapshotRoundTripsThroughKeyValueStore() throws {
        let memory = MemoryKeyValueStore()
        let store = WidgetSnapshotStore(store: memory)
        let snapshot = WidgetSnapshot(
            nextBreakAt: Date(timeIntervalSince1970: 30 * 60),
            status: "Active",
            updatedAt: Date(timeIntervalSince1970: 0)
        )

        try store.save(snapshot)

        XCTAssertEqual(store.load(), snapshot)
    }

    func testWidgetSnapshotLoadReturnsNilWhenMissing() {
        let store = WidgetSnapshotStore(store: MemoryKeyValueStore())

        XCTAssertNil(store.load())
    }
}

private final class MemoryKeyValueStore: KeyValueStore {
    private var values: [String: Data] = [:]

    func data(forKey key: String) -> Data? {
        values[key]
    }

    func set(_ value: Data?, forKey key: String) {
        values[key] = value
    }
}
```

- [ ] **Step 2: Run tests to verify failure**

Run:

```bash
swift test --filter WidgetSnapshotTests
```

Expected: FAIL with missing `WidgetSnapshot` and `WidgetSnapshotStore`.

- [ ] **Step 3: Add snapshot implementation**

Create `Sources/EyePauseCore/WidgetSnapshot.swift`:

```swift
import Foundation

public struct WidgetSnapshot: Codable, Equatable {
    public var nextBreakAt: Date?
    public var status: String
    public var updatedAt: Date

    public init(nextBreakAt: Date?, status: String, updatedAt: Date = Date()) {
        self.nextBreakAt = nextBreakAt
        self.status = status
        self.updatedAt = updatedAt
    }
}

public struct WidgetSnapshotStore {
    public static let appGroupIdentifier = "group.com.eyepause.shared"

    private let key: String
    private let store: KeyValueStore
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    public init(
        key: String = "EyePause.widgetSnapshot.v1",
        store: KeyValueStore = UserDefaultsStore(defaults: UserDefaults(suiteName: appGroupIdentifier) ?? .standard)
    ) {
        self.key = key
        self.store = store
    }

    public func load() -> WidgetSnapshot? {
        guard let data = store.data(forKey: key) else { return nil }
        return try? decoder.decode(WidgetSnapshot.self, from: data)
    }

    public func save(_ snapshot: WidgetSnapshot) throws {
        let data = try encoder.encode(snapshot)
        store.set(data, forKey: key)
    }
}
```

- [ ] **Step 4: Run tests**

Run:

```bash
swift test --filter WidgetSnapshotTests
```

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add Sources/EyePauseCore/WidgetSnapshot.swift Tests/EyePauseCoreTests/WidgetSnapshotTests.swift
git commit -m "feat: add widget snapshot persistence"
```

### Task 2: Publish Widget Snapshot From AppModel

**Files:**
- Modify: `Sources/EyePauseApp/AppModel.swift`

- [ ] **Step 1: Add store property**

In `AppModel`, after `private let persistence: PersistenceStore`, add:

```swift
private let widgetSnapshotStore = WidgetSnapshotStore()
```

- [ ] **Step 2: Publish initial snapshot**

In `AppModel.init`, after `startTimer()`, add:

```swift
publishWidgetSnapshot(now: now)
```

- [ ] **Step 3: Publish after state-changing actions**

Add `publishWidgetSnapshot(now: Date())` immediately before each `save()` call in:
- `setInterval(_:)`
- `startBreakNow()` after `beginExercise(...)` returns, by adding publication inside `beginExercise(_:)`
- `completeExercise()`
- `delayCurrentReminder()`
- `pause(minutes:)`
- `setManualMeeting(minutes:)`
- `skipForcedBreak()`
- `handleSystemInterruption(now:)`
- `tick(now:)`

Use this exact call:

```swift
publishWidgetSnapshot(now: Date())
```

For methods that already have a `now` local, use:

```swift
publishWidgetSnapshot(now: now)
```

- [ ] **Step 4: Add publisher method**

Add near `save()`:

```swift
private func publishWidgetSnapshot(now: Date) {
    let nextBreakAt: Date?
    switch state {
    case .active:
        nextBreakAt = reminderEngine.nextReminderDate
    case .paused(let until):
        nextBreakAt = until
    case .due, .escalated, .forced, .exerciseRunning, .meetingSuppressed:
        nextBreakAt = nil
    }

    do {
        try widgetSnapshotStore.save(WidgetSnapshot(
            nextBreakAt: nextBreakAt,
            status: stateText,
            updatedAt: now
        ))
    } catch {
        NSLog("EyePause failed to save widget snapshot: \(error.localizedDescription)")
    }
}
```

- [ ] **Step 5: Run tests**

Run:

```bash
swift test
```

Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add Sources/EyePauseApp/AppModel.swift
git commit -m "feat: publish widget countdown snapshot"
```

### Task 3: Widget Extension

**Files:**
- Create: `Sources/EyePauseWidget/EyePauseWidget.swift`
- Modify: Xcode project app target and widget extension target
- Modify: main app entitlements
- Modify: widget extension entitlements

- [ ] **Step 1: Create Widget source**

Create `Sources/EyePauseWidget/EyePauseWidget.swift`:

```swift
import EyePauseCore
import SwiftUI
import WidgetKit

struct EyePauseWidgetEntry: TimelineEntry {
    let date: Date
    let snapshot: WidgetSnapshot?
}

struct EyePauseWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> EyePauseWidgetEntry {
        EyePauseWidgetEntry(
            date: Date(),
            snapshot: WidgetSnapshot(nextBreakAt: Date().addingTimeInterval(25 * 60), status: "Active")
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (EyePauseWidgetEntry) -> Void) {
        completion(EyePauseWidgetEntry(date: Date(), snapshot: WidgetSnapshotStore().load()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<EyePauseWidgetEntry>) -> Void) {
        let now = Date()
        let entry = EyePauseWidgetEntry(date: now, snapshot: WidgetSnapshotStore().load())
        let nextRefresh = Calendar.current.date(byAdding: .minute, value: 1, to: now) ?? now.addingTimeInterval(60)
        completion(Timeline(entries: [entry], policy: .after(nextRefresh)))
    }
}

struct EyePauseWidgetView: View {
    let entry: EyePauseWidgetEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("EyePause")
                .font(.headline)
            Text(entry.snapshot?.status ?? "Not running")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text(countdownText)
                .font(.title3)
                .fontWeight(.semibold)
        }
        .containerBackground(.background, for: .widget)
    }

    private var countdownText: String {
        guard let nextBreakAt = entry.snapshot?.nextBreakAt else {
            return "Due now"
        }
        let minutes = max(0, Int(ceil(nextBreakAt.timeIntervalSince(Date()) / 60)))
        return "Next break in \(minutes) min"
    }
}

@main
struct EyePauseWidget: Widget {
    let kind = "EyePauseWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: EyePauseWidgetProvider()) { entry in
            EyePauseWidgetView(entry: entry)
        }
        .configurationDisplayName("EyePause")
        .description("Shows your next eye break countdown.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
```

- [ ] **Step 2: Add Xcode targets**

In Xcode:
- Add a macOS Widget Extension target named `EyePauseWidgetExtension`.
- Add `Sources/EyePauseWidget/EyePauseWidget.swift` to the widget extension target.
- Link the widget extension against `EyePauseCore`.
- Ensure the main app target also links `EyePauseCore`.

- [ ] **Step 3: Add App Group entitlements**

In both the main app target and widget extension target:
- Enable App Groups.
- Add `group.com.eyepause.shared`.
- Confirm both entitlement files contain:

```xml
<key>com.apple.security.application-groups</key>
<array>
    <string>group.com.eyepause.shared</string>
</array>
```

- [ ] **Step 4: Manual verification**

Build and run the app from Xcode.

Expected:
- Main app writes `EyePause.widgetSnapshot.v1` into the App Group defaults.
- Widget gallery shows EyePause widget.
- Widget displays the next break countdown or "Due now" based on app state.

- [ ] **Step 5: Commit**

```bash
git add Sources/EyePauseWidget/EyePauseWidget.swift Sources/EyePauseApp/AppModel.swift Sources/EyePauseCore/WidgetSnapshot.swift Tests/EyePauseCoreTests/WidgetSnapshotTests.swift
git commit -m "feat: add widget countdown"
```

## Self-Review

- Spec coverage: App Group shared state and macOS widget next-break countdown.
- Placeholder scan: Xcode target creation is explicit because no `.xcodeproj` exists in the current SwiftPM workspace.
- Type consistency: `WidgetSnapshotStore` is defined in Core before app and widget use it.
