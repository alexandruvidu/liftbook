import Foundation

/// Suggests other exercises that train the same muscles.
enum Substitutions {
    /// Exercises sharing at least one primary muscle with `exercise`, best
    /// matches first (see `score`). Among equal scores, everyday (featured)
    /// exercises come first, then shorter, more basic names, then A–Z, so
    /// the big catalog's obscure variants don't crowd out the classics.
    static func suggestions(for exercise: LibraryExercise, among candidates: [LibraryExercise],
                            limit: Int = 6,
                            featured: Set<String> = ExerciseLibrary.bundled.featuredIDs) -> [LibraryExercise] {
        let primary = Set(exercise.primaryMuscles)
        let scored: [(exercise: LibraryExercise, score: Int, featured: Bool)] = candidates
            .filter { $0.id != exercise.id && !primary.isDisjoint(with: $0.primaryMuscles) }
            .map { (exercise: $0, score: Self.score($0, against: exercise), featured: featured.contains($0.id)) }
        let sorted = scored.sorted { lhs, rhs in
            if lhs.score != rhs.score { return lhs.score > rhs.score }
            if lhs.featured != rhs.featured { return lhs.featured }
            if lhs.exercise.name.count != rhs.exercise.name.count { return lhs.exercise.name.count < rhs.exercise.name.count }
            return lhs.exercise.name < rhs.exercise.name
        }
        return sorted.prefix(limit).map(\.exercise)
    }

    /// Shared primary muscles count most, then the same movement in the name
    /// ("bench press", "curl"), then the same logging type, then shared
    /// secondary muscles; among equal matches, different equipment wins for variety.
    static func score(_ candidate: LibraryExercise, against exercise: LibraryExercise) -> Int {
        let sharedPrimary: Int = Set(exercise.primaryMuscles).intersection(candidate.primaryMuscles).count
        let sharedSecondary: Int = Set(exercise.secondaryMuscles).intersection(candidate.secondaryMuscles).count
        let sharedMovement: Int = movementWords(in: exercise.name).intersection(movementWords(in: candidate.name)).count
        let sameType: Int = candidate.type == exercise.type ? 1 : 0
        let differentEquipment: Int = candidate.equipment != exercise.equipment ? 1 : 0
        return sharedPrimary * 10 + sharedMovement * 5 + sameType * 4 + sharedSecondary * 2 + differentEquipment
    }

    /// Words naming the movement, without equipment, grip or position words:
    /// "Incline Dumbbell Bench Press" → ["bench", "press"].
    static func movementWords(in name: String) -> Set<String> {
        let ignored: Set<String> = ["barbell", "dumbbell", "dumbbells", "cable", "machine", "band", "smith",
                                    "kettlebell", "lever", "weighted", "assisted", "seated", "standing",
                                    "lying", "incline", "decline", "single", "alternating", "grip", "wide",
                                    "close", "narrow", "with", "and", "the", "arm", "leg"]
        return Set(ExerciseFilter.tokens(in: name).filter { $0.count >= 3 && !ignored.contains($0) && Int($0) == nil })
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
