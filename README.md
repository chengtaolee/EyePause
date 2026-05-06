# EyePause

EyePause is a native macOS menu bar app that reminds you to rest your eyes during long computer sessions.

## Run Locally

```bash
swift run EyePause
```

## Test

```bash
swift test
```

## MVP Features

- macOS menu bar app.
- Default 25-minute reminder interval.
- Presets for 20, 25, 30, and 45 minutes.
- Progressive reminder flow: notification first, then prominent reminder after 2 minutes.
- Three exercises:
  - 20-20-20 distant look, 20 seconds.
  - Near/far focus target, 30 seconds.
  - Close eyes / blink rhythm, 30 seconds.
- Optional forced mode with a 4-digit skip code. The code is shown on the
  reminder window itself: it is a friction barrier, not a security gate. The
  goal is to slow down the reflexive "skip" tap, not to lock the user out.
- Manual meeting mode for 30, 60, or 90 minutes.
- Foreground app meeting suppression for native meeting apps such as Zoom, Teams, and FaceTime.
- Local-only settings and simple daily statistics.
- Optional launch-at-login toggle.

## Current Limitations

- Google Meet inside a browser is not detected because the MVP does not inspect browser tabs.
- macOS does not provide a stable public API for checking whether another app is actively using the microphone or camera. The app therefore relies on manual meeting mode and native meeting foreground app detection.
- Forced overlays currently open as a prominent reminder window for the active app session. Full multi-monitor lockout is out of scope for the MVP.
- Swift Package Manager builds a runnable development executable. A distributable signed `.app` bundle still needs a packaging step.
