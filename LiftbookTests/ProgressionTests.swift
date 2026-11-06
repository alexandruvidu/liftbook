import Foundation
import SwiftData
import Testing
@testable import Liftbook

@MainActor
struct ProgressionTests {
    private func exercise(_ id: String) -> LibraryExercise {
        ExerciseLibrary.bundled.exercise(id: id)!
    }

    private func sets(_ weight: Double?, _ reps: [Int]) -> [SetMeasurement] {
        reps.map { SetMeasurement(weight: weight, reps: $0) }
    }

    @Test func topOfTheRangeOnEverySetAddsWeight() throws {
        let suggestion = try #require(Progression.suggestion(
            lastSets: sets(60, [12, 12, 12]), exercise: exercise("barbell-bench-press"), range: 8...12, unit: .kilograms))
        #expect(suggestion.increasesWeight)
        #expect(suggestion.weight == 62.5)
        #expect(suggestion.reps == 8)
    }

    @Test func lowerBodyGetsABiggerJump() throws {
        let suggestion = try #require(Progression.suggestion(
            lastSets: sets(100, [8, 8]), exercise: exercise("back-squat"), range: 5...8, unit: .kilograms))
        #expect(suggestion.weight == 105)
        let pounds = try #require(Progression.suggestion(
            lastSets: sets(100, [8, 8]), exercise: exercise("back-squat"), range: 5...8, unit: .pounds))
        #expect(abs(pounds.weight - (100 + 10 / WeightUnit.poundsPerKilogram)) < 0.0001)
    }

    @Test func otherwiseOneMoreRepAtTheSameWeight() throws {
        let suggestion = try #require(Progression.suggestion(
            lastSets: sets(60, [12, 10, 9]), exercise: exercise("barbell-bench-press"), range: 8...12, unit: .kilograms))
        #expect(!suggestion.increasesWeight)
        #expect(suggestion.weight == 60)
        #expect(suggestion.reps == 10)
    }

    @Test func belowTheRangeAimsForTheBottom() throws {
        let suggestion = try #require(Progression.suggestion(
            lastSets: sets(80, [5, 4]), exercise: exercise("barbell-bench-press"), range: 8...12, unit: .kilograms))
        #expect(suggestion.reps == 8)
    }

    @Test func bodyweightAddsARep() throws {
        let suggestion = try #require(Progression.suggestion(
            lastSets: sets(nil, [10, 8]), exercise: exercise("push-up"), range: 8...12, unit: .kilograms))
        #expect(suggestion.reps == 9)
    }

    @Test func nothingToGoOn() {
        #expect(Progression.suggestion(lastSets: [], exercise: exercise("barbell-bench-press"),
                                       range: 8...12, unit: .kilograms) == nil)
        #expect(Progression.suggestion(lastSets: sets(nil, [60]), exercise: exercise("plank"),
                                       range: 8...12, unit: .kilograms) == nil)
    }

    @Test func rangeEncoding() {
        #expect(Progression.decode(Progression.encode(6...10)) == 6...10)
        #expect(Progression.decode("12-8") == nil)
        #expect(Progression.decode(nil) == nil)
    }

    @Test func applyFillsOnlyEmptyUncheckedWorkingSets() {
        let container = Persistence.makeContainer(inMemory: true)
        let session = WorkoutSession(name: "W")
        container.mainContext.insert(session)
        session.addExercises(["barbell-bench-press"], setCount: 3)
        let workoutExercise = session.exercises[0]
        let ordered = workoutExercise.orderedSets
        ordered[0].measurement = SetMeasurement(weight: 50, reps: 5)
        workoutExercise.apply(Progression.Suggestion(weight: 62.5, reps: 8, increasesWeight: true, reason: ""),
                              type: .weightAndReps)
        #expect(ordered[0].measurement == SetMeasurement(weight: 50, reps: 5))
        #expect(ordered[1].measurement == SetMeasurement(weight: 62.5, reps: 8))
        #expect(ordered[2].measurement == SetMeasurement(weight: 62.5, reps: 8))
    }
}
