import SwiftUI
#if SWIFT_PACKAGE
import FocusKit
#endif

struct ThoughtSidebar: View {
    @Bindable var controller: SessionController
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Thoughts").font(.headline)
                Spacer()
                if let session = controller.current, !session.thoughts.isEmpty {
                    CopyButton(text: Clipboard.allThoughts(in: session), title: "Copy all")
                }
            }
            Text("Park it here. Come back later.").font(.caption).foregroundStyle(.secondary)
            if controller.isActive {
                HStack(alignment: .center, spacing: 6) {
                    TextField("A thought for later…", text: $controller.thoughtText)
                        .textFieldStyle(.plain)
                        .onSubmit { controller.captureThought() }
                        .accessibilityLabel("Capture a thought. Press Return to save.")
                    Button { controller.captureThought() } label: { Image(systemName: "return") }
                        .buttonStyle(.plain).foregroundStyle(.secondary).help("Save thought (Return)")
                }.padding(12).background(Color(nsColor: .textBackgroundColor), in: RoundedRectangle(cornerRadius: 10))
            }
            if let session = controller.current, !session.thoughts.isEmpty {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 12) {
                        ForEach(session.sortedThoughts) { thought in ThoughtRow(thought: thought) }
                    }
                }
            } else {
                VStack(spacing: 10) {
                    Image(systemName: "tray").font(.system(size: 28, weight: .ultraLight))
                    Text(controller.isActive ? "Nothing to hold onto.\nStay with your task." : "Your ideas will have\na place to wait.")
                        .font(.callout).multilineTextAlignment(.center)
                }.foregroundStyle(.tertiary).frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            Spacer(minLength: 0)
            if let session = controller.current {
                Text("\(session.thoughts.count) captured · saved with this session")
                    .font(.caption2).foregroundStyle(.tertiary)
            }
        }.padding(20).background(.primary.opacity(0.025))
    }
}

struct ThoughtRow: View {
    let thought: CapturedThought
    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            Text(thought.text).font(.callout).textSelection(.enabled).fixedSize(horizontal: false, vertical: true)
            HStack {
                Text(thought.createdAt, style: .time).font(.caption2).foregroundStyle(.tertiary)
                Spacer()
                CopyButton(text: thought.text)
            }
        }.padding(12).frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 10))
    }
}
