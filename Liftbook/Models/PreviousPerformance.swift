import Foundation

/// What the user did for an exercise the last time they finished a workout
/// containing it.
struct PreviousPerformance: Equatable, Sendable {
    /// Completed sets from that workout, in order.
    let sets: [SetMeasurement]
    let date: Date
    /// The completed sets that weren't warm-ups.
    var workingSets: [SetMeasurement] = []

    /// The previous set at the same position, if there was one.
    func set(at index: Int) -> SetMeasurement? {
        sets.indices.contains(index) ? sets[index] : nil
    }

    /// Looks through finished sessions (newest first wins) for the most recent
    /// one that has completed sets of the exercise.
    static func find(exerciseID: String, in sessions: [WorkoutSession], excluding current: WorkoutSession? = nil) -> PreviousPerformance? {
        let finished = sessions
            .filter { $0.endedAt != nil && $0.sessionID != current?.sessionID }
            .sorted { $0.startedAt > $1.startedAt }
        for session in finished {
            let completed = session.orderedExercises
                .filter { $0.exerciseID == exerciseID }
                .flatMap(\.orderedSets)
                .filter(\.isCompleted)
            if !completed.isEmpty {
                return PreviousPerformance(sets: completed.map(\.measurement), date: session.startedAt,
                                           workingSets: completed.filter { $0.kind.isWorkingSet }.map(\.measurement))
            }
        }
        return nil
    }
}
