# Dashboard Enhancements Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the approved high-contrast EyePause Dashboard and supporting summary helpers.

**Architecture:** Keep the current `ReminderEngine` state machine and SwiftUI app structure. Add small read-only helpers in core models, then render those values in a new `DashboardView` embedded at the top of the existing settings window.

**Tech Stack:** Swift 5.9, Swift Package Manager, SwiftUI, XCTest.

---

## Files

- Modify `Sources/EyePauseCore/StatsStore.swift` for stats summary helpers.
- Modify `Sources/EyePauseCore/ReminderEngine.swift` for read-only next reminder access.
- Modify `Tests/EyePauseCoreTests/StoreTests.swift` for stats helper coverage.
- Modify `Tests/EyePauseCoreTests/ReminderEngineTests.swift` for next reminder coverage.
- Modify `Sources/EyePauseApp/AppModel.swift` for Dashboard formatting and quick actions.
- Modify `Sources/EyePauseApp/AppStrings.swift` for localized Dashboard copy and exercise steps.
- Create `Sources/EyePauseApp/DashboardView.swift` for the high-contrast Dashboard.
- Modify `Sources/EyePauseApp/SettingsView.swift` to embed the Dashboard.
- Modify `Sources/EyePauseApp/ReminderWindowView.swift` to show step guidance.
- Modify `Sources/EyePauseApp/MenuBarView.swift` to expose new pause/focus options.

## Tasks

- [ ] Add failing stats tests for completion rate and seven-day totals.
- [ ] Implement minimal `StatsStore` summary properties.
- [ ] Add failing reminder tests for next reminder visibility.
- [ ] Implement minimal `ReminderEngine.nextReminderDate`.
- [ ] Add app model formatting helpers and quick pause/focus methods.
- [ ] Add localized strings for Dashboard and exercise step guidance.
- [ ] Create `DashboardView` with high-contrast grouped layout.
- [ ] Embed Dashboard into settings and add pause options to menu bar.
- [ ] Show exercise step guidance in the reminder window.
- [ ] Run `swift test` and `swift build`.

## Verification

- `swift test` must pass.
- `swift build` must pass.
- Manual review should confirm Dashboard text is dark on light backgrounds and avoids low-contrast gray-green combinations.
