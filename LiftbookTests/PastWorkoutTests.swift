import Foundation
import SwiftData
import Testing
@testable import Liftbook

@MainActor
struct PastWorkoutTests {
    private let container = Persistence.makeContainer(inMemory: true)
    private let start = Date(timeIntervalSince1970: 1_000_000)

    private func past() -> WorkoutSession {
        let session = WorkoutSession(name: "Push", startedAt: start, routineID: UUID())
        container.mainContext.insert(session)
        session.addExercises(["bench", "fly", "dips"], setCount: 2)
        let bench = session.orderedExercises[0]
        bench.orderedSets[0].kind = .warmUp
        bench.orderedSets[0].measurement = SetMeasurement(weight: 40, reps: 10)
        bench.orderedSets[1].measurement = SetMeasurement(weight: 80, reps: 5)
        bench.orderedSets.forEach { $0.toggleCompleted(for: .weightAndReps) }
        bench.restSeconds = 180
        session.linkWithNext(session.orderedExercises[1])
        session.notes = "Good day"
        session.finish(at: start.addingTimeInterval(3000))
        return session
    }

    @Test func repeatingCopiesExercisesAndSetsButNotCompletion() {
        let old = past()
        let new = WorkoutStarter.repeating(old, at: start.addingTimeInterval(86_400))
        #expect(new.name == "Push")
        #expect(new.isInProgress)
        #expect(new.routineID == old.routineID)
        #expect(new.notes.isEmpty)
        #expect(new.orderedExercises.map(\.exerciseID) == ["bench", "fly", "dips"])
        let bench = new.orderedExercises[0]
        #expect(bench.orderedSets.map(\.kind) == [.warmUp, .normal])
        #expect(bench.orderedSets.map(\.measurement) == [SetMeasurement(weight: 40, reps: 10), SetMeasurement(weight: 80, reps: 5)])
        #expect(bench.orderedSets.allSatisfy { !$0.isCompleted && $0.completedAt == nil })
        #expect(bench.restSeconds == 180)
    }

    @Test func repeatingKeepsSupersetsWithNewGroups() {
        let old = past()
        let new = WorkoutStarter.repeating(old)
        #expect(new.supersets.map { $0.map(\.exerciseID) } == [["fly", "dips"]])
        #expect(new.orderedExercises[1].supersetGroup != old.orderedExercises[1].supersetGroup)
    }

    @Test func durationCanBeEdited() {
        let session = past()
        #expect(session.durationMinutes == 50)
        session.setDuration(minutes: 65)
        #expect(session.endedAt == start.addingTimeInterval(65 * 60))
        session.setDuration(minutes: 0)
        #expect(session.durationMinutes == 1)
    }

    @Test func movingTheStartKeepsTheLength() {
        let session = past()
        let newStart = start.addingTimeInterval(-7200)
        session.moveStart(to: newStart)
        #expect(session.startedAt == newStart)
        #expect(session.durationMinutes == 50)
    }

    @Test func inProgressWorkoutsHaveNoEditableDuration() {
        let session = WorkoutSession(name: "Now", startedAt: start)
        session.setDuration(minutes: 30)
        #expect(session.endedAt == nil)
        #expect(session.durationMinutes == 0)
    }
}
