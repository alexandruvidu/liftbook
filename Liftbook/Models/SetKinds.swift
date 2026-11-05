import Foundation

extension SetKind {
    var displayName: String {
        switch self {
        case .normal: "Normal"
        case .warmUp: "Warm-up"
        case .drop: "Drop Set"
        case .failure: "To Failure"
        }
    }

    /// One-letter tag shown instead of a set number; nil for normal sets.
    var tag: String? {
        switch self {
        case .normal: nil
        case .warmUp: "W"
        case .drop: "D"
        case .failure: "F"
        }
    }

    var explanation: String {
        switch self {
        case .normal: "A regular working set."
        case .warmUp: "A lighter set to prepare. Not counted in volume or records."
        case .drop: "Straight after the previous set, with less weight and no rest."
        case .failure: "A working set taken until you couldn't do another rep."
        }
    }

    /// Whether the set counts towards volume, set totals and records.
    var isWorkingSet: Bool { self != .warmUp }
}

extension WorkoutExercise {
    /// Label for each ordered set: normal sets are numbered 1, 2, 3…; other
    /// kinds show their tag instead, e.g. ["W", "1", "2", "D", "F"].
    var setLabels: [String] {
        SetKind.labels(for: orderedSets.map(\.kind))
    }
}

extension SetKind {
    static func labels(for kinds: [SetKind]) -> [String] {
        var number = 0
        return kinds.map { kind in
            if let tag = kind.tag { return tag }
            number += 1
            return "\(number)"
        }
    }
}
