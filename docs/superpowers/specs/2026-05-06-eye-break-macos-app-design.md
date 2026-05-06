# EyePause macOS App Design Spec

**Date:** 2026-05-06
**Product Name:** EyePause
**Platform:** macOS
**Primary Form Factor:** Menu bar app
**Status:** MVP scope approved in discussion

## Product Goal

Build a lightweight macOS menu bar app that helps long-duration computer users remember to rest their eyes, alternate near/far focus, and reduce continuous screen fixation without disrupting meetings or critical work.

The app should be quiet during normal operation, obvious when a break is overdue, and optionally strict when the user explicitly enables stronger self-control.

## Target User

The initial user is a macOS user who works at a computer for long periods and sometimes forgets to look away from the screen. They want reminders that are practical during real work, including meetings, and they want a fallback screen-based focus exercise when looking into the distance is not possible.

## MVP Summary

The MVP is a native SwiftUI macOS menu bar app with:

- Fixed interval reminders with quick presets.
- Progressive reminder escalation.
- Three eye rest exercises.
- Optional forced break mode.
- Meeting-aware suppression and delayed catch-up reminders.
- Local-only minimal statistics.
- Optional launch at login.

## Non-Goals

The MVP will not include:

- Cloud sync.
- Account login.
- Browser extension support.
- Cross-device statistics.
- Detailed website or app usage history.
- Medical diagnosis, treatment claims, or vision correction claims.
- Full multi-monitor forced overlays.

## Product Disclaimer

Screen-based focus exercises are a convenience fallback, not a complete replacement for looking at a real distant object. The product should avoid medical claims and frame itself as a reminder and habit-support tool.

## Core Decisions

### App Shell

The app is a native SwiftUI macOS app that lives primarily in the menu bar.

The app should avoid occupying persistent Dock or desktop space during normal operation. The menu bar item is the user's main control surface for current state, preset selection, meeting mode, forced mode, and statistics.

### Reminder Interval

The reminder interval is fixed rather than adaptive in the MVP.

Available presets:

- 20 minutes
- 25 minutes
- 30 minutes
- 45 minutes

Default interval: 25 minutes.

After a completed exercise, the timer restarts. Users can delay a reminder by 5 minutes or pause reminders for 30, 60, or 90 minutes.

### Progressive Escalation

Reminder escalation follows this sequence:

1. At the due time, show a macOS notification and update the menu bar icon state.
2. If the reminder remains unhandled for 2 minutes, show a prominent always-on-top reminder window.
3. If forced mode is enabled, the prominent reminder can become a near full-screen overlay.

The default behavior is not forced. Forced mode must be explicitly enabled by the user.

### Meeting-Aware Behavior

The app should avoid interrupting meetings.

Meeting detection combines:

- Manual meeting mode.
- Foreground app detection.
- Microphone and camera activity detection.

Manual meeting mode always wins. While it is enabled, the app does not show popups or forced overlays.

If the app infers that the user is likely in a meeting, reminders become silent and are recorded as missed breaks. After the meeting ends, the app waits 2 minutes and then shows a prominent but skippable reminder.

Forced mode is also suppressed during meetings by default.

### Exercises

The MVP includes three exercises.

#### 20-20-20 Distant Look

Duration: 20 seconds.

The user is prompted to look at a distant object. The UI should be minimal: countdown, exercise title, and a calm visual state. It should not include dense instruction text during the exercise.

#### Screen-Based Near/Far Focus

Duration: 30 seconds.

The UI shows a minimal animated focus target rather than complex imagery. The focus target alternates between visually "near" and "far" states every 5 seconds using size, contrast, or spatial depth cues.

This exercise is a fallback for moments when the user cannot look away from the screen. The settings or onboarding copy should make clear that it does not fully replace real distance viewing.

#### Close Eyes / Blink Rhythm

Duration: 30 seconds.

The UI guides the user through closing their eyes or blinking at a steady rhythm. It should use a simple countdown and low-stimulation visuals.

### Forced Mode

Forced mode is off by default.

When enabled, the app may show a near full-screen overlay for overdue reminders. The user can complete the exercise normally or skip it by entering a displayed 4-digit random code.

Skipping a forced break records a local skip event.

Forced mode should not override meeting suppression by default.

### Window Strategy

Default prominent reminders use a small always-on-top window.

Forced mode can use a near full-screen overlay.

For multi-monitor setups in the MVP:

- Prominent reminders appear on the screen containing the mouse pointer.
- If the pointer screen cannot be determined, use the main screen.
- Forced overlays cover only that selected screen.
- Full multi-monitor forced coverage is out of scope.

If the user is inside a full-screen app or another Space, the MVP may fall back to notification behavior rather than forcibly switching Spaces.

