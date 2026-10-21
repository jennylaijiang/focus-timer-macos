import Foundation
import SwiftData

@MainActor public final class SessionRepository {
    public let container: ModelContainer
    public let context: ModelContext
    public static let schema = Schema([FocusSession.self, CapturedThought.self])

    public init(container: ModelContainer) {
        self.container = container
        context = ModelContext(container)
        context.autosaveEnabled = false
    }

    public static func persistent() throws -> SessionRepository {
        let directory = try FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask,
                                                     appropriateFor: nil, create: true).appendingPathComponent("Focus", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let config = ModelConfiguration(schema: schema, url: directory.appendingPathComponent("Focus.store"), cloudKitDatabase: .none)
        return SessionRepository(container: try ModelContainer(for: schema, configurations: [config]))
    }

    public func allSessions() throws -> [FocusSession] {
        try context.fetch(FetchDescriptor<FocusSession>(sortBy: [SortDescriptor(\.startedAt, order: .reverse)]))
    }

    public func create(_ snapshot: TimerSnapshot) throws -> FocusSession {
        guard try allSessions().allSatisfy({ $0.status != .active }) else { throw TimerError.alreadyActive }
        let session = FocusSession(snapshot: snapshot)
        context.insert(session)
        do { try context.save() } catch { context.rollback(); throw error }
        return session
    }

    public func checkpoint(_ session: FocusSession, snapshot: TimerSnapshot, status: SessionStatus = .active) throws {
        session.actualActiveDurationSeconds = snapshot.active
        session.pausedDurationSeconds = snapshot.paused
        session.endedAt = snapshot.endedAt
        session.checkpointAt = snapshot.sampledAt
        session.timerStateRaw = snapshot.state.rawValue
        session.statusRaw = status.rawValue
        try context.save()
    }

    @discardableResult public func addThought(_ text: String, to session: FocusSession, at date: Date = Date()) throws -> CapturedThought? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let thought = CapturedThought(text: trimmed, createdAt: date, session: session)
        context.insert(thought)
        // Explicitly maintain the inverse collection for immediate UI updates.
        if !session.thoughts.contains(where: { $0.id == thought.id }) { session.thoughts.append(thought) }
        do { try context.save() } catch {
            session.thoughts.removeAll { $0.id == thought.id }
            context.delete(thought)
            throw error
        }
        return thought
    }

    public func save() throws { try context.save() }
}
