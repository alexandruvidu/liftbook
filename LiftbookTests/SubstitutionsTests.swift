import Foundation
import SwiftData
import Testing
@testable import Liftbook

@MainActor
struct SubstitutionsTests {
    private let library = ExerciseLibrary.bundled

    @Test func suggestionsShareAPrimaryMuscle() throws {
        let bench = try #require(library.exercise(id: "barbell-bench-press"))
        let suggestions = Substitutions.suggestions(for: bench, among: library.exercises)
        #expect(suggestions.count == 6)
        #expect(!suggestions.contains { $0.id == bench.id })
        #expect(suggestions.allSatisfy { !Set($0.primaryMuscles).isDisjoint(with: bench.primaryMuscles) })
    }

    @Test func sameTypeRanksAboveOtherTypes() {
        func make(_ id: String, _ type: ExerciseType, equipment: Equipment = .barbell) -> LibraryExercise {
            LibraryExercise(id: id, name: id, primaryMuscles: [.chest], secondaryMuscles: [],
                            equipment: equipment, type: type, details: "")
        }
        let target = make("target", .weightAndReps)
        let candidates = [make("a-bodyweight", .bodyweight), make("b-weighted", .weightAndReps),
                          make("c-dumbbell", .weightAndReps, equipment: .dumbbell), make("legs", .weightAndReps)]
        let legs = LibraryExercise(id: "legs", name: "legs", primaryMuscles: [.quads], secondaryMuscles: [],
                                   equipment: .barbell, type: .weightAndReps, details: "")
        let result = Substitutions.suggestions(for: target, among: Array(candidates.dropLast()) + [legs])
        // Different equipment wins the tie, then the other weighted exercise, then bodyweight
        #expect(result.map(\.id) == ["c-dumbbell", "b-weighted", "a-bodyweight"])
    }

    @Test func swappingKeepsCompletedSetsAndClearsTheRest() {
        let container = Persistence.makeContainer(inMemory: true)
        let session = WorkoutSession(name: "W")
        container.mainContext.insert(session)
        session.addExercises(["barbell-bench-press"], setCount: 2)
        let exercise = session.exercises[0]
        let sets = exercise.orderedSets
        sets.forEach { $0.measurement = SetMeasurement(weight: 80, reps: 5) }
        sets[0].toggleCompleted(for: .weightAndReps)
        sets[1].rpe = 8

        exercise.swap(to: "dumbbell-bench-press")
        #expect(exercise.exerciseID == "dumbbell-bench-press")
        #expect(sets[0].measurement == SetMeasurement(weight: 80, reps: 5))
        #expect(sets[1].measurement == SetMeasurement())
        #expect(sets[1].rpe == nil)
    }
}
