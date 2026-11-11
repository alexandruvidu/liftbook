import Foundation
import SwiftData
import Testing
@testable import Liftbook

@MainActor
struct ExerciseAliasesTests {
    private let library = ExerciseLibrary.bundled

    @Test func everyAliasPointsAtAnExerciseThatStays() {
        #expect(!ExerciseAliases.bundled.isEmpty)
        for (removed, kept) in ExerciseAliases.bundled {
            #expect(library.byID[removed] == nil, "\(removed) is still in the catalog")
            #expect(library.byID[kept] != nil, "\(kept) is missing")
            #expect(ExerciseAliases.bundled[kept] == nil, "\(kept) is itself removed")
        }
    }

    @Test func removedIDsStillResolveToTheKeptExercise() {
        #expect(library.exercise(id: "run")?.id == "running")
        #expect(ExerciseAliases.resolve("split-squats") == "split-squat")
        #expect(ExerciseAliases.resolve("barbell-bench-press") == "barbell-bench-press")
    }

    @Test func migrationMovesLoggedDataToTheKeptExercise() {
        let container = Persistence.makeContainer(inMemory: true)
        let context = container.mainContext
        let session = WorkoutSession(name: "W")
        context.insert(session)
        session.addExercises(["sumo-squats"], setCount: 1)
        let set = session.exercises[0].sets[0]
        set.measurement = SetMeasurement(reps: 12)
        set.toggleCompleted(for: .bodyweight)
        context.insert(Machine(exerciseID: "run", name: "Treadmill"))

        let changed = ExerciseAliases.migrate(in: context)
        #expect(changed == 2)
        #expect(session.exercises[0].exerciseID == "sumo-squat")
        // Moved onto a weighted exercise: counts as 0 kg and stays complete.
        #expect(set.measurement.weight == 0)
        #expect(set.measurement.isComplete(for: .weightAndReps))
        let machines = (try? context.fetch(FetchDescriptor<Machine>())) ?? []
        #expect(machines.map(\.exerciseID) == ["running"])
        #expect(ExerciseAliases.migrate(in: context) == 0)
    }
}
