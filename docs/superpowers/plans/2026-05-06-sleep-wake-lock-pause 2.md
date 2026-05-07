# Sleep Wake Lock Pause Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Pause or reset continuous-work accounting when macOS sleeps, wakes, or locks the screen.

**Architecture:** Keep system notification wiring in `EyePauseApp/AppModel.swift`, because `AppModel` already owns `NSWorkspace.didWakeNotification` and app lifecycle coordination. Keep pure time-accounting behavior in `EyePauseCore/StatsStore.swift` so it remains unit-testable without AppKit.

**Tech Stack:** Swift 5.9, SwiftPM, AppKit `NSWorkspace` notifications, XCTest.

---

## Assumptions

- "Auto pause continuous work timer" means the continuous-work duration shown in UI must not include time spent asleep or locked.
- Sleep/lock should not count as a skipped or completed break.
- On wake/unlock, the simplest correct behavior is to reset `StatsStore.activeWorkStartedAt` to the current time; this matches the existing `handleSystemDidWake(now:)` behavior and avoids adding a new persisted pause state.
- `NSWorkspace.screensDidUnlockNotification` is included with `screensDidLockNotification` so lock and unlock are symmetrical. If only lock is observed, the continuous timer can keep growing while locked until the next tick after unlock.

## File Structure

- Modify: `Sources/EyePauseCore/StatsStore.swift`
  - Add a semantic wrapper for system interruptions.
- Modify: `Tests/EyePauseCoreTests/StoreTests.swift`
  - Prove interruption resets continuous-work start without changing break counts.
- Modify: `Sources/EyePauseApp/AppModel.swift`
  - Replace single `wakeObserver` with multiple workspace observers.
  - Observe `willSleepNotification`, `didWakeNotification`, `screensDidLockNotification`, and `screensDidUnlockNotification`.

## Success Criteria

- `swift test --filter StoreTests/testSystemInterruptionResetsContinuousWorkWithoutChangingBreakCounts` passes.
- `swift test` passes.
- Manual: start app, note continuous work, lock screen, unlock, verify continuous work restarts near `0分鐘`.

### Task 1: Core Interruption Accounting

**Files:**
- Modify: `Sources/EyePauseCore/StatsStore.swift`
- Test: `Tests/EyePauseCoreTests/StoreTests.swift`

- [ ] **Step 1: Write the failing test**

Add this test near the other continuous-work tests in `Tests/EyePauseCoreTests/StoreTests.swift`:

```swift
func testSystemInterruptionResetsContinuousWorkWithoutChangingBreakCounts() {
    let start = Date(timeIntervalSince1970: 0)
    let interruptedAt = Date(timeIntervalSince1970: 30 * 60)
    var store = StatsStore(today: start)

    store.recordCompletedBreak(now: start)
    store.recordSkippedBreak(now: start)
    store.recordSystemInterruption(now: interruptedAt)

    XCTAssertEqual(store.activeWorkStartedAt, interruptedAt)
    XCTAssertEqual(store.continuousWorkDuration(now: interruptedAt), 0)
    XCTAssertEqual(store.today.completedCount, 1)
    XCTAssertEqual(store.today.skippedCount, 1)
    XCTAssertEqual(store.today.meetingSuppressedCount, 0)
}
```

- [ ] **Step 2: Run test to verify it fails**

Run:

```bash
swift test --filter StoreTests/testSystemInterruptionResetsContinuousWorkWithoutChangingBreakCounts
```

Expected: FAIL with `value of type 'StatsStore' has no member 'recordSystemInterruption'`.

- [ ] **Step 3: Write minimal implementation**

In `Sources/EyePauseCore/StatsStore.swift`, add this public method immediately after `recordMeetingSuppression(now:)`:

```swift
public mutating func recordSystemInterruption(now: Date = Date()) {
    rolloverIfNeeded(now: now)
    activeWorkStartedAt = now
    replaceTodayInTrend()
}
```

- [ ] **Step 4: Run test to verify it passes**

Run:

```bash
swift test --filter StoreTests/testSystemInterruptionResetsContinuousWorkWithoutChangingBreakCounts
```

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add Sources/EyePauseCore/StatsStore.swift Tests/EyePauseCoreTests/StoreTests.swift
git commit -m "feat: track system interruption work resets"
```

### Task 2: Workspace Sleep Lock Observers

**Files:**
- Modify: `Sources/EyePauseApp/AppModel.swift`

- [ ] **Step 1: Replace observer storage**

In `Sources/EyePauseApp/AppModel.swift`, replace:

```swift
private var wakeObserver: NSObjectProtocol?
```

with:

```swift
private var workspaceObservers: [NSObjectProtocol] = []
```

- [ ] **Step 2: Update deinit cleanup**

Replace:

```swift
if let wakeObserver {
    NSWorkspace.shared.notificationCenter.removeObserver(wakeObserver)
}
```

with:

```swift
for observer in workspaceObservers {
    NSWorkspace.shared.notificationCenter.removeObserver(observer)
}
```

- [ ] **Step 3: Replace workspace observer installation**

Replace the entire `installWorkspaceObservers()` method with:

```swift
private func installWorkspaceObservers() {
    let notificationCenter = NSWorkspace.shared.notificationCenter
    let names: [NSNotification.Name] = [
        NSWorkspace.willSleepNotification,
        NSWorkspace.didWakeNotification,
        NSWorkspace.screensDidLockNotification,
        NSWorkspace.screensDidUnlockNotification
    ]

    workspaceObservers = names.map { name in
        notificationCenter.addObserver(
            forName: name,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.handleSystemInterruption(now: Date())
            }
        }
    }
}
```

- [ ] **Step 4: Replace wake handler with interruption handler**

Replace:

```swift
private func handleSystemDidWake(now: Date) {
    stats.rolloverIfNeeded(now: now)
    stats.resetActiveWorkStart(now: now)
    markDirty()
    save()
}
```

with:

```swift
private func handleSystemInterruption(now: Date) {
    stats.recordSystemInterruption(now: now)
    markDirty()
    save()
}
```

- [ ] **Step 5: Run full tests**

Run:

```bash
swift test
```

Expected: PASS.

- [ ] **Step 6: Manual verification**

Run:

```bash
swift run EyePause
```

Expected:
- Menu bar app starts.
- After locking and unlocking the screen, the continuous-work text restarts near zero.
- No completed/skipped/meeting-suppressed counts change because of lock/unlock alone.

- [ ] **Step 7: Commit**

```bash
git add Sources/EyePauseApp/AppModel.swift
git commit -m "feat: pause work timer for workspace interruptions"
```

## Self-Review

- Spec coverage: covers sleep, wake, screen lock, and screen unlock. Uses reset semantics already present in the app.
- Placeholder scan: no deferred implementation text.
- Type consistency: `recordSystemInterruption(now:)` is defined before `AppModel` uses it.
