import SwiftUI

enum FocusStyle {
    static let accent = Color(red: 0.24, green: 0.53, blue: 0.49)
    static let overtime = Color(red: 0.73, green: 0.35, blue: 0.36)
}

struct CopyButton: View {
    let text: String
    var title = "Copy"
    @State private var copied = false
    @State private var failed = false
    var body: some View {
        Button {
            copied = Clipboard.copy(text)
            failed = !copied
        } label: {
            Label(copied ? "Copied" : (failed ? "Retry copy" : title), systemImage: copied ? "checkmark" : "doc.on.doc")
                .font(.caption)
        }
        .buttonStyle(.borderless)
        .help(title)
        .task(id: copied) {
            guard copied else { return }
            try? await Task.sleep(for: .seconds(1.8))
            if !Task.isCancelled { copied = false }
        }
    }
}
