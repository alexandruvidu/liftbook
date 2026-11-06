import Foundation

/// Totals and new records for a finished workout.
struct WorkoutSummary: Equatable, Sendable {
    struct Record: Equatable, Hashable, Sendable {
        typealias Kind = RecordKind

        let exerciseID: String
        /// The machine the record was set on; records are per machine.
        var machineID: UUID? = nil
        let kind: Kind
        /// Kilograms for weights, a count for reps.
        let value: Double
    }

    let duration: TimeInterval
    /// Completed working sets (warm-ups don't count).
    let setCount: Int
    let exerciseCount: Int
    /// Sum of weight × reps over completed working sets, in kilograms.
    let volume: Double
    let records: [Record]

    /// - Parameters:
    ///   - history: other finished sessions to compare against for records.
    ///   - type: the exercise type for an exercise ID.
    init(session: WorkoutSession, history: [WorkoutSession], type: (String) -> ExerciseType) {
        let end = session.endedAt ?? .now
        duration = max(end.timeIntervalSince(session.startedAt), 0)

        let working = Self.workingSets(in: session)
        setCount = working.count
        exerciseCount = Set(working.map(\.exerciseID)).count
        volume = working.reduce(0) { total, item in
            guard Self.countsTowardsVolume(type(item.exerciseID)),
                  let weight = item.set.weight, let reps = item.set.reps else { return total }
            return total + weight * Double(reps)
        }

        let past = history
            .filter { $0.endedAt != nil && $0.sessionID != session.sessionID }
            .flatMap(Self.workingSets(in:))
        // Machines load differently, so each machine (and "no machine")
        // keeps its own records.
        var records: [Record] = []
        for group in Self.orderedUnique(working.map(\.group)) {
            let now = working.filter { $0.group == group }.map(\.set)
            let before = past.filter { $0.group == group }.map(\.set)
            // A first-ever session sets a baseline, not a record.
            guard !before.isEmpty else { continue }
            for kind in Self.summaryKinds(for: type(group.exerciseID)) {
                if let best = kind.best(in: now), best > (kind.best(in: before) ?? 0) {
                    records.append(Record(exerciseID: group.exerciseID, machineID: group.machineID, kind: kind, value: best))
                }
            }
        }
        self.records = records
    }

    private struct Group: Hashable {
        let exerciseID: String
        let machineID: UUID?
    }

    private struct LoggedSet {
        let exerciseID: String
        let machineID: UUID?
        let set: SetMeasurement

        var group: Group { Group(exerciseID: exerciseID, machineID: machineID) }
    }

    private static func workingSets(in session: WorkoutSession) -> [LoggedSet] {
        session.orderedExercises.flatMap { exercise in
            exercise.orderedSets
                .filter { $0.isCompleted && $0.kind.isWorkingSet }
                .map { LoggedSet(exerciseID: exercise.exerciseID, machineID: exercise.machineID, set: $0.measurement) }
        }
    }

    private static func countsTowardsVolume(_ type: ExerciseType) -> Bool {
        type == .weightAndReps || type == .bodyweight
    }

    /// The summary highlights fewer kinds than the exercise page shows.
    private static func summaryKinds(for type: ExerciseType) -> [RecordKind] {
        RecordKind.kinds(for: type).filter { $0 != .bestSetVolume && !(type == .weightAndReps && $0 == .mostReps) }
    }

    private static func orderedUnique<T: Hashable>(_ items: [T]) -> [T] {
        var seen = Set<T>()
        return items.filter { seen.insert($0).inserted }
    }
}
