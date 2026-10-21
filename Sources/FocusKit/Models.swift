import Foundation
import SwiftData

public enum SessionStatus: String, Codable {
    case active, completed, interrupted
}

@Model public final class FocusSession {
    @Attribute(.unique) public var id: UUID
    public var taskName: String
    public var plannedDurationSeconds: TimeInterval
    public var actualActiveDurationSeconds: TimeInterval
    public var pausedDurationSeconds: TimeInterval
    public var unobservedDurationSeconds: TimeInterval
    public var startedAt: Date
    public var endedAt: Date?
    public var checkpointAt: Date
    public var statusRaw: String
    public var timerStateRaw: String
    @Relationship(deleteRule: .cascade, inverse: \CapturedThought.session)
    public var thoughts: [CapturedThought] = []

    public var status: SessionStatus { SessionStatus(rawValue: statusRaw) ?? .interrupted }
    public var overtimeDurationSeconds: TimeInterval { max(0, actualActiveDurationSeconds - plannedDurationSeconds) }
    public var sortedThoughts: [CapturedThought] { thoughts.sorted { $0.createdAt > $1.createdAt } }

    public init(snapshot: TimerSnapshot) {
        id = snapshot.id
        taskName = snapshot.taskName
        plannedDurationSeconds = snapshot.planned
        actualActiveDurationSeconds = snapshot.active
        pausedDurationSeconds = snapshot.paused
        unobservedDurationSeconds = 0
        startedAt = snapshot.startedAt
        endedAt = snapshot.endedAt
        checkpointAt = snapshot.sampledAt
        statusRaw = SessionStatus.active.rawValue
        timerStateRaw = snapshot.state.rawValue
    }
}

@Model public final class CapturedThought {
    @Attribute(.unique) public var id: UUID
    public var text: String
    public var createdAt: Date
    public var session: FocusSession?

    public init(text: String, createdAt: Date = Date(), session: FocusSession) {
        id = UUID()
        self.text = text
        self.createdAt = createdAt
        self.session = session
    }
}
