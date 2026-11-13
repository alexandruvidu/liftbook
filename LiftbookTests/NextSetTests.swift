import Foundation
import SwiftData
import Testing
@testable import Liftbook

/// Logging sets from the Live Activity, and what it shows.
@MainActor
struct NextSetTests {
    private let container = Persistence.makeContainer(inMemory: true)
    private let start = Date(timeIntervalSince1970: 1_000_000)

    /// Bench press with 2 sets, then rows with 1.
    private func workout() -> WorkoutSession {
        let session = WorkoutSession(name: "Push", startedAt: start)
        container.mainContext.insert(session)
        session.addExercises(["bench"], setCount: 2)
        session.addExercises(["row"], setCount: 1)
        return session
    }

    private func type(_ id: String) -> ExerciseType { .weightAndReps }

    @Test func nextSetIsTheFirstNotCheckedOffInWorkoutOrder() throws {
        let session = workout()
        #expect(session.nextSetToLog?.exercise.exerciseID == "bench")
        #expect(session.nextSetToLog?.index == 0)

        let bench = try #require(session.orderedExercises.first)
        for set in bench.orderedSets {
            set.measurement = SetMeasurement(weight: 60, reps: 8)
            set.toggleCompleted(for: .weightAndReps)
        }
        #expect(session.nextSetToLog?.exercise.exerciseID == "row")
        #expect(session.nextSetToLog?.index == 0)

        session.orderedExercises[1].orderedSets[0].measurement = SetMeasurement(weight: 40, reps: 10)
        session.orderedExercises[1].orderedSets[0].toggleCompleted(for: .weightAndReps)
        #expect(session.nextSetToLog == nil)
    }

    @Test func loggingFillsLastTimesValuesAndStartsRest() throws {
        let session = workout()
        let logged = session.logNextSet(type: type, placeholder: { _, _ in SetMeasurement(weight: 60, reps: 8) },
                                        defaultRest: 90, at: start)
        #expect(logged)
        let first = try #require(session.orderedExercises.first?.orderedSets.first)
        #expect(first.isCompleted)
        #expect(first.weight == 60)
        #expect(first.reps == 8)
        #expect(session.restEndsAt == start.addingTimeInterval(90))
        #expect(session.restExerciseID == "bench")
        #expect(session.nextSetToLog?.index == 1)
    }

    @Test func typedValuesWinOverLastTime() throws {
        let session = workout()
        let first = try #require(session.orderedExercises.first?.orderedSets.first)
        first.measurement = SetMeasurement(weight: 65)
        session.logNextSet(type: type, placeholder: { _, _ in SetMeasurement(weight: 60, reps: 8) }, defaultRest: 90)
        #expect(first.weight == 65)
        #expect(first.reps == 8)
    }

    @Test func aSetWithoutValuesIsNotLogged() {
        let session = workout()
        let logged = session.logNextSet(type: type, placeholder: { _, _ in nil }, defaultRest: 90)
        #expect(!logged)
        #expect(session.nextSetToLog?.index == 0)
        #expect(session.restEndsAt == nil)
    }

    @Test func activityStateShowsTheNextSetAndProgress() {
        let session = workout()
        let state = WorkoutActivityAttributes.ContentState(
            session: session, name: { $0 == "bench" ? "Bench Press" : "Row" }, type: type,
            placeholder: { _, _ in SetMeasurement(weight: 60, reps: 8) }, unit: .kilograms)
        #expect(state.workoutName == "Push")
        #expect(state.exerciseName == "Bench Press")
        #expect(state.setLabel == "Set 1 of 2")
        #expect(state.canLog)
        #expect(state.target.contains("60"))
        #expect(state.completedSets == 0)
        #expect(state.totalSets == 3)
        #expect(state.restEndsAt == nil)
    }

    @Test func activityStateAsksToOpenTheAppWithoutValues() {
        let session = workout()
        let state = WorkoutActivityAttributes.ContentState(
            session: session, name: { $0 }, type: type, placeholder: { _, _ in nil }, unit: .kilograms)
        #expect(!state.canLog)
        #expect(state.target.isEmpty)
    }

    @Test func activityStateShowsRestWithItsStart() {
        let session = workout()
        session.startRest(seconds: 120, for: "bench", at: start)
        let state = WorkoutActivityAttributes.ContentState(
            session: session, name: { $0 }, type: type, placeholder: { _, _ in nil }, unit: .kilograms)
        #expect(state.restEndsAt == start.addingTimeInterval(120))
        #expect(state.restStartedAt == start)
    }
}
