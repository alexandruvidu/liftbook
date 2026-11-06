import Foundation

/// Suggests other exercises that train the same muscles.
enum Substitutions {
    /// Exercises sharing at least one primary muscle with `exercise`, best
    /// matches first: shared primary muscles count most, then the same way of
    /// logging sets, then shared secondary muscles. Ties go alphabetically.
    static func suggestions(for exercise: LibraryExercise, among candidates: [LibraryExercise],
                            limit: Int = 6) -> [LibraryExercise] {
        let primary = Set(exercise.primaryMuscles)
        let secondary = Set(exercise.secondaryMuscles)
        return candidates
            .filter { $0.id != exercise.id && !primary.isDisjoint(with: $0.primaryMuscles) }
            .map { candidate -> (LibraryExercise, Int) in
                let sharedPrimary = primary.intersection(candidate.primaryMuscles).count
                let sharedSecondary = secondary.intersection(candidate.secondaryMuscles).count
                let sameType = candidate.type == exercise.type ? 1 : 0
                let differentEquipment = candidate.equipment != exercise.equipment ? 1 : 0
                // Variety: among equal matches, prefer different equipment
                return (candidate, sharedPrimary * 10 + sameType * 4 + sharedSecondary * 2 + differentEquipment)
            }
            .sorted { $0.1 != $1.1 ? $0.1 > $1.1 : $0.0.name < $1.0.name }
            .prefix(limit)
            .map(\.0)
    }
}

extension WorkoutExercise {
    /// Switches to another exercise. Completed sets keep their values;
    /// the rest are cleared, since the old numbers don't carry over.
    func swap(to exerciseID: String) {
        guard exerciseID != self.exerciseID else { return }
        self.exerciseID = exerciseID
        for set in sets where !set.isCompleted {
            set.measurement = SetMeasurement()
            set.rpe = nil
        }
    }
}
