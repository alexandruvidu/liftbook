import Foundation

/// What the user did for an exercise the last time they finished a workout
/// containing it.
struct PreviousPerformance: Equatable, Sendable {
    /// Completed sets from that workout, in order.
    let sets: [SetMeasurement]
    let date: Date
    /// The completed sets that weren't warm-ups.
    var workingSets: [SetMeasurement] = []
    /// The completed warm-up sets.
    var warmUpSets: [SetMeasurement] = []

    /// The previous set at the same position, if there was one.
    func set(at index: Int) -> SetMeasurement? {
        sets.indices.contains(index) ? sets[index] : nil
    }

    /// Last time's set for the row at `index`, matched within its group: the
    /// 2nd warm-up gets last time's 2nd warm-up, the 1st working set the 1st
    /// working set, so warm-ups never show working weights.
    func set(at index: Int, kinds: [SetKind]) -> SetMeasurement? {
        guard kinds.indices.contains(index) else { return nil }
        let isWarmUp = !kinds[index].isWorkingSet
        let rank = kinds[..<index].filter { $0.isWorkingSet != isWarmUp }.count
        let group = isWarmUp ? warmUpSets : workingSets
        return group.indices.contains(rank) ? group[rank] : nil
    }

    /// Looks through finished sessions (newest first wins) for the most recent
    /// one that has completed sets of the exercise.
    /// - Parameter machine: which machine's history to look at.
    static func find(exerciseID: String, machine: MachineFilter = .all, in sessions: [WorkoutSession],
                     excluding current: WorkoutSession? = nil) -> PreviousPerformance? {
        let finished = sessions
            .filter { $0.endedAt != nil && $0.sessionID != current?.sessionID }
            .sorted { $0.startedAt > $1.startedAt }
        for session in finished {
            let completed = session.orderedExercises
                .filter { $0.exerciseID == exerciseID && machine.matches($0) }
                .flatMap(\.orderedSets)
                .filter(\.isCompleted)
            if !completed.isEmpty {
                return PreviousPerformance(sets: completed.map(\.measurement), date: session.startedAt,
                                           workingSets: completed.filter { $0.kind.isWorkingSet }.map(\.measurement),
                                           warmUpSets: completed.filter { !$0.kind.isWorkingSet }.map(\.measurement))
            }
        }
        return nil
    }
}
