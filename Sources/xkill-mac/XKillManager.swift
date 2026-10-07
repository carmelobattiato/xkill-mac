import AppKit
import CoreGraphics

final class XKillManager {

    weak var delegate: AppDelegate?

    private(set) var isInKillMode = false
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var escMonitor: Any?
    private var cursorPanel: NSPanel?
    private var mouseMoveMonitor: Any?

    // MARK: - Kill Mode

    func enterKillMode() {
        guard !isInKillMode else {
            exitKillMode()
            return
        }

        guard AXIsProcessTrusted() else {
            showAccessibilityAlert()
            return
        }

        isInKillMode = true
        showCursorOverlay()
        installEventTap()
        installEscMonitor()
        delegate?.killManagerDidEnterKillMode()
    }

    func exitKillMode() {
        guard isInKillMode else { return }
        isInKillMode = false
        hideCursorOverlay()
        removeEventTap()
        removeEscMonitor()
        delegate?.killManagerDidExitKillMode()
    }

    // MARK: - Cursor Overlay

    private func showCursorOverlay() {
        let size: CGFloat = 56
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: size, height: size),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.level = .screenSaver
        panel.ignoresMouseEvents = true
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.contentView = CursorOverlayView(frame: NSRect(x: 0, y: 0, width: size, height: size))

        cursorPanel = panel
        moveCursorPanel()
        panel.orderFrontRegardless()

        CGDisplayHideCursor(CGMainDisplayID())

        mouseMoveMonitor = NSEvent.addGlobalMonitorForEvents(
            matching: [.mouseMoved, .leftMouseDragged, .rightMouseDragged]
        ) { [weak self] _ in
            self?.moveCursorPanel()
        }
    }

    private func moveCursorPanel() {
        guard let panel = cursorPanel else { return }
        let loc = NSEvent.mouseLocation
        let size = panel.frame.size
        panel.setFrameOrigin(NSPoint(x: loc.x - size.width / 2, y: loc.y - size.height / 2))
    }

    private func hideCursorOverlay() {
        CGDisplayShowCursor(CGMainDisplayID())
        cursorPanel?.orderOut(nil)
        cursorPanel = nil
        if let m = mouseMoveMonitor {
            NSEvent.removeMonitor(m)
            mouseMoveMonitor = nil
        }
    }

    // MARK: - CGEvent Tap

    private func installEventTap() {
        let mask: CGEventMask = 1 << CGEventType.leftMouseDown.rawValue
        let selfPtr = Unmanaged.passRetained(self).toOpaque()

        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: mask,
            callback: xkillEventTapCallback,
            userInfo: selfPtr
        ) else {
            Unmanaged<XKillManager>.fromOpaque(selfPtr).release()
            isInKillMode = false
            hideCursorOverlay()
            showAccessibilityAlert()
            return
        }

        eventTap = tap
        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        runLoopSource = source
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
    }

    private func removeEventTap() {
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
            eventTap = nil
        }
        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
            runLoopSource = nil
        }
    }

    // MARK: - ESC Monitor

    private func installEscMonitor() {
        escMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self, event.keyCode == 53 else { return }
            DispatchQueue.main.async { self.exitKillMode() }
        }
    }

    private func removeEscMonitor() {
        if let monitor = escMonitor {
            NSEvent.removeMonitor(monitor)
            escMonitor = nil
        }
    }

    // MARK: - Click Handler

    func handleClick(at cgPoint: CGPoint, selfPtr: UnsafeMutableRawPointer) {
        guard isInKillMode else {
            Unmanaged<XKillManager>.fromOpaque(selfPtr).release()
            return
        }

        exitKillMode()
        Unmanaged<XKillManager>.fromOpaque(selfPtr).release()

        let ownPID = ProcessInfo.processInfo.processIdentifier
        guard let app = findApp(at: cgPoint), app.processIdentifier != ownPID else { return }

        app.forceTerminate()
    }

    func reenableTap() {
        if let tap = eventTap { CGEvent.tapEnable(tap: tap, enable: true) }
    }

    // MARK: - Window Hit-Test

    private func findApp(at cgPoint: CGPoint) -> NSRunningApplication? {
        guard let list = CGWindowListCopyWindowInfo(
            [.optionOnScreenOnly, .excludeDesktopElements],
            kCGNullWindowID
        ) as? [[CFString: Any]] else { return nil }

        for window in list {
            guard let layer = window[kCGWindowLayer] as? Int, layer == 0 else { continue }
            guard let boundsDict = window[kCGWindowBounds] else { continue }
            var rect = CGRect.zero
            guard CGRectMakeWithDictionaryRepresentation(boundsDict as! CFDictionary, &rect) else { continue }
            guard rect.width > 10, rect.height > 10 else { continue }
            if rect.contains(cgPoint) {
                guard let pid = window[kCGWindowOwnerPID] as? pid_t else { continue }
                return NSWorkspace.shared.runningApplications.first { $0.processIdentifier == pid }
            }
        }
        return nil
    }

    // MARK: - Alert

    private func showAccessibilityAlert() {
        let alert = NSAlert()
        alert.messageText = "Accessibility Permission Required"
        alert.informativeText = "xkill-mac needs Accessibility access to intercept mouse events globally. Grant it in System Settings > Privacy & Security > Accessibility, then relaunch."
        alert.addButton(withTitle: "Open System Settings")
        alert.addButton(withTitle: "Cancel")
        NSApp.activate(ignoringOtherApps: true)
        if alert.runModal() == .alertFirstButtonReturn {
            NSWorkspace.shared.open(
                URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
            )
        }
    }
}

// MARK: - Cursor Overlay View

private final class CursorOverlayView: NSView {

    private let skullImage: NSImage? = {
        guard let url = Bundle.main.url(forResource: "skull_active", withExtension: "png") else { return nil }
        return NSImage(contentsOf: url)
    }()

    override func draw(_ dirtyRect: NSRect) {
        if let img = skullImage {
            img.draw(in: bounds, from: .zero, operation: .sourceOver, fraction: 1)
        } else {
            // Fallback: draw a red X if image not found
            let path = NSBezierPath()
            path.lineWidth = 4
            path.lineCapStyle = .round
            let m: CGFloat = 6
            path.move(to: NSPoint(x: m, y: bounds.height - m))
            path.line(to: NSPoint(x: bounds.width - m, y: m))
            path.move(to: NSPoint(x: bounds.width - m, y: bounds.height - m))
            path.line(to: NSPoint(x: m, y: m))
            NSColor.systemRed.setStroke()
            path.stroke()
        }
    }
}

// MARK: - C Event Tap Callback

private let xkillEventTapCallback: CGEventTapCallBack = { proxy, type, event, refconPtr in
    guard let refconPtr else { return Unmanaged.passRetained(event) }

    if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
        let manager = Unmanaged<XKillManager>.fromOpaque(refconPtr).takeUnretainedValue()
        DispatchQueue.main.async { manager.reenableTap() }
        return Unmanaged.passRetained(event)
    }

    guard type == .leftMouseDown else { return Unmanaged.passRetained(event) }

    let location = event.location

    DispatchQueue.main.async {
        let manager = Unmanaged<XKillManager>.fromOpaque(refconPtr).takeUnretainedValue()
        manager.handleClick(at: location, selfPtr: refconPtr)
    }

    return nil
}
