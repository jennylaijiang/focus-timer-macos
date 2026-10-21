import SwiftUI
#if SWIFT_PACKAGE
import FocusKit
#endif

struct TimerRing: View {
    let snapshot: TimerSnapshot
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    private var color: Color { snapshot.isOvertime ? FocusStyle.overtime : FocusStyle.accent }
    private var displayedTime: String {
        snapshot.isOvertime ? "+" + TimeText.clock(snapshot.overtime) : TimeText.clock(snapshot.remaining, roundingUp: true)
    }
    var body: some View {
        ZStack {
            Circle().stroke(color.opacity(0.1), lineWidth: 8)
            Circle()
                .trim(from: 0, to: snapshot.isOvertime ? 1 : snapshot.remainingProportion)
                .stroke(color, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .rotationEffect(.degrees(-90))
            VStack(spacing: 8) {
                Text(displayedTime)
                    .font(.system(size: 46, weight: .light, design: .rounded)).monospacedDigit()
                    .minimumScaleFactor(0.6).lineLimit(1).foregroundStyle(color)
                Text(snapshot.state == .paused ? (snapshot.isOvertime ? "Overtime · paused" : "Paused") : (snapshot.isOvertime ? "Overtime" : "Remaining"))
                    .font(.callout).foregroundStyle(.secondary)
            }.padding(20)
        }
        .padding(6)
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.45), value: snapshot.isOvertime)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(snapshot.state == .paused ? "Paused. " : "")\(snapshot.isOvertime ? "Overtime" : "Remaining") \(displayedTime)")
    }
}
