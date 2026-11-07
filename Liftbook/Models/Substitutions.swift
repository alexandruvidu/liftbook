import Foundation

/// Suggests other exercises that train the same muscles.
enum Substitutions {
    /// Exercises sharing at least one primary muscle with `exercise`, best
    /// matches first: shared primary muscles count most, then the same way of
    /// logging sets, then shared secondary muscles. Ties go alphabetically.
    static func suggestions(for exercise: LibraryExercise, among candidates: [LibraryExercise],
                            limit: Int = 6) -> [LibraryExercise] {
        let primary = Set(exercise.primaryMuscles)
        let scored: [(exercise: LibraryExercise, score: Int)] = candidates
            .filter { $0.id != exercise.id && !primary.isDisjoint(with: $0.primaryMuscles) }
            .map { (exercise: $0, score: Self.score($0, against: exercise)) }
        let sorted = scored.sorted { lhs, rhs in
            lhs.score != rhs.score ? lhs.score > rhs.score : lhs.exercise.name < rhs.exercise.name
        }
        return sorted.prefix(limit).map(\.exercise)
    }

    /// Shared primary muscles count most, then the same logging type, then
    /// shared secondary muscles; among equal matches, different equipment
    /// wins for variety.
    static func score(_ candidate: LibraryExercise, against exercise: LibraryExercise) -> Int {
        let sharedPrimary: Int = Set(exercise.primaryMuscles).intersection(candidate.primaryMuscles).count
        let sharedSecondary: Int = Set(exercise.secondaryMuscles).intersection(candidate.secondaryMuscles).count
        let sameType: Int = candidate.type == exercise.type ? 1 : 0
        let differentEquipment: Int = candidate.equipment != exercise.equipment ? 1 : 0
        return sharedPrimary * 10 + sameType * 4 + sharedSecondary * 2 + differentEquipment
    }
}

extension WorkoutExercise {
    /// Switches to another exercise. Completed sets keep their values;
    /// the rest are cleared, since the old numbers don't carry over.
    func swap(to exerciseID: String) {
        guard exerciseID != self.exerciseID else { return }
        self.exerciseID = exerciseID
        // A machine belongs to one exercise, so it doesn't carry over.
        machineID = nil
        machineConfirmed = true
        for set in sets where !set.isCompleted {
            set.measurement = SetMeasurement()
            set.rpe = nil
        }
    }
}
