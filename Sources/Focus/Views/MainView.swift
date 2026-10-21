import SwiftUI
#if SWIFT_PACKAGE
import FocusKit
#endif

struct MainView: View {
    @Bindable var controller: SessionController
    var body: some View {
        VStack(spacing: 0) {
            if let message = controller.errorMessage {
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "exclamationmark.triangle").foregroundStyle(FocusStyle.overtime)
                    Text(message).font(.callout).textSelection(.enabled)
                    Spacer(minLength: 0)
                    if controller.hasUnsavedChanges || controller.repository == nil {
                        Button("Retry") { controller.retrySave() }
                    } else {
                        Button { controller.errorMessage = nil } label: { Image(systemName: "xmark") }
                            .buttonStyle(.plain).accessibilityLabel("Dismiss error")
                    }
                }.padding(12).background(FocusStyle.overtime.opacity(0.1))
            }
            if let notice = controller.notice {
                VStack(alignment: .leading, spacing: 6) {
                    Text(notice).font(.caption).foregroundStyle(.secondary)
                    if controller.recovered {
                        Button("End as interrupted") { controller.finish(interrupted: true) }.font(.caption)
                    }
                }.frame(maxWidth: .infinity, alignment: .leading).padding(12)
                    .background(FocusStyle.accent.opacity(0.08))
            }
            HStack(spacing: 0) {
                TimerView(controller: controller)
                    .frame(minWidth: 350, maxWidth: .infinity, maxHeight: .infinity)
                if controller.sidebarVisible {
                    Divider()
                    ThoughtSidebar(controller: controller)
                        .frame(width: 260)
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                }
            }
        }
        .frame(minWidth: controller.sidebarVisible ? 650 : 380, minHeight: 460)
        .background(Color(nsColor: .windowBackgroundColor))
        .tint(FocusStyle.accent)
        .toolbar {
            ToolbarItemGroup(placement: .automatic) {
                Button { controller.reloadHistory(); controller.showsHistory = true } label: {
                    Label("History", systemImage: "clock.arrow.circlepath")
                }.help("Session history (⇧⌘H)")
                Toggle(isOn: $controller.alwaysOnTop) { Label("Always on Top", systemImage: "pin") }
                    .toggleStyle(.button).help("Keep Focus above other windows")
                Toggle(isOn: $controller.sidebarVisible) { Label("Thought Sidebar", systemImage: "sidebar.right") }
                    .toggleStyle(.button).help("Show or hide thoughts (⇧⌘S)")
            }
        }
        .sheet(isPresented: $controller.showsHistory) { HistoryView(controller: controller) }
    }
}
