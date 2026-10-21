import Testing
import Foundation
#if SWIFT_PACKAGE
@testable import FocusKit
#else
@testable import Focus
#endif

final class TestClock {
    var seconds: TimeInterval = 0
    var wallOffset: TimeInterval = 0
    let epoch = Date(timeIntervalSince1970: 1_700_000_000)
    var clock: TimerClock { TimerClock { [self] in ClockReading(date: epoch.addingTimeInterval(seconds + wallOffset), instant: seconds) } }
    func advance(_ amount: TimeInterval) { seconds += amount }
}

struct TimerEngineTests {
    @Test func testFifteenMinutesAndProgress() throws {
        let clock = TestClock()
        var timer = TimerEngine(clock: clock.clock)
        #expect(timer.state == .idle)
        try timer.start(taskName: " Read ", plannedDuration: 900)
        #expect(timer.snapshot()?.taskName == "Read")
        #expect(timer.snapshot()?.remaining == 900)
        #expect(timer.snapshot()?.remainingProportion == 1)
        clock.advance(450)
        #expect(timer.snapshot()?.remaining == 450)
        #expect(timer.snapshot()?.remainingProportion == 0.5)
        clock.advance(450)
        #expect(timer.state == .overtime)
        #expect(timer.snapshot()?.remainingProportion == 0)
        #expect(timer.snapshot()?.overtime == 0)
        clock.advance(480)
        #expect(timer.snapshot()?.overtime == 480)
        #expect(timer.snapshot()?.remaining == 0)
        #expect(TimeText.clock(timer.snapshot()!.overtime) == "08:00")
    }

    @Test func testPauseAndResumeMultipleTimesExcludesPauses() throws {
        let clock = TestClock()
        var timer = TimerEngine(clock: clock.clock)
        try timer.start(taskName: "Read", plannedDuration: 900)
        clock.advance(300)
        timer.pause()
        timer.pause()
        clock.advance(120)
        #expect(timer.state == .paused)
        #expect(timer.snapshot()?.remaining == 600)
        timer.resume()
        timer.resume()
        clock.advance(150)
        timer.pause()
        clock.advance(60)
        timer.resume()
        clock.advance(50)
        let finished = timer.finish()
        let end = try #require(finished)
        #expect(end.active == 500)
        #expect(end.paused == 180)
        #expect(end.endedAt!.timeIntervalSince(end.startedAt) == 680)
        #expect(end.state == .finished)
    }

    @Test func testPauseOvertimeAndFinishWhilePaused() throws {
        let clock = TestClock()
        var timer = TimerEngine(clock: clock.clock)
        try timer.start(taskName: "Read", plannedDuration: 900)
        clock.advance(1105)
        timer.pause()
        clock.advance(300)
        #expect(timer.snapshot()?.overtime == 205)
        #expect(timer.snapshot()!.isOvertime)
        timer.resume()
        #expect(timer.state == .overtime)
        clock.advance(275)
        timer.pause()
        clock.advance(10)
        let finished = timer.finish()
        let end = try #require(finished)
        #expect(end.active == 1380)
        #expect(end.overtime == 480)
        #expect(end.paused == 310)
    }

    @Test func testDuplicateStartAndIdempotentFinish() throws {
        let clock = TestClock()
        var timer = TimerEngine(clock: clock.clock)
        try timer.start(taskName: "A", plannedDuration: 900)
        let id = timer.snapshot()!.id
        #expect(throws: (any Error).self) { try timer.start(taskName: "B", plannedDuration: 50) }
        clock.advance(30)
        let end = timer.finish()!
        clock.advance(500)
        let again = timer.finish()
        #expect(again?.active == 30)
        #expect(again?.endedAt == end.endedAt)
        #expect(timer.snapshot()?.id == id)
        #expect(timer.snapshot()?.overtime == 0)
        try timer.start(taskName: "Next", plannedDuration: 28_800)
        #expect(timer.snapshot()?.id != id)
    }

    @Test func testValidation() throws {
        var timer = TimerEngine()
        #expect(throws: (any Error).self) { try timer.start(taskName: " \n", plannedDuration: 60) }
        for duration in [0.0, -1, Double.nan, Double.infinity, 86_401] {
            #expect(throws: (any Error).self) { try timer.start(taskName: "Task", plannedDuration: duration) }
        }
        #expect(timer.state == .idle)
        try timer.start(taskName: "Long session", plannedDuration: 28_800)
        #expect(timer.snapshot()?.planned == 28_800)
    }

    @Test func testRecoveryExcludesUnknownTimeAndStartsPaused() throws {
        let clock = TestClock()
        clock.advance(100_000)
        var timer = TimerEngine(clock: clock.clock)
        let id = UUID()
        try timer.recover(id: id, taskName: "Recovered", planned: 900, active: 400, paused: 30, startedAt: clock.epoch)
        #expect(timer.state == .paused)
        #expect(timer.snapshot()?.active == 400)
        #expect(timer.snapshot()?.paused == 30)
        clock.advance(60)
        timer.resume()
        clock.advance(100)
        #expect(timer.snapshot()?.active == 500)
        #expect(timer.snapshot()?.paused == 90)
        #expect(timer.snapshot()?.id == id)
    }

    @Test func testWallClockChangesDoNotChangeActiveTimeAndLongBackgroundGapIsAccurate() throws {
        let clock = TestClock()
        var timer = TimerEngine(clock: clock.clock)
        try timer.start(taskName: "Work", plannedDuration: 900)
        clock.advance(10)
        clock.wallOffset = -3600
        #expect(timer.snapshot()?.active == 10)
        clock.advance(3600)
        #expect(timer.snapshot()?.active == 3610)
        #expect(timer.state == .overtime)
    }

    @Test func testDisplayRoundingAndHours() {
        #expect(TimeText.clock(899.9, roundingUp: true) == "15:00")
        #expect(TimeText.clock(0) == "00:00")
        #expect(TimeText.clock(28_800) == "8:00:00")
        #expect(TimeText.clock(-3) == "00:00")
    }
}
