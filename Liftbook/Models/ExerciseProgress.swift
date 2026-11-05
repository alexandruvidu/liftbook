import Foundation

/// One value per finished workout for an exercise, for progress charts.
enum ExerciseProgress {
    enum Metric: String, CaseIterable, Identifiable, Sendable {
        case oneRepMax, maxWeight, volume

        var id: String { rawValue }

        var title: String {
            switch self {
            case .oneRepMax: "Est. 1RM"
            case .maxWeight: "Max Weight"
            case .volume: "Volume"
            }
        }

        /// Sentence used for the chart's accessibility summary.
        var description: String {
            switch self {
            case .oneRepMax: "Best estimated one-rep max per workout"
            case .maxWeight: "Heaviest weight lifted per workout"
            case .volume: "Total volume (weight × reps) per workout"
            }
        }
    }

    struct Point: Identifiable, Equatable, Sendable {
        let date: Date
        /// Kilograms.
        let value: Double
        var id: Date { date }
    }

    /// Oldest first; workouts without a usable set for the metric are skipped.
    static func points(for exerciseID: String, metric: Metric, in sessions: [WorkoutSession]) -> [Point] {
        sessions
            .filter { $0.endedAt != nil }
            .sorted { $0.startedAt < $1.startedAt }
            .compactMap { session in
                let sets = session.orderedExercises
                    .filter { $0.exerciseID == exerciseID }
                    .flatMap(\.orderedSets)
                    .filter { $0.isCompleted && $0.kind.isWorkingSet }
                    .map(\.measurement)
                let value: Double? = switch metric {
                case .oneRepMax: RecordKind.bestOneRepMax.best(in: sets)
                case .maxWeight: RecordKind.heaviestWeight.best(in: sets)
                case .volume: sets.compactMap(RecordKind.bestSetVolume.value(of:)).reduce(0, +).nonZero
                }
                return value.map { Point(date: session.startedAt, value: $0) }
            }
    }

    /// Change from the first to the last point, or nil with fewer than two.
    static func change(in points: [Point]) -> Double? {
        guard points.count > 1, let first = points.first, let last = points.last else { return nil }
        return last.value - first.value
    }
}

private extension Double {
    var nonZero: Double? { self == 0 ? nil : self }
}
