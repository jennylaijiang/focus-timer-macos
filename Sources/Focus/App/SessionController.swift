import Foundation
import Observation
#if SWIFT_PACKAGE
import FocusKit
#endif

@MainActor @Observable final class SessionController {
    private(set) var repository: SessionRepository?
    private var engine = TimerEngine()
    private var ticker: Timer?
    private var lastCheckpoint = ContinuousClock.now
    private var finishStatus: SessionStatus = .completed
    private(set) var current: FocusSession?
    private(set) var snapshot: TimerSnapshot?
    private(set) var history: [FocusSession] = []
    var errorMessage: String?
    var notice: String?
    var recovered = false
    var hasUnsavedChanges = false
    var taskName = ""
    var durationMinutes = "25"
    var thoughtText = ""
    var showsHistory = false
    var sidebarVisible = true
    var alwaysOnTop = false

    var isActive: Bool { engine.isActive }
    var canStart: Bool { repository != nil && !isActive && !hasUnsavedChanges }

    init() {
        loadStore()
        ticker = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in self?.refresh() }
        }
        if let ticker { RunLoop.main.add(ticker, forMode: .common) }
    }

    func loadStore() {
        guard repository == nil else { retrySave(); return }
        do {
            let repository = try SessionRepository.persistent()
            let sessions = try repository.allSessions()
            self.repository = repository
            if let latest = sessions.first(where: { $0.status == .active }) {
                // Defensive repair of a legacy/corrupted multiple-active store.
                for older in sessions.filter({ $0.status == .active && $0.id != latest.id }) {
                    older.statusRaw = SessionStatus.interrupted.rawValue
                    older.timerStateRaw = TimerState.finished.rawValue
                    older.endedAt = older.checkpointAt
                }
                try engine.recover(id: latest.id, taskName: latest.taskName, planned: latest.plannedDurationSeconds,
                                   active: latest.actualActiveDurationSeconds, paused: latest.pausedDurationSeconds, startedAt: latest.startedAt)
                latest.unobservedDurationSeconds += max(0, Date().timeIntervalSince(latest.checkpointAt))
                current = latest
                snapshot = engine.snapshot()
                recovered = true
                notice = "Recovered paused at the last saved checkpoint. Time while Focus was closed is excluded. Resume when ready, or end this session as interrupted."
                persistCurrent()
            }
            reloadHistory()
        } catch {
            errorMessage = "Couldn’t open your saved sessions: \(error.localizedDescription)"
            if current == nil { repository = nil }
        }
    }

    func start() {
        guard canStart, let repository else { return }
        do {
            guard let minutes = Double(durationMinutes.trimmingCharacters(in: .whitespacesAndNewlines)), minutes.isFinite else {
                throw TimerError.invalidDuration
            }
            var candidate = TimerEngine()
            try candidate.start(taskName: taskName, plannedDuration: minutes * 60)
            guard let initial = candidate.snapshot() else { return }
            let record = try repository.create(initial)
            engine = candidate
            current = record
            snapshot = initial
            recovered = false
            notice = nil
            errorMessage = nil
            thoughtText = ""
            lastCheckpoint = .now
        } catch { errorMessage = error.localizedDescription }
    }

    func refresh() {
        guard isActive else { return }
        let wasOvertime = snapshot?.isOvertime ?? false
        snapshot = engine.snapshot()
        if lastCheckpoint.duration(to: .now) >= .seconds(5) || (!wasOvertime && snapshot?.isOvertime == true) {
            persistCurrent()
        }
    }

    func togglePause() {
        guard isActive else { return }
        if engine.state == .paused { engine.resume(); notice = nil; recovered = false } else { engine.pause() }
        snapshot = engine.snapshot()
        persistCurrent()
    }

    func pauseForSleep() {
        guard isActive else { return }
        engine.pause()
        snapshot = engine.snapshot()
        notice = "Paused for Mac sleep. Resume when you’re ready; sleep time is excluded from focus time."
        persistCurrent()
    }

    func finish(interrupted: Bool = false) {
        guard isActive else { return }
        // Preserve a typed thought when the user finishes without pressing Return.
        guard captureThought() else { return }
        snapshot = engine.finish()
        finishStatus = interrupted ? .interrupted : .completed
        recovered = false
        notice = nil
        persistCurrent()
        reloadHistory()
    }

    @discardableResult func captureThought() -> Bool {
        guard !thoughtText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return true }
        guard isActive, let current, let repository else { return false }
        do {
            try repository.addThought(thoughtText, to: current)
            thoughtText = ""
            snapshot = engine.snapshot()
            persistCurrent()
            return true
        } catch {
            errorMessage = "Couldn’t save that thought. Your text is still here. \(error.localizedDescription)"
            return false
        }
    }

    func newSession() {
        guard canStart else { return }
        current = nil
        snapshot = nil
        taskName = ""
        notice = nil
        errorMessage = nil
    }

    @discardableResult func prepareToQuit() -> Bool {
        guard captureThought() else { return false }
        if isActive {
            engine.pause()
            snapshot = engine.snapshot()
            persistCurrent()
        } else if hasUnsavedChanges { retrySave() }
        return !hasUnsavedChanges
    }

    func retrySave() {
        if repository == nil { loadStore(); return }
        persistCurrent()
        reloadHistory()
    }

    private func persistCurrent() {
        guard let repository, let current, let snapshot else { return }
        do {
            try repository.checkpoint(current, snapshot: snapshot, status: isActive ? .active : finishStatus)
            if hasUnsavedChanges { errorMessage = nil }
            hasUnsavedChanges = false
            lastCheckpoint = .now
        } catch {
            hasUnsavedChanges = true
            errorMessage = "Changes haven’t been saved. Keep Focus open and retry. \(error.localizedDescription)"
            lastCheckpoint = .now // Avoid retrying on every display refresh.
        }
    }

    func reloadHistory() {
        do { history = try repository?.allSessions().filter { $0.status != .active } ?? [] }
        catch { errorMessage = "Couldn’t load history: \(error.localizedDescription)" }
    }
}
