import Foundation

/// Builds warm-up sets that ramp up to a working weight.
enum WarmUpCalculator {
    struct Step: Equatable, Sendable {
        /// Display-unit weight (kg or lb).
        let weight: Double
        let reps: Int
        /// Share of the working weight, 0...1 (0 for the empty bar).
        let percent: Double
    }

    /// (share of working weight, reps); the empty bar comes first.
    static let scheme: [(percent: Double, reps: Int)] = [(0.4, 5), (0.6, 3), (0.8, 2)]
    static let barReps = 10

    /// Warm-ups for `working` on a `bar`, each rounded down to a weight the
    /// smallest plate pair can make. Steps at or below the bar, at or above
    /// the working weight, or repeating the previous weight are left out.
    static func steps(working: Double, bar: Double, smallestPlate: Double) -> [Step] {
        guard working > bar else { return [] }
        let increment = max(smallestPlate * 2, 0.01)
        var steps = [Step(weight: bar, reps: barReps, percent: 0)]
        for (percent, reps) in scheme {
            let raw = working * percent
            let rounded = bar + ((raw - bar) / increment).rounded(.down) * increment
            let weight = (rounded * 100).rounded() / 100
            guard weight > (steps.last?.weight ?? 0), weight < working else { continue }
            steps.append(Step(weight: weight, reps: reps, percent: percent))
        }
        return steps
    }
}

extension WorkoutExercise {
    /// The weight of the first normal set with one, in kilograms.
    var workingWeight: Double? {
        orderedSets.first { $0.kind == .normal && ($0.weight ?? 0) > 0 }?.weight
    }

    /// Replaces any warm-up sets with `weights` (kilograms) × reps, placed
    /// before the working sets.
    func setWarmUps(_ warmUps: [(kilograms: Double, reps: Int)]) {
        for old in sets where old.kind == .warmUp {
            sets.removeAll { $0 === old }
            old.modelContext?.delete(old)
        }
        let working = orderedSets
        for (index, set) in working.enumerated() { set.position = warmUps.count + index }
        for (index, warmUp) in warmUps.enumerated() {
            sets.append(WorkoutSet(position: index, kind: .warmUp,
                                   measurement: SetMeasurement(weight: warmUp.kilograms, reps: warmUp.reps)))
        }
    }
}
