import Foundation
import Testing
@testable import Liftbook

struct RestTimerTests {
    private let now = Date(timeIntervalSince1970: 10_000)

    @Test(arguments: [(0, "Off"), (45, "45s"), (60, "1 min"), (90, "1:30"), (120, "2 min"), (150, "2:30")])
    func labels(seconds: Int, expected: String) {
        #expect(RestTimer.label(seconds: seconds) == expected)
    }

    @Test func optionsIncludeOffAndTheFallback() {
        #expect(RestTimer.options.first == 0)
        #expect(RestTimer.options.contains(RestTimer.fallbackSeconds))
        #expect(RestTimer.options == RestTimer.options.sorted())
    }

    @Test func startCountsDown() {
        let session = WorkoutSession(name: "W")
        session.startRest(seconds: 90, for: "barbell-bench-press", at: now)
        #expect(session.restRemaining(at: now) == 90)
        #expect(session.restRemaining(at: now.addingTimeInterval(30)) == 60)
        #expect(session.restProgress(at: now.addingTimeInterval(45)) == 0.5)
        #expect(session.restExerciseID == "barbell-bench-press")
        #expect(session.restRemaining(at: now.addingTimeInterval(90)) == nil)
    }

    @Test func zeroSecondsMeansNoTimer() {
        let session = WorkoutSession(name: "W")
        session.startRest(seconds: 60, for: "a", at: now)
        session.startRest(seconds: 0, for: "b", at: now)
        #expect(session.restEndsAt == nil)
        #expect(session.restRemaining(at: now) == nil)
    }

    @Test func adjustAddsAndRemovesTime() {
        let session = WorkoutSession(name: "W")
        session.startRest(seconds: 60, for: "a", at: now)
        session.adjustRest(by: 15, at: now)
        #expect(session.restRemaining(at: now) == 75)
        #expect(session.restDuration == 75)
        session.adjustRest(by: -30, at: now)
        #expect(session.restRemaining(at: now) == 45)
    }

    @Test func removingAllTimeStopsTheTimer() {
        let session = WorkoutSession(name: "W")
        session.startRest(seconds: 10, for: "a", at: now)
        session.adjustRest(by: -15, at: now)
        #expect(session.restEndsAt == nil)
        #expect(session.restExerciseID == nil)
    }

    @Test func adjustWithoutTimerDoesNothing() {
        let session = WorkoutSession(name: "W")
        session.adjustRest(by: 15, at: now)
        #expect(session.restEndsAt == nil)
    }

    @Test func exerciseRestFallsBackToDefault() {
        let exercise = WorkoutExercise(exerciseID: "a", position: 0)
        #expect(exercise.effectiveRestSeconds(default: 120) == 120)
        exercise.restSeconds = 0
        #expect(exercise.effectiveRestSeconds(default: 120) == 0)
        exercise.restSeconds = 45
        #expect(exercise.effectiveRestSeconds(default: 120) == 45)
    }
}
