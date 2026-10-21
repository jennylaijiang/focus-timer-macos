import SwiftUI
#if SWIFT_PACKAGE
import FocusKit
#endif

struct HistoryView: View {
    @Bindable var controller: SessionController
    @State private var selectedID: UUID?
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Session history").font(.title3.weight(.semibold))
                Spacer()
                if controller.isActive { Text("Your timer is still \(controller.snapshot?.state == .paused ? "paused" : "running").").font(.caption).foregroundStyle(.secondary) }
                Button("Done") { dismiss() }.keyboardShortcut(.cancelAction)
            }.padding(20)
            Divider()
            if controller.history.isEmpty {
                ContentUnavailableView("A fresh start", systemImage: "clock.arrow.circlepath", description: Text("Finished sessions and their thoughts will appear here."))
            } else {
                HSplitView {
                    List(controller.history, selection: $selectedID) { session in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(session.taskName).font(.headline).lineLimit(2)
                            Text(session.startedAt.formatted(date: .abbreviated, time: .shortened)).font(.caption).foregroundStyle(.secondary)
                            Text("\(TimeText.duration(session.actualActiveDurationSeconds)) focused · \(session.status.rawValue.capitalized)")
                                .font(.caption).foregroundStyle(.secondary)
                            Text("Planned \(TimeText.duration(session.plannedDurationSeconds))\(session.overtimeDurationSeconds > 0 ? " · +" + TimeText.duration(session.overtimeDurationSeconds) : "")")
                                .font(.caption2).foregroundStyle(.secondary)
                            if let end = session.endedAt {
                                Text("\(session.startedAt.formatted(date: .omitted, time: .shortened)) – \(end.formatted(date: .omitted, time: .shortened))")
                                    .font(.caption2).foregroundStyle(.tertiary)
                            }
                        }.padding(.vertical, 6).tag(session.id)
                    }.frame(minWidth: 230, idealWidth: 260, maxWidth: 320)
                    if let session = controller.history.first(where: { $0.id == selectedID }) {
                        SessionDetailView(session: session)
                    } else {
                        ContentUnavailableView("Choose a session", systemImage: "text.bubble", description: Text("Revisit your focus time and saved thoughts."))
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
            }
        }.frame(minWidth: 680, idealWidth: 760, minHeight: 440, idealHeight: 520)
            .onAppear { selectedID = controller.history.first?.id }
    }
}

struct SessionDetailView: View {
    let session: FocusSession
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 7) {
                    Text(session.taskName).font(.title2.weight(.medium)).textSelection(.enabled)
                    Text(session.status.rawValue.capitalized).font(.caption).foregroundStyle(.secondary)
                    Text(session.startedAt.formatted(date: .abbreviated, time: .shortened))
                    if let endedAt = session.endedAt {
                        Text("Ended \(endedAt.formatted(date: .abbreviated, time: .shortened))")
                    }
                }.font(.callout)
                Grid(alignment: .leading, horizontalSpacing: 22, verticalSpacing: 8) {
                    detail("Planned", TimeText.duration(session.plannedDurationSeconds))
                    detail("Focused", TimeText.duration(session.actualActiveDurationSeconds))
                    detail("Paused", TimeText.duration(session.pausedDurationSeconds))
                    if session.overtimeDurationSeconds > 0 { detail("Overtime", "+" + TimeText.duration(session.overtimeDurationSeconds)) }
                    if session.unobservedDurationSeconds > 0 { detail("Unobserved · excluded", TimeText.duration(session.unobservedDurationSeconds)) }
                }.font(.callout)
                Divider()
                HStack {
                    Text("Thoughts").font(.headline)
                    Spacer()
                    if !session.thoughts.isEmpty { CopyButton(text: Clipboard.allThoughts(in: session), title: "Copy all") }
                }
                if session.thoughts.isEmpty { Text("No thoughts captured.").foregroundStyle(.secondary) }
                ForEach(session.sortedThoughts) { ThoughtRow(thought: $0) }
            }.padding(24).frame(maxWidth: .infinity, alignment: .leading)
        }.frame(minWidth: 330)
    }
    private func detail(_ label: String, _ value: String) -> some View {
        GridRow { Text(label).foregroundStyle(.secondary); Text(value).monospacedDigit() }
    }
}
