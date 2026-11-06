import Foundation

/// A kind of personal record.
enum RecordKind: String, CaseIterable, Sendable {
    case heaviestWeight, bestOneRepMax, bestSetVolume, mostReps

    var title: String {
        switch self {
        case .heaviestWeight: "Heaviest weight"
        case .bestOneRepMax: "Best estimated 1RM"
        case .bestSetVolume: "Best set volume"
        case .mostReps: "Most reps"
        }
    }

    /// Whether the value is a weight (shown in kg/lb) rather than a rep count.
    var isWeight: Bool { self != .mostReps }

    /// Record kinds that make sense for an exercise type.
    static func kinds(for type: ExerciseType) -> [RecordKind] {
        switch type {
        case .weightAndReps: [.heaviestWeight, .bestOneRepMax, .bestSetVolume, .mostReps]
        case .bodyweight: [.mostReps]
        case .assisted, .duration, .distance: []
        }
    }

    /// This record's value for one set, if it has one.
    func value(of set: SetMeasurement) -> Double? {
        switch self {
        case .heaviestWeight:
            guard let weight = set.weight, weight > 0, (set.reps ?? 0) > 0 else { return nil }
            return weight
        case .bestOneRepMax:
            guard let weight = set.weight, let reps = set.reps else { return nil }
            return PersonalRecords.estimatedOneRepMax(weight: weight, reps: reps)
        case .bestSetVolume:
            guard let weight = set.weight, let reps = set.reps, weight > 0, reps > 0 else { return nil }
            return weight * Double(reps)
        case .mostReps:
            guard let reps = set.reps, reps > 0 else { return nil }
            return Double(reps)
        }
    }

    /// "85 kg" or "12 reps".
    func formatted(_ value: Double, unit: WeightUnit) -> String {
        isWeight ? "\(SetMeasurement.number(value, unit: unit)) \(unit.symbol)" : "\(Int(value)) reps"
    }

    func best(in sets: [SetMeasurement]) -> Double? {
        sets.compactMap(value(of:)).max()
    }
}

/// An exercise's all-time bests across finished workouts.
enum PersonalRecords {
    struct Record: Equatable, Sendable {
        let kind: RecordKind
        let value: Double
        /// The set that holds the record and when it was done.
        let set: SetMeasurement
        let date: Date
    }

    /// Estimated one-rep max (Epley formula); nil without weight or reps.
    static func estimatedOneRepMax(weight: Double, reps: Int) -> Double? {
        guard weight > 0, reps > 0 else { return nil }
        return reps == 1 ? weight : weight * (1 + Double(reps) / 30)
    }

    /// Completed working sets of an exercise in finished sessions, with dates.
    static func loggedSets(of exerciseID: String, machine: MachineFilter = .all,
                           in sessions: [WorkoutSession]) -> [(set: SetMeasurement, date: Date)] {
        sessions.filter { $0.endedAt != nil }.flatMap { session in
            session.orderedExercises
                .filter { $0.exerciseID == exerciseID && machine.matches($0) }
                .flatMap(\.orderedSets)
                .filter { $0.isCompleted && $0.kind.isWorkingSet }
                .map { ($0.measurement, $0.completedAt ?? session.startedAt) }
        }
    }

    /// Records for an exercise; the earliest set wins a tie.
    static func records(for exerciseID: String, type: ExerciseType, machine: MachineFilter = .all,
                        in sessions: [WorkoutSession]) -> [Record] {
        let logged = loggedSets(of: exerciseID, machine: machine, in: sessions).sorted { $0.date < $1.date }
        return RecordKind.kinds(for: type).compactMap { kind in
            var best: Record?
            for item in logged {
                guard let value = kind.value(of: item.set) else { continue }
                if value > (best?.value ?? -1) {
                    best = Record(kind: kind, value: value, set: item.set, date: item.date)
                }
            }
            return best
        }
    }
}
