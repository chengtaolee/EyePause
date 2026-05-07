import AppKit
import EyePauseCore
import SwiftUI

@MainActor
final class WindowCoordinator {
    private var reminderWindow: NSWindow?
    private var settingsWindow: NSWindow?
    private var onboardingWindow: NSWindow?

    func presentReminderWindow(
        model: AppModel,
        isForcedPresentation: Bool,
        presentationMode: BreakWindowPresentationMode
    ) {
        let frame = reminderWindowFrame(
            isForcedPresentation: isForcedPresentation,
            presentationMode: presentationMode
        )
        let window = reminderWindow ?? makeReminderWindow(
            title: "EyePause Reminder",
            level: isForcedPresentation ? .screenSaver : .floating,
            frame: frame
        )
        reminderWindow = window
        window.setFrame(frame, display: true)
        window.level = isForcedPresentation ? .screenSaver : .floating
        window.contentView = NSHostingView(rootView: ReminderWindowView(model: model))
        show(window)
    }

    func presentSettingsWindow(model: AppModel) {
        let window = settingsWindow ?? makeWindow(
            title: "EyePause Settings",
            size: NSSize(width: 720, height: 760),
            level: .normal
        )
        settingsWindow = window
        window.contentView = NSHostingView(rootView: SettingsView(model: model))
        show(window)
    }

    func presentOnboardingWindow(model: AppModel) {
        let window = onboardingWindow ?? makeWindow(
            title: model.text(.onboardingTitle),
            size: NSSize(width: 460, height: 420),
            level: .normal
        )
        onboardingWindow = window
        window.title = model.text(.onboardingTitle)
        window.contentView = NSHostingView(rootView: OnboardingView(model: model))
        show(window)
    }

    func dismissReminderWindow() {
        reminderWindow?.orderOut(nil)
        NSApp.setActivationPolicy(.accessory)
    }

    func dismissOnboardingWindow() {
        onboardingWindow?.orderOut(nil)
    }

    private func makeWindow(title: String, size: NSSize, level: NSWindow.Level) -> NSWindow {
        let window = NSWindow(
            contentRect: NSRect(origin: .zero, size: size),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = title
        window.level = level
        window.isReleasedWhenClosed = false
        window.center()
        return window
    }

    private func makeReminderWindow(title: String, level: NSWindow.Level, frame: NSRect) -> NSWindow {
        let window = NSWindow(
            contentRect: frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        window.title = title
        window.level = level
        window.isReleasedWhenClosed = false
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.isOpaque = true
        window.backgroundColor = .black
        return window
    }

    private func reminderWindowFrame(
        isForcedPresentation: Bool,
        presentationMode: BreakWindowPresentationMode
    ) -> NSRect {
        let screenFrame = targetScreenFrame()
        let shouldUseFullScreen = isForcedPresentation || presentationMode == .fullScreen
        guard !shouldUseFullScreen else { return screenFrame }
        let width = min(560, screenFrame.width * 0.9)
        let height = min(420, screenFrame.height * 0.8)
        return NSRect(
            x: screenFrame.midX - width / 2,
            y: screenFrame.midY - height / 2,
            width: width,
            height: height
        )
    }

    private func show(_ window: NSWindow) {
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
    }

    private func targetScreenFrame() -> NSRect {
        let mouseLocation = NSEvent.mouseLocation
        let screen = NSScreen.screens.first { NSMouseInRect(mouseLocation, $0.frame, false) } ?? NSScreen.main
        return screen?.frame ?? NSRect(x: 0, y: 0, width: 1280, height: 800)
    }
}
