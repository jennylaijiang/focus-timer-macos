import Testing
import Foundation
import SwiftData
#if SWIFT_PACKAGE
@testable import FocusKit
#else
@testable import Focus
#endif

struct PersistenceTests {
    @Test @MainActor func testSessionsAndThoughtsSurviveReopeningStore() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("Test.store")
        let sessionID = try writeSession(to: url)
        // A fresh container and context read the persisted store, not cached model objects.
        let config = ModelConfiguration(schema: SessionRepository.schema, url: url, cloudKitDatabase: .none)
        let repository = SessionRepository(container: try ModelContainer(for: SessionRepository.schema, configurations: [config]))
        let sessions = try repository.allSessions()
        #expect(sessions.count == 1)
        let session = try #require(sessions.first)
        #expect(session.id == sessionID)
        #expect(session.status == .completed)
        #expect(session.actualActiveDurationSeconds == 1380)
        #expect(session.pausedDurationSeconds == 60)
        #expect(session.overtimeDurationSeconds == 480)
        #expect(session.endedAt != nil)
        #expect(session.sortedThoughts.map(\.text) == ["Second idea", "First idea"])
        #expect(session.thoughts.first?.session?.id == sessionID)
    }

    @MainActor private func writeSession(to url: URL) throws -> UUID {
        let config = ModelConfiguration(schema: SessionRepository.schema, url: url, cloudKitDatabase: .none)
        let repository = SessionRepository(container: try ModelContainer(for: SessionRepository.schema, configurations: [config]))
        let clock = TestClock()
        var timer = TimerEngine(clock: clock.clock)
        try timer.start(taskName: "Read", plannedDuration: 900)
        let session = try repository.create(timer.snapshot()!)
        #expect(throws: (any Error).self) { try repository.create(timer.snapshot()!) }
        #expect(try repository.addThought(" \n", to: session) == nil)
        try repository.addThought(" First idea ", to: session, at: clock.epoch)
        try repository.addThought("Second idea", to: session, at: clock.epoch.addingTimeInterval(10))
        clock.advance(900)
        timer.pause()
        clock.advance(60)
        timer.resume()
        clock.advance(480)
        try repository.checkpoint(session, snapshot: timer.finish()!, status: .completed)
        return session.id
    }

    @Test @MainActor func testActiveCheckpointCanBeRecoveredWithoutCountingDowntime() throws {
        let config = ModelConfiguration(schema: SessionRepository.schema, isStoredInMemoryOnly: true)
        let repository = SessionRepository(container: try ModelContainer(for: SessionRepository.schema, configurations: [config]))
        let clock = TestClock()
        var timer = TimerEngine(clock: clock.clock)
        try timer.start(taskName: "Read", plannedDuration: 900)
        let session = try repository.create(timer.snapshot()!)
        clock.advance(42)
        try repository.checkpoint(session, snapshot: timer.snapshot()!)
        clock.advance(10_000)
        let saved = try #require(repository.allSessions().first)
        var recovered = TimerEngine(clock: clock.clock)
        try recovered.recover(id: saved.id, taskName: saved.taskName, planned: saved.plannedDurationSeconds,
                              active: saved.actualActiveDurationSeconds, paused: saved.pausedDurationSeconds, startedAt: saved.startedAt)
        #expect(recovered.state == .paused)
        #expect(recovered.snapshot()?.active == 42)
    }
}
