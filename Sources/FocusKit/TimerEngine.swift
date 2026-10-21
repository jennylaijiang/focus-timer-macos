import Foundation

public enum TimerState: String, Codable, Sendable {
    case idle, running, paused, overtime, finished
}

public struct ClockReading {
    public let date: Date
    public let instant: TimeInterval
    public init(date: Date, instant: TimeInterval) {
        self.date = date
        self.instant = instant
    }
}

/// Wall dates label records; a continuous monotonic clock measures intervals.
public struct TimerClock {
    private let read: () -> ClockReading
    public init(read: @escaping () -> ClockReading) { self.read = read }
    public func now() -> ClockReading { read() }
    public static func continuous() -> TimerClock {
        let origin = ContinuousClock.now
        return TimerClock {
            let parts = origin.duration(to: .now).components
            return ClockReading(date: Date(), instant: Double(parts.seconds) + Double(parts.attoseconds) / 1e18)
        }
    }
}

public struct TimerSnapshot {
    public let id: UUID
    public let taskName: String
    public let planned: TimeInterval
    public let active: TimeInterval
    public let paused: TimeInterval
    public let startedAt: Date
    public let endedAt: Date?
    public let sampledAt: Date
    public let state: TimerState
    public var overtime: TimeInterval { max(0, active - planned) }
    public var remaining: TimeInterval { max(0, planned - active) }
    public var remainingProportion: Double { min(1, max(0, remaining / planned)) }
    public var isOvertime: Bool { active >= planned }
}

public enum TimerError: LocalizedError {
    case emptyTask, invalidDuration, alreadyActive
    public var errorDescription: String? {
        switch self {
        case .emptyTask: return "Give this session a task name."
        case .invalidDuration: return "Enter a duration greater than zero and no longer than 24 hours."
        case .alreadyActive: return "Finish the current session before starting another."
        }
    }
}

/// No UI or persistence dependency. Refreshes only read the clock; they never drive time.
public struct TimerEngine {
    private let clock: TimerClock
    private var phase: TimerState = .idle
    private var id = UUID()
    private var taskName = ""
    private var planned: TimeInterval = 0
    private var accumulatedActive: TimeInterval = 0
    private var accumulatedPaused: TimeInterval = 0
    private var anchor: TimeInterval = 0
    private var startedAt = Date.distantPast
    private var endedAt: Date?
    private var finishedAt: Date?

    public init(clock: TimerClock = .continuous()) { self.clock = clock }
    public var isActive: Bool { phase == .running || phase == .paused }
    public var state: TimerState { snapshot()?.state ?? .idle }

    public mutating func start(taskName: String, plannedDuration: TimeInterval) throws {
        guard !isActive else { throw TimerError.alreadyActive }
        let name = taskName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { throw TimerError.emptyTask }
        guard plannedDuration.isFinite, plannedDuration > 0, plannedDuration <= 86_400 else { throw TimerError.invalidDuration }
        let now = clock.now()
        id = UUID()
        self.taskName = name
        planned = plannedDuration
        accumulatedActive = 0
        accumulatedPaused = 0
        anchor = now.instant
        startedAt = now.date
        endedAt = nil
        finishedAt = nil
        phase = .running
    }

    public func snapshot() -> TimerSnapshot? {
        guard phase != .idle else { return nil }
        let now = clock.now()
        let delta = max(0, now.instant - anchor)
        let active = accumulatedActive + (phase == .running ? delta : 0)
        let paused = accumulatedPaused + (phase == .paused ? delta : 0)
        let state: TimerState = phase == .running && active >= planned ? .overtime : phase
        return TimerSnapshot(id: id, taskName: taskName, planned: planned, active: active, paused: paused,
                             startedAt: startedAt, endedAt: endedAt, sampledAt: finishedAt ?? now.date, state: state)
    }

    public mutating func pause() {
        guard phase == .running else { return }
        let now = clock.now()
        accumulatedActive += max(0, now.instant - anchor)
        anchor = now.instant
        phase = .paused
    }

    public mutating func resume() {
        guard phase == .paused else { return }
        let now = clock.now()
        accumulatedPaused += max(0, now.instant - anchor)
        anchor = now.instant
        phase = .running
    }

    @discardableResult public mutating func finish() -> TimerSnapshot? {
        guard isActive else { return snapshot() }
        let now = clock.now()
        let delta = max(0, now.instant - anchor)
        if phase == .paused { accumulatedPaused += delta } else { accumulatedActive += delta }
        phase = .finished
        endedAt = now.date
        finishedAt = now.date
        return snapshot()
    }

    /// Recovery never infers work or pauses from time when the app wasn't observing.
    public mutating func recover(id: UUID, taskName: String, planned: TimeInterval,
                                 active: TimeInterval, paused: TimeInterval, startedAt: Date) throws {
        guard !isActive else { throw TimerError.alreadyActive }
        guard planned.isFinite, planned > 0, planned <= 86_400,
              active.isFinite, active >= 0, paused.isFinite, paused >= 0 else { throw TimerError.invalidDuration }
        self.id = id
        self.taskName = taskName
        self.planned = planned
        accumulatedActive = active
        accumulatedPaused = paused
        self.startedAt = startedAt
        endedAt = nil
        finishedAt = nil
        anchor = clock.now().instant
        phase = .paused
    }
}
