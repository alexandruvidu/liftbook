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
        open(ModelConfiguration(schema: schema, isStoredInMemoryOnly: inMemory))
    }

    /// A store in a specific file; UI tests use this to survive a relaunch.
    static func makeContainer(url: URL) -> ModelContainer {
        open(ModelConfiguration(schema: schema, url: url))
    }

    private static func open(_ configuration: ModelConfiguration) -> ModelContainer {
        do {
            return try ModelContainer(for: schema, configurations: configuration)
        } catch {
            fatalError("Could not open the Liftbook data store: \(error)")
        }
    }

    /// Adds an "Upper Body" routine. Used by UI tests via `-uiTestSeedSampleData YES`.
    @MainActor
    static func seedSampleData(in context: ModelContext) {
        // A relaunched UI test keeps its store; don't add the routine twice.
        guard ((try? context.fetchCount(FetchDescriptor<Routine>())) ?? 0) == 0 else { return }
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
