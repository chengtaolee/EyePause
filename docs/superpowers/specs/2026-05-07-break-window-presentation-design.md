# Break Window Presentation Design

## Goal

Add a user setting that controls how non-forced break screens appear:

- Centered window: the current default behavior.
- Full screen: a borderless reminder window covering the active screen.

Forced mode remains full screen regardless of this setting.

## Scope

In scope:

- Add a persisted break window presentation setting.
- Add a Settings picker labeled as the break screen/window display mode.
- Apply the setting to non-forced reminder prompts and exercise screens.
- Preserve existing forced-mode behavior.
- Preserve existing users' behavior by defaulting old snapshots to centered window.

Out of scope:

- Native macOS full-screen Spaces.
- Covering all attached displays.
- Changing reminder timing, forced-mode escalation, or exercise content.

## Design

Add a small `Codable` enum in `EyePauseCore`, for example `BreakWindowPresentationMode`, with cases for centered window and full screen. Add it to `SettingsStore` with a default of centered window and `decodeIfPresent` fallback for older persisted settings.

Expose an `AppModel` setter that updates the setting, marks settings dirty, and saves.

Add a picker row in `SettingsView` near the other break-related settings. The picker should show localized labels for centered window and full screen.

Update reminder window presentation so the frame decision is:

- forced presentation: always use the target screen frame.
- non-forced presentation + full-screen setting: use the target screen frame.
- non-forced presentation + centered setting: use the existing centered 560x420 max frame.

`ReminderWindowView` should not need structural changes because it already adapts to available geometry.

## Verification

- Add or update core settings tests for default value and decoding old snapshots without the new field.
- Build or test the Swift package.
- Manual behavior to verify after implementation:
  - With centered setting, non-forced breaks stay centered.
  - With full-screen setting, non-forced breaks fill the active screen.
  - With forced mode, forced breaks fill the active screen no matter which setting is selected.
