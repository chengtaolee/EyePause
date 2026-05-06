import AppKit
import SwiftUI

@MainActor
final class StatusItemCoordinator: NSObject {
    private var statusItem: NSStatusItem?
    private var popover: NSPopover?

    func install(model: AppModel) {
        guard statusItem == nil else {
            updateIcon(systemImage: model.menuBarSystemImage)
            return
        }

        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem = item
        if let button = item.button {
            button.target = self
            button.action = #selector(togglePopover)
            button.toolTip = "EyePause"
        }

        let popover = NSPopover()
        popover.behavior = .transient
        popover.contentSize = NSSize(width: 280, height: 520)
        popover.contentViewController = NSHostingController(
            rootView: MenuBarView(model: model)
                .frame(width: 280)
        )
        self.popover = popover
        updateIcon(systemImage: model.menuBarSystemImage)
    }

    func updateIcon(systemImage: String) {
        guard let button = statusItem?.button else { return }
        if let image = NSImage(systemSymbolName: systemImage, accessibilityDescription: "EyePause") {
            image.isTemplate = true
            button.image = image
            button.title = ""
        } else {
            button.image = nil
            button.title = "EyePause"
        }
    }

    @objc private func togglePopover() {
        guard let button = statusItem?.button, let popover else { return }
        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            NSApp.activate(ignoringOtherApps: true)
        }
    }
}
