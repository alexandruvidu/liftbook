import Foundation

/// Orderings for browsing the exercise library without search text.
enum ExerciseBrowsing {
    /// Everyday (featured) exercises A–Z, then the rest A–Z, so the list
    /// doesn't open on "1 Leg Box Squat" and "3008 Abdominal Crunch".
    /// Custom exercises count as everyday: they were added on purpose.
    static func featuredFirst(_ exercises: [LibraryExercise],
                              featured: Set<String> = ExerciseLibrary.bundled.featuredIDs) -> [LibraryExercise] {
        let isEveryday: (LibraryExercise) -> Bool = { $0.isCustom || featured.contains($0.id) }
        return exercises.filter(isEveryday) + exercises.filter { !isEveryday($0) }
    }

    /// IDs of exercises logged in `sessions`, most recently done first, each once.
    static func recentIDs(in sessions: [WorkoutSession], limit: Int = 8) -> [String] {
        var seen: Set<String> = []
        var ids: [String] = []
        for session in sessions.sorted(by: { $0.startedAt > $1.startedAt }) {
            for exercise in session.orderedExercises where seen.insert(exercise.exerciseID).inserted {
                ids.append(exercise.exerciseID)
                if ids.count == limit { return ids }
            }
        }
        return ids
    }
}
