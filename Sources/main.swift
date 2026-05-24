import SwiftUI
import AppKit
import Darwin

if HermesManagerSelfTests.runRequestedIfNeeded() {
    exit(0)
}

final class MainWindowController: NSWindowController {
    init(manager: ServiceManager) {
        let contentView = ContentView(manager: manager)
            .frame(minWidth: 980, minHeight: 620)
            .background(SetupPalette.abyss)
        let hostingController = NSHostingController(rootView: contentView)
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1180, height: 760),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Hermes Manager"
        window.titlebarAppearsTransparent = true
        window.backgroundColor = NSColor(
            red: 0.008,
            green: 0.014,
            blue: 0.016,
            alpha: 1.0
        )
        window.contentViewController = hostingController
        window.minSize = NSSize(width: 980, height: 620)
        window.collectionBehavior = [.moveToActiveSpace]
        window.setFrame(NSRect(x: 0, y: 0, width: 1180, height: 760), display: false)
        window.center()
        window.isReleasedWhenClosed = false
        window.isRestorable = false
        super.init(window: window)
        shouldCascadeWindows = false
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let manager = ServiceManager()
    private var mainWindowController: MainWindowController?

    func applicationWillFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        showMainWindow()
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        showMainWindow()
        return true
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        manager.stopAllForAppQuit()
        return .terminateNow
    }

    private func showMainWindow() {
        if mainWindowController == nil {
            mainWindowController = MainWindowController(manager: manager)
        }
        mainWindowController?.showWindow(nil)
        mainWindowController?.window?.deminiaturize(nil)
        mainWindowController?.window?.setFrame(NSRect(x: 0, y: 0, width: 1180, height: 760), display: true)
        mainWindowController?.window?.center()
        mainWindowController?.window?.makeMain()
        mainWindowController?.window?.makeKeyAndOrderFront(nil)
        mainWindowController?.window?.orderFrontRegardless()
        NSRunningApplication.current.activate(options: [.activateAllWindows])
        NSApp.activate(ignoringOtherApps: true)
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.regular)
app.run()
