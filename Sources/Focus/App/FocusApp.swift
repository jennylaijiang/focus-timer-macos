import SwiftUI
import AppKit

@main struct FocusApp: App {
    @NSApplicationDelegateAdaptor(FocusAppDelegate.self) private var delegate
    @State private var controller = SessionController()

    var body: some Scene {
        Window("Focus", id: "focus") {
            MainView(controller: controller)
                .background(WindowAccess(controller: controller, delegate: delegate))
                .preferredColorScheme(nil)
        }
        .defaultSize(width: 720, height: 500)
        .windowResizability(.contentMinSize)
        .commands {
            CommandGroup(replacing: .newItem) { }
            CommandMenu("Session") {
                Button(controller.snapshot?.state == .paused ? "Resume" : "Pause") { controller.togglePause() }
                    .keyboardShortcut("p", modifiers: [.command, .shift])
                    .disabled(!controller.isActive)
                Button("Finish Session") { controller.finish() }
                    .keyboardShortcut("f", modifiers: [.command, .shift])
                    .disabled(!controller.isActive)
                Divider()
                Button("History") { controller.reloadHistory(); controller.showsHistory = true }
                    .keyboardShortcut("h", modifiers: [.command, .shift])
                Toggle("Always on Top", isOn: $controller.alwaysOnTop)
                Toggle("Thought Sidebar", isOn: $controller.sidebarVisible)
                    .keyboardShortcut("s", modifiers: [.command, .shift])
            }
        }
    }
}
