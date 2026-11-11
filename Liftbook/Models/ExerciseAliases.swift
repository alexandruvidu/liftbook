import Foundation
import SwiftData

/// Duplicate exercises removed from the catalog, and the exercise each was
/// merged into (`exercise-aliases.json`). Logged data that still points at a
/// removed ID is moved to the kept one on launch, and imports are mapped too.
enum ExerciseAliases {
    /// Removed ID → kept ID, from the app bundle.
    static let bundled: [String: String] = {
        guard let url = Bundle.main.url(forResource: "exercise-aliases", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let aliases = try? JSONDecoder().decode([String: String].self, from: data)
        else { return [:] }
        return aliases
    }()

    /// The kept ID for a removed duplicate; any other ID unchanged.
    static func resolve(_ id: String, aliases: [String: String] = bundled) -> String {
        aliases[id] ?? id
    }

    /// Points workouts, routines, machines and media at the kept exercises.
    /// Returns how many records changed; saves only when something did.
    @MainActor
    @discardableResult
    static func migrate(in context: ModelContext, aliases: [String: String] = bundled,
                        library: ExerciseLibrary = .bundled) -> Int {
        guard !aliases.isEmpty else { return 0 }
        var changed = 0
        func remap(_ id: inout String) -> Bool {
            guard let kept = aliases[id] else { return false }
            id = kept
            changed += 1
            return true
        }
        for exercise in (try? context.fetch(FetchDescriptor<WorkoutExercise>())) ?? [] where remap(&exercise.exerciseID) {
            // A bodyweight set moved to a weighted exercise counts as 0 kg, so
            // completed sets stay complete.
            guard library.exercise(id: exercise.exerciseID)?.type == .weightAndReps else { continue }
            for set in exercise.sets where set.measurement.weight == nil {
                set.measurement.weight = 0
            }
        }
        for entry in (try? context.fetch(FetchDescriptor<RoutineEntry>())) ?? [] { _ = remap(&entry.exerciseID) }
        for machine in (try? context.fetch(FetchDescriptor<Machine>())) ?? [] { _ = remap(&machine.exerciseID) }
        for media in (try? context.fetch(FetchDescriptor<ExerciseMedia>())) ?? [] { _ = remap(&media.exerciseID) }
        if changed > 0 { try? context.save() }
        return changed
    }
}
