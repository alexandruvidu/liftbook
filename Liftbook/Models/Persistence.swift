import Foundation
import SwiftData

enum Persistence {
    /// Every SwiftData model the app stores.
    static let schema = Schema([
        CustomExercise.self,
        RoutineFolder.self,
        Routine.self,
        RoutineEntry.self,
        WorkoutSession.self,
        WorkoutExercise.self,
        WorkoutSet.self,
    ])

    static func makeContainer(inMemory: Bool) -> ModelContainer {
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: inMemory)
        do {
            return try ModelContainer(for: schema, configurations: configuration)
        } catch {
            fatalError("Could not open the Liftbook data store: \(error)")
        }
    }

    /// Adds an "Upper Body" routine. Used by UI tests via `-uiTestSeedSampleData YES`.
    @MainActor
    static func seedSampleData(in context: ModelContext) {
        var draft = RoutineDraft()
        draft.name = "Upper Body"
        draft.add(["barbell-bench-press", "bent-over-barbell-row", "overhead-press"])
        draft.entries[2].setCount = 2
        let routine = Routine()
        context.insert(routine)
        routine.apply(draft, folder: nil, in: context)
        try? context.save()
    }
}
