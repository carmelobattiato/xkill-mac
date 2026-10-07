import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {

    private var statusItem: NSStatusItem!
    private var killManager: XKillManager!
    private var hintPanel: NSPanel?

    func applicationDidFinishLaunching(_ notification: Notification) {
        killManager = XKillManager()
        killManager.delegate = self

        statusItem = NSStatusBar.system.statusItem(withLength: 32)

        guard let button = statusItem.button else { return }
        button.image = skullImage(active: false)
        button.imageScaling = .scaleProportionallyDown
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        button.action = #selector(statusBarButtonClicked)
        button.target = self

        checkAccessibilityPermission()
    }

    @objc private func statusBarButtonClicked() {
        guard let event = NSApp.currentEvent else { return }

        if event.type == .rightMouseUp {
            showContextMenu()
        } else {
            killManager.enterKillMode()
        }
    }

    private func showContextMenu() {
        let menu = NSMenu()
        if killManager.isInKillMode {
            let info = NSMenuItem(title: "Press ESC to deactivate", action: nil, keyEquivalent: "")
            info.isEnabled = false
            menu.addItem(info)
            menu.addItem(.separator())
        }
        menu.addItem(NSMenuItem(title: "Quit xkill-mac",
                                action: #selector(NSApplication.terminate(_:)),
                                keyEquivalent: "q"))
        statusItem.menu = menu
        statusItem.button?.performClick(nil)
        statusItem.menu = nil
    }

    func killManagerDidEnterKillMode() {
        statusItem.button?.image = skullImage(active: true)
        showEscHint()
    }

    func killManagerDidExitKillMode() {
        statusItem.button?.image = skullImage(active: false)
        hideEscHint()
    }

    // MARK: - ESC hint panel

    private func showEscHint() {
        guard let button = statusItem.button,
              let window = button.window else { return }

        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 220, height: 28),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.level = .floating
        panel.ignoresMouseEvents = true
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        let container = NSView(frame: NSRect(x: 0, y: 0, width: 220, height: 28))
        container.wantsLayer = true
        container.layer?.backgroundColor = NSColor.black.withAlphaComponent(0.75).cgColor
        container.layer?.cornerRadius = 6

        let label = NSTextField(labelWithString: "Press ESC to deactivate")
        label.font = .systemFont(ofSize: 12)
        label.textColor = .white
        label.frame = NSRect(x: 10, y: 6, width: 200, height: 16)
        container.addSubview(label)
        panel.contentView = container

        // Position below the status bar button
        let btnRect = window.convertToScreen(button.frame)
        let x = btnRect.midX - 110
        let y = btnRect.minY - 34
        panel.setFrameOrigin(NSPoint(x: x, y: y))
        panel.orderFrontRegardless()
        hintPanel = panel
    }

    private func hideEscHint() {
        hintPanel?.orderOut(nil)
        hintPanel = nil
    }

    // MARK: - Icon

    private func skullImage(active: Bool) -> NSImage? {
        let name = active ? "skull_active" : "skull_normal"
        guard let url = Bundle.main.url(forResource: name, withExtension: "png"),
              let img = NSImage(contentsOf: url) else { return nil }
        img.size = NSSize(width: 27, height: 27)
        img.isTemplate = false
        return img
    }

    private func checkAccessibilityPermission() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        AXIsProcessTrustedWithOptions(options as CFDictionary)
    }
}
