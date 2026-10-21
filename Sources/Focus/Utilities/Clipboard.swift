import AppKit
#if SWIFT_PACKAGE
import FocusKit
#endif

enum Clipboard {
    @MainActor @discardableResult static func copy(_ text: String) -> Bool {
        NSPasteboard.general.clearContents()
        return NSPasteboard.general.setString(text, forType: .string)
    }

    @MainActor static func allThoughts(in session: FocusSession) -> String {
        let header = "Thoughts — \(session.taskName)\n\(session.startedAt.formatted(date: .abbreviated, time: .shortened))"
        let thoughts = session.sortedThoughts.map { thought in
            "[\(thought.createdAt.formatted(date: .omitted, time: .shortened))] \(thought.text)"
        }.joined(separator: "\n\n")
        return "\(header)\n\n\(thoughts)"
    }
}
