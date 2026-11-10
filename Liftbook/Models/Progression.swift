import Foundation

/// Double progression: work up to the top of a rep range at one weight, then
/// add weight and start again from the bottom of the range.
enum Progression {
    struct Suggestion: Equatable, Sendable {
        /// Kilograms.
        let weight: Double
        let reps: Int
        let increasesWeight: Bool
        let reason: String
    }

    static let ranges: [ClosedRange<Int>] = [3...5, 5...8, 6...10, 8...12, 10...15, 12...20]
    static let defaultRange = 8...12

    static func rangeKey(_ exerciseID: String) -> String { "progression.range.\(exerciseID)" }

    static func encode(_ range: ClosedRange<Int>) -> String { "\(range.lowerBound)-\(range.upperBound)" }

    static func decode(_ text: String?) -> ClosedRange<Int>? {
        guard let parts = text?.split(separator: "-").compactMap({ Int($0) }), parts.count == 2,
              parts[0] > 0, parts[0] <= parts[1] else { return nil }
        return parts[0]...parts[1]
    }

    /// Weight to add, in kilograms: bigger jumps for lower-body lifts.
    static func increment(for exercise: LibraryExercise, unit: WeightUnit) -> Double {
        let lowerBody: Set<Muscle> = [.quads, .glutes, .hamstrings, .adductors, .abductors]
        let isLower = !lowerBody.isDisjoint(with: exercise.primaryMuscles)
        switch unit {
        case .kilograms: return isLower ? 5 : 2.5
        case .pounds: return unit.kilograms(fromDisplay: isLower ? 10 : 5)
        }
    }

    /// What to aim for next time, from last time's completed working sets.
    /// Nil when there's nothing to go on or the type has no weight to add.
    static func suggestion(lastSets: [SetMeasurement], exercise: LibraryExercise,
                           range: ClosedRange<Int>, unit: WeightUnit) -> Suggestion? {
        let sets = lastSets.filter { ($0.reps ?? 0) > 0 }
        guard !sets.isEmpty else { return nil }
        let reps = sets.compactMap(\.reps)
        let lowest = reps.min() ?? 0

        switch exercise.type {
        case .weightAndReps:
            guard let weight = sets.compactMap(\.weight).max(), weight > 0 else { return nil }
            if lowest >= range.upperBound {
                let increment = increment(for: exercise, unit: unit)
                return Suggestion(weight: weight + increment, reps: range.lowerBound, increasesWeight: true,
                                  reason: "You did \(lowest)+ reps on every set last time.")
            }
            let target = min(max(lowest + 1, range.lowerBound), range.upperBound)
            return Suggestion(weight: weight, reps: target, increasesWeight: false,
                              reason: "Same weight; aim for \(target) reps on each set.")
        case .bodyweight:
            let target = lowest + 1
            return Suggestion(weight: 0, reps: target, increasesWeight: false,
                              reason: "Beat last time's \(lowest) reps.")
        case .assisted, .duration, .distance:
            return nil
        }
    }
}

extension WorkoutExercise {
    /// Fills sets that aren't checked off and have no values yet.
    func apply(_ suggestion: Progression.Suggestion, type: ExerciseType) {
        for set in orderedSets where !set.isCompleted && set.kind != .warmUp && set.measurement == SetMeasurement() {
            set.measurement = SetMeasurement(weight: type == .weightAndReps ? suggestion.weight : nil,
                                             reps: suggestion.reps)
        }
    }
}
