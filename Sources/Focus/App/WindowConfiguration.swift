import AppKit
import SwiftUI

@MainActor final class FocusAppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    weak var window: NSWindow?
    var controller: SessionController?
    private var sleepObserver: NSObjectProtocol?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        sleepObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.willSleepNotification, object: nil, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.controller?.pauseForSleep() }
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { false }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        window?.makeKeyAndOrderFront(nil)
        return true
    }

    func windowShouldClose(_ sender: NSWindow) -> Bool {
        if controller?.isActive == true {
            let alert = NSAlert()
            alert.messageText = "Keep this session running?"
            alert.informativeText = "Closing the window keeps Focus running, including overtime. Click Focus in the Dock to return. You can pause or finish before closing."
            alert.addButton(withTitle: "Keep Running")
            alert.addButton(withTitle: "Cancel")
            guard alert.runModal() == .alertFirstButtonReturn else { return false }
        }
        sender.orderOut(nil)
        return false // Keep one window, one controller, and one active session.
    }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        if controller?.isActive == true {
            let alert = NSAlert()
            alert.messageText = "Save this session and quit?"
            alert.informativeText = "Your session and thoughts will be saved. Next time Focus opens, the session will be paused. Time while the app is closed won’t count as focus time."
            alert.addButton(withTitle: "Save and Quit")
            alert.addButton(withTitle: "Cancel")
            guard alert.runModal() == .alertFirstButtonReturn else { return .terminateCancel }
        }
        if controller?.prepareToQuit() == false {
            window?.makeKeyAndOrderFront(nil)
            let alert = NSAlert()
            alert.messageText = "Focus couldn’t save your latest changes."
            alert.informativeText = "The app will stay open so you can retry saving."
            alert.runModal()
            return .terminateCancel
        }
        return .terminateNow
    }
}

struct WindowAccess: NSViewRepresentable {
    let controller: SessionController
    let delegate: FocusAppDelegate
    func makeNSView(context: Context) -> NSView { NSView() }
    func updateNSView(_ nsView: NSView, context: Context) {
        let floating = controller.alwaysOnTop
        DispatchQueue.main.async {
            guard let window = nsView.window else { return }
            delegate.window = window
            delegate.controller = controller
            window.delegate = delegate
            window.level = floating ? .floating : .normal
            window.isMovableByWindowBackground = true
            window.titlebarAppearsTransparent = true
            window.isReleasedWhenClosed = false
        }
    }
}
