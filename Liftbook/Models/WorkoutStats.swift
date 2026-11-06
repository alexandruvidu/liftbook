import Foundation

/// Running totals for the workout in progress, shown in its stat strip.
struct WorkoutStats: Equatable {
    /// Sets checked off, of every kind.
    let completedSets: Int
    let totalSets: Int
    /// Kilograms lifted in completed working sets, as in the finish summary.
    let volume: Double

    static func of(_ session: WorkoutSession, type: (String) -> ExerciseType) -> WorkoutStats {
        let sets = session.exercises.flatMap(\.sets)
        return WorkoutStats(completedSets: sets.filter(\.isCompleted).count,
                            totalSets: sets.count,
                            volume: WorkoutSummary(session: session, history: [], type: type).volume)
    }
}
