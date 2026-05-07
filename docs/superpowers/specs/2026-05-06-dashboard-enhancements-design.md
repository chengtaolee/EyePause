# Dashboard Enhancements Design

## Goal

Add a high-contrast Dashboard to EyePause that brings the app's current reminder status, quick controls, break health, long-break progress, notification status, and meeting-mode explanation into one readable view.

## Scope

This design covers the first seven requested improvements:

- Show the next reminder countdown.
- Add clearer pause/focus quick options.
- Surface useful today and seven-day statistics.
- Show more actionable exercise guidance.
- Make long-break progress visible.
- Explain notification permission and development-run behavior.
- Clarify meeting mode as best-effort detection plus reliable manual controls.

Packaging and release preparation are deliberately out of scope for this pass.

## UX Direction

Use the approved high-contrast compact Dashboard layout inside the existing settings window. The Dashboard should use macOS-native SwiftUI controls and avoid low-contrast gray-green text. It should read as a utility panel, not a marketing page.

The settings window will show a Dashboard section above existing settings. It will include:

- A current-status block with state, next break text, continuous work, and meeting status.
- A quick-actions block with Start Break, Delay 5 min, Focus 1 hour, Pause 10 min, and Pause Today.
- A statistics block with completed, skipped, meeting-suppressed, completion rate, and seven-day completed total.
- A break-plan block with long-break progress and exercise guidance.
- A system-notes block with notification and meeting-mode explanations.

## Data Model

Keep changes small and local:

- Add read-only summary helpers to `StatsStore` for attempted breaks, completion rate, seven-day completed count, and seven-day attempted count.
- Add read-only formatting helpers in `AppModel` for next-break, notification status, long-break progress, and pause actions.
- Preserve the existing `ReminderEngine` state machine. Expose `nextReminderAt` through a read-only method instead of redesigning the engine.
- Keep exercise steps as localized app strings selected by the existing `Exercise` enum.

## Testing

Core behavior should be tested in `EyePauseCoreTests`:

- `StatsStore` computes completion rate and seven-day totals correctly.
- `ReminderEngine` exposes next reminder timing after init, delay, pause expiry, completion, and skip.

UI-only copy and SwiftUI layout will be verified by `swift test` plus `swift build`, because the current package has no UI snapshot test harness.

## Constraints

- No external packages.
- No broad refactor.
- No browser-tab inspection for Google Meet.
- No packaging or signing in this pass.
