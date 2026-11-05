import Foundation

/// Totals and new records for a finished workout.
struct WorkoutSummary: Equatable, Sendable {
    struct Record: Equatable, Hashable, Sendable {
        enum Kind: String, Sendable {
            case heaviestWeight, bestOneRepMax, mostReps

            var title: String {
                switch self {
                case .heaviestWeight: "Heaviest weight"
                case .bestOneRepMax: "Best estimated 1RM"
                case .mostReps: "Most reps"
                }
            }
        }

        let exerciseID: String
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

    /// Estimated one-rep max (Epley formula); nil without weight or reps.
    static func estimatedOneRepMax(weight: Double, reps: Int) -> Double? {
        guard weight > 0, reps > 0 else { return nil }
        return reps == 1 ? weight : weight * (1 + Double(reps) / 30)
    }

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
        var records: [Record] = []
        for exerciseID in Self.orderedUnique(working.map(\.exerciseID)) {
            let now = working.filter { $0.exerciseID == exerciseID }.map(\.set)
            let before = past.filter { $0.exerciseID == exerciseID }.map(\.set)
            // A first-ever session sets a baseline, not a record.
            guard !before.isEmpty else { continue }
            for kind in Self.recordKinds(for: type(exerciseID)) {
                if let best = Self.best(kind, in: now), best > (Self.best(kind, in: before) ?? 0) {
                    records.append(Record(exerciseID: exerciseID, kind: kind, value: best))
                }
            }
        }
        self.records = records
    }

    private struct LoggedSet {
        let exerciseID: String
        let set: SetMeasurement
    }

    private static func workingSets(in session: WorkoutSession) -> [LoggedSet] {
        session.orderedExercises.flatMap { exercise in
            exercise.orderedSets
                .filter { $0.isCompleted && $0.kind.isWorkingSet }
                .map { LoggedSet(exerciseID: exercise.exerciseID, set: $0.measurement) }
        }
    }

    private static func countsTowardsVolume(_ type: ExerciseType) -> Bool {
        type == .weightAndReps || type == .bodyweight
    }

    private static func recordKinds(for type: ExerciseType) -> [Record.Kind] {
        switch type {
        case .weightAndReps: [.heaviestWeight, .bestOneRepMax]
        case .bodyweight: [.mostReps]
        case .assisted, .duration, .distance: []
        }
    }

    private static func best(_ kind: Record.Kind, in sets: [SetMeasurement]) -> Double? {
        let values: [Double] = sets.compactMap { set in
            switch kind {
            case .heaviestWeight: set.reps.flatMap { $0 > 0 ? set.weight : nil }
            case .bestOneRepMax: set.weight.flatMap { w in set.reps.flatMap { estimatedOneRepMax(weight: w, reps: $0) } }
            case .mostReps: set.reps.map(Double.init)
            }
        }
        return values.max()
    }

    private static func orderedUnique(_ ids: [String]) -> [String] {
        var seen = Set<String>()
        return ids.filter { seen.insert($0).inserted }
    }
}
