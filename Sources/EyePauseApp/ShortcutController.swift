@preconcurrency import AppKit
import EyePauseCore
import Foundation

@MainActor
final class ShortcutController {
    var isRecording = false
    private var localKeyMonitor: Any?
    private var globalKeyMonitor: Any?

    deinit {
        MainActor.assumeIsolated {
            invalidate()
        }
    }

    func installMonitors(
        shortcut: @escaping @MainActor () -> KeyboardShortcutSetting,
        canTrigger: @escaping @MainActor () -> Bool,
        capture: @escaping @MainActor (NSEvent) -> Bool,
        startBreak: @escaping @MainActor () -> Void
    ) {
        localKeyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            let shouldSuppress = MainActor.assumeIsolated {
                guard let self else { return false }
                if self.isRecording {
                    return capture(event)
                }
                if self.matches(event, shortcut: shortcut()), canTrigger() {
                    startBreak()
                    return true
                }
                return false
            }
            return shouldSuppress ? nil : event
        }

        globalKeyMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            MainActor.assumeIsolated {
                guard let self else { return }
                if self.matches(event, shortcut: shortcut()), canTrigger() {
                    startBreak()
                }
            }
        }
    }

    func invalidate() {
        if let localKeyMonitor {
            NSEvent.removeMonitor(localKeyMonitor)
            self.localKeyMonitor = nil
        }
        if let globalKeyMonitor {
            NSEvent.removeMonitor(globalKeyMonitor)
            self.globalKeyMonitor = nil
        }
    }

    func captureShortcut(from event: NSEvent, settings: inout SettingsStore) -> Bool {
        let modifiers = shortcutModifiers(from: event.modifierFlags)
        let key = event.charactersIgnoringModifiers ?? ""
        guard !key.isEmpty, !modifiers.isEmpty else {
            return false
        }
        settings.startBreakShortcut = KeyboardShortcutSetting(
            key: key.lowercased(),
            modifiers: modifiers
        )
        isRecording = false
        return true
    }

    func displayText(for shortcut: KeyboardShortcutSetting, noShortcutText: String) -> String {
        guard shortcut.isConfigured else {
            return noShortcutText
        }

        var parts: [String] = []
        if shortcut.modifiers.contains(.control) { parts.append("⌃") }
        if shortcut.modifiers.contains(.option) { parts.append("⌥") }
        if shortcut.modifiers.contains(.shift) { parts.append("⇧") }
        if shortcut.modifiers.contains(.command) { parts.append("⌘") }
        parts.append(shortcut.key.uppercased())
        return parts.joined()
    }

    private func matches(_ event: NSEvent, shortcut: KeyboardShortcutSetting) -> Bool {
        guard shortcut.isConfigured else { return false }
        let key = (event.charactersIgnoringModifiers ?? "").lowercased()
        return key == shortcut.key && shortcutModifiers(from: event.modifierFlags) == shortcut.modifiers
    }

    private func shortcutModifiers(from flags: NSEvent.ModifierFlags) -> [KeyboardShortcutModifier] {
        var modifiers: [KeyboardShortcutModifier] = []
        if flags.contains(.control) { modifiers.append(.control) }
        if flags.contains(.option) { modifiers.append(.option) }
        if flags.contains(.shift) { modifiers.append(.shift) }
        if flags.contains(.command) { modifiers.append(.command) }
        return modifiers
    }
}
