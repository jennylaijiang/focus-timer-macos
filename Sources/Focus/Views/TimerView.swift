import SwiftUI
#if SWIFT_PACKAGE
import FocusKit
#endif

struct TimerView: View {
    @Bindable var controller: SessionController
    @FocusState private var nameFocused: Bool
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 20) {
                    if let snapshot = controller.snapshot {
                        if snapshot.state == .finished { summary(snapshot) }
                        else { activeTimer(snapshot, availableHeight: geometry.size.height) }
                    } else { setup }
                }
                .padding(28)
                .frame(maxWidth: .infinity)
                .frame(minHeight: geometry.size.height)
            }
        }
    }

    private var setup: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                Text("One thing at a time.").font(.system(size: 27, weight: .semibold, design: .rounded))
                Text("Give this moment a little focus.").foregroundStyle(.secondary)
            }.padding(.bottom, 12)
            VStack(alignment: .leading, spacing: 8) {
                Text("WHAT ARE YOU WORKING ON?").font(.caption2.weight(.semibold)).foregroundStyle(.secondary)
                TextField("e.g. Read the next chapter", text: $controller.taskName)
                    .textFieldStyle(.roundedBorder).controlSize(.large).focused($nameFocused)
                    .onSubmit { controller.start() }
                    .accessibilityLabel("Task name")
            }
            HStack {
                Text("Planned time").foregroundStyle(.secondary)
                Spacer()
                TextField("25", text: $controller.durationMinutes)
                    .textFieldStyle(.roundedBorder).frame(width: 70).multilineTextAlignment(.trailing)
                    .onSubmit { controller.start() }.accessibilityLabel("Duration in minutes")
                Text("min").foregroundStyle(.secondary)
            }
            Button { controller.start() } label: {
                Label("Start focus", systemImage: "play.fill").frame(maxWidth: .infinity).padding(.vertical, 5)
            }
            .buttonStyle(.borderedProminent).controlSize(.large).disabled(!controller.canStart)
            Text("When time is up, keep going. Finish when you’re ready.")
                .font(.caption).foregroundStyle(.tertiary).fixedSize(horizontal: false, vertical: true)
        }.frame(maxWidth: 400)
            .onAppear { nameFocused = true }
    }

    private func activeTimer(_ snapshot: TimerSnapshot, availableHeight: CGFloat) -> some View {
        VStack(spacing: 20) {
            VStack(spacing: 6) {
                Text(snapshot.taskName).font(.title2.weight(.medium)).multilineTextAlignment(.center).lineLimit(3)
                    .textSelection(.enabled)
                Text(snapshot.state == .paused ? "TAKE A BREATH" : "STAY WITH THIS")
                    .font(.caption2.weight(.semibold)).tracking(2).foregroundStyle(.secondary)
            }
            TimerRing(snapshot: snapshot)
                .frame(width: min(270, max(190, availableHeight - 220)), height: min(270, max(190, availableHeight - 220)))
            HStack(spacing: 14) {
                Button { controller.togglePause() } label: {
                    Label(snapshot.state == .paused ? "Resume" : "Pause", systemImage: snapshot.state == .paused ? "play.fill" : "pause.fill")
                        .frame(minWidth: 78)
                }.buttonStyle(.borderedProminent)
                Button("Finish") { controller.finish() }.buttonStyle(.bordered)
            }.controlSize(.large)
            Text(snapshot.isOvertime ? "A little more time, at your own pace." : "A thought can wait. Capture it and return.")
                .font(.caption).foregroundStyle(.secondary).multilineTextAlignment(.center)
            if !controller.sidebarVisible {
                HStack {
                    TextField("Park a thought…", text: $controller.thoughtText).onSubmit { controller.captureThought() }
                    Button { controller.captureThought() } label: { Image(systemName: "return") }.help("Save thought")
                }.textFieldStyle(.roundedBorder)
            }
        }
    }

    private func summary(_ snapshot: TimerSnapshot) -> some View {
        VStack(spacing: 22) {
            Image(systemName: "checkmark.circle").font(.system(size: 42, weight: .light)).foregroundStyle(FocusStyle.accent)
            VStack(spacing: 8) {
                Text(controller.current?.status == .interrupted ? "Session saved." : "A little further along.")
                    .font(.title2.weight(.medium))
                Text(snapshot.taskName).foregroundStyle(.secondary).multilineTextAlignment(.center)
            }
            VStack(spacing: 12) {
                metric("Focused", TimeText.duration(snapshot.active))
                metric("Planned", TimeText.duration(snapshot.planned))
                if snapshot.overtime > 0 { metric("Overtime", "+" + TimeText.duration(snapshot.overtime)) }
                metric("Paused", TimeText.duration(snapshot.paused))
            }.padding(18).background(.quaternary.opacity(0.4), in: RoundedRectangle(cornerRadius: 14))
            Button("Start another task") { controller.newSession() }
                .buttonStyle(.borderedProminent).controlSize(.large).disabled(!controller.canStart)
        }.frame(maxWidth: 340)
    }

    private func metric(_ name: String, _ value: String) -> some View {
        HStack { Text(name).foregroundStyle(.secondary); Spacer(); Text(value).monospacedDigit() }
    }
}