### Launch at Login

Launch at login is supported as an optional setting.

The app should ask the user after onboarding whether they want to enable login launch. It should not silently enable itself.

Use Apple's supported login item mechanism for macOS.

## Menu Bar Structure

The menu bar menu should include:

- Current timer state.
- Start break now.
- Reminder interval preset picker: 20, 25, 30, 45 minutes.
- Delay current reminder by 5 minutes.
- Pause reminders: 30, 60, 90 minutes.
- Meeting mode: 30, 60, 90 minutes, and off.
- Forced mode toggle.
- Today's statistics summary.
- Settings.
- Quit.

The menu bar icon should visually distinguish normal, due, paused, meeting, and forced states.

## State Model

The app should model reminder behavior as explicit states:

- `active`: Timer is running.
- `due`: Reminder has reached its interval and a notification has been shown.
- `escalated`: Reminder was not handled after 2 minutes and a prominent window is visible.
- `exerciseRunning`: User is completing an exercise.
- `paused`: User manually paused reminders.
- `meetingSuppressed`: Reminder is due but suppressed because of manual or inferred meeting state.
- `forced`: Forced mode is enabled and the current reminder can require completion or a 4-digit skip code.

State transitions:

- `active` to `due`: Reminder interval elapses.
- `due` to `escalated`: 2 minutes pass without completion, delay, skip, or meeting suppression.
- `due` or `escalated` to `exerciseRunning`: User starts an exercise.
- `exerciseRunning` to `active`: Exercise completes.
- `due` or `escalated` to `active`: User skips or delays, with local statistics updated.
- Any active reminder state to `meetingSuppressed`: Manual meeting mode or inferred meeting state is active.
- `meetingSuppressed` to `due`: Meeting ends, then 2-minute catch-up delay completes.

## Local Statistics

All statistics are stored locally.

The MVP records:

- Completed breaks today.
- Skipped breaks today.
- Meeting-suppressed reminders today.
- Current continuous work duration.
- Seven-day trend summary.

The MVP must not record:

- Website content.
- Meeting content.
- Audio content.
- Camera images.
- Detailed keyboard input.

## Permissions

Expected macOS permissions or system integrations:

- Notifications for reminder alerts.
- Accessibility permissions for foreground app detection if required by implementation.
- Camera and microphone activity visibility where supported by macOS APIs.
- Login item registration for launch at login.

The app should degrade gracefully if permissions are denied:

- Without notification permission, rely on menu bar state and reminder windows.
- Without foreground app detection, rely on manual meeting mode and microphone/camera signals.
- Without microphone/camera visibility, rely on manual meeting mode and foreground app detection.
- Without login item permission or support, keep launch at login disabled.

## Technical Architecture

Recommended stack:

- Swift
- SwiftUI
- AppKit integration where needed for menu bar, window levels, notifications, and system state
- UserDefaults or a small local store for settings and daily statistics

Proposed modules:

- `AppShell`: app lifecycle, menu bar item, settings entry points.
- `ReminderEngine`: timer scheduling, interval presets, pause/delay behavior, escalation.
- `MeetingDetector`: manual meeting mode, foreground app detection, microphone/camera activity signals.
- `ExerciseEngine`: exercise selection, countdowns, completion and skip events.
- `OverlayController`: prominent reminder window and forced overlay presentation.
- `StatsStore`: local minimal statistics and seven-day trend aggregation.
- `SettingsStore`: persistent user preferences.

## Testing Strategy

Unit tests should cover:

- Timer interval transitions.
- 2-minute escalation behavior.
- Pause and delay behavior.
- Meeting suppression and catch-up reminder timing.
- Forced-mode skip code behavior.
- Statistics updates for completion, skip, and meeting suppression.

Manual QA should cover:

- Menu bar behavior after launch.
- Notification permission denied and granted paths.
- Reminder escalation from notification to window.
- Exercise completion for all three exercise types.
- Forced-mode skip with a 4-digit code.
- Manual meeting mode suppression.
- Foreground meeting app suppression where supported.
- Login item toggle behavior.

## MVP Acceptance Criteria

The MVP is acceptable when:

- The app runs as a macOS menu bar app.
- The default interval is 25 minutes.
- The user can switch interval presets.
- A reminder shows at the due time.
- Unhandled reminders escalate after 2 minutes.
- The user can complete all three exercises.
- Forced mode requires either exercise completion or 4-digit code skip.
- Meeting mode suppresses popups and overlays.
- Suppressed meeting reminders produce a catch-up reminder 2 minutes after the meeting ends.
- Local statistics show completed, skipped, and meeting-suppressed counts.
- Launch at login can be enabled or disabled by the user.
