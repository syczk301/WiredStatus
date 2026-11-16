import AppKit
import ServiceManagement
import SwiftUI

func portIcon(_ state: WiredState) -> NSImage {
    let image = NSImage(size: NSSize(width: 22, height: 18), flipped: false) { _ in
        NSColor.labelColor.setStroke()
        let port = NSBezierPath()
        port.move(to: NSPoint(x: 3, y: 15)); port.line(to: NSPoint(x: 17, y: 15))
        port.line(to: NSPoint(x: 17, y: 5)); port.line(to: NSPoint(x: 14, y: 5))
        port.line(to: NSPoint(x: 14, y: 2)); port.line(to: NSPoint(x: 6, y: 2))
        port.line(to: NSPoint(x: 6, y: 5)); port.line(to: NSPoint(x: 3, y: 5)); port.close()
        port.lineWidth = 1.5; port.lineJoinStyle = .round; port.stroke()
        for x in stride(from: 6.0, through: 14.0, by: 2.0) {
            let pin = NSBezierPath(); pin.move(to: NSPoint(x: x, y: 11))
            pin.line(to: NSPoint(x: x, y: 14)); pin.lineWidth = 1; pin.stroke()
        }
        if state == .connected {
            NSColor.labelColor.setFill()
            NSBezierPath(ovalIn: NSRect(x: 8, y: 5, width: 4, height: 4)).fill()
        } else if state == .waiting {
            let mark = NSBezierPath(); mark.move(to: NSPoint(x: 20, y: 7)); mark.line(to: NSPoint(x: 20, y: 14))
            mark.lineWidth = 2; mark.stroke()
            NSColor.labelColor.setFill(); NSBezierPath(ovalIn: NSRect(x: 19, y: 3, width: 2, height: 2)).fill()
        } else {
            let slash = NSBezierPath(); slash.move(to: NSPoint(x: 2, y: 1)); slash.line(to: NSPoint(x: 19, y: 17))
            slash.lineWidth = 1.8; slash.stroke()
        }
        return true
    }
    image.isTemplate = true
    return image
}

final class AppDelegate: NSObject, NSApplicationDelegate, NSPopoverDelegate {
    private let monitor = EthernetMonitor()
    private let model = PanelModel()
    private var item: NSStatusItem!
    private let popover = NSPopover()

    func applicationDidFinishLaunching(_ notification: Notification) {
        AppUpdater.shared.start()
        if let id = Bundle.main.bundleIdentifier,
           NSRunningApplication.runningApplications(withBundleIdentifier: id).count > 1 {
            NSApp.terminate(nil); return
        }
        NSApp.setActivationPolicy(.accessory)
        item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        item.button?.target = self
        item.button?.action = #selector(togglePanel)
        popover.behavior = .transient
        popover.delegate = self
        monitor.onChange = { [weak self] in self?.updateState() }
        monitor.start(); updateState()
    }
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        showPanel(); return true
    }
    func applicationWillTerminate(_ notification: Notification) { monitor.stop() }
    private func updateState() {
        item.button?.image = portIcon(monitor.state)
        item.button?.toolTip = "有线状态 · \(monitor.state.title)"
        item.button?.setAccessibilityLabel("有线状态 · \(monitor.state.title)")
        model.state = monitor.state
        model.interfaces = monitor.connectedInterfaces
    }
    @objc private func togglePanel() {
        if popover.isShown { popover.performClose(nil) } else { showPanel() }
    }
    private func showPanel() {
        guard let button = item.button else { return }
        monitor.refresh()
        if popover.isShown { return }
        let availableHeight = (button.window?.screen ?? NSScreen.main)?.visibleFrame.height ?? 600
        let desiredHeight: CGFloat = monitor.connectedInterfaces.isEmpty ? 280 : monitor.connectedInterfaces.count == 1 ? 340 : 420
        let size = NSSize(width: 320, height: min(desiredHeight, max(280, availableHeight - 48)))
        let hosting = NSHostingController(rootView: StatusPanel(
            model: model, panelHeight: size.height,
            networkSettings: { [weak self] in self?.openNetworkSettings() },
            loginSettings: { [weak self] in self?.openLoginSettings() },
            quit: { NSApp.terminate(nil) }))
        hosting.sizingOptions = []
        hosting.preferredContentSize = size
        hosting.view.setFrameSize(size)
        popover.contentViewController = hosting
        popover.contentSize = size
        NSApp.activate(ignoringOtherApps: true)
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        popover.contentViewController?.view.window?.makeKey()
    }
    private func openNetworkSettings() {
        popover.performClose(nil)
        NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.Network-Settings.extension")!)
    }
    private func openLoginSettings() {
        popover.performClose(nil)
        SMAppService.openSystemSettingsLoginItems()
    }
}

if CommandLine.arguments.contains("--diagnose") {
    let monitor = EthernetMonitor()
    print("STATE: \(monitor.state.rawValue)")
    for i in monitor.connectedInterfaces { print("\(i.name)\t\(i.displayName)\t\(i.status)\t\(i.addresses.joined(separator: ", "))") }
} else {
    let app = NSApplication.shared
    let delegate = AppDelegate(); app.delegate = delegate; app.run()
}
