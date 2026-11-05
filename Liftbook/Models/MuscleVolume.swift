import Foundation

/// Working sets and volume per muscle group for a calendar week.
struct MuscleVolume {
    var calendar: Calendar = .current

    struct Entry: Identifiable, Equatable, Sendable {
        let muscle: Muscle
        let sets: Int
        /// Kilograms of weight × reps.
        let volume: Double
        var id: Muscle { muscle }
    }

    enum Measure: String, CaseIterable, Identifiable, Sendable {
        case sets = "Sets", volume = "Volume"
        var id: String { rawValue }
    }

    /// The week (per the calendar's first weekday) containing `date`.
    func week(containing date: Date) -> DateInterval {
        calendar.dateInterval(of: .weekOfYear, for: date) ?? DateInterval(start: date, duration: 7 * 86_400)
    }

    func week(_ week: DateInterval, offsetBy weeks: Int) -> DateInterval {
        let start = calendar.date(byAdding: .weekOfYear, value: weeks, to: week.start) ?? week.start
        return self.week(containing: start)
    }

    /// Completed working sets in finished workouts during `week`. Each set
    /// counts once for every primary muscle of its exercise. Sorted by sets.
    func entries(for week: DateInterval, in sessions: [WorkoutSession],
                 exercise: (String) -> LibraryExercise?) -> [Entry] {
        var sets: [Muscle: Int] = [:]
        var volume: [Muscle: Double] = [:]
        for session in sessions where session.endedAt != nil && week.contains(session.startedAt) && session.startedAt < week.end {
            for workoutExercise in session.exercises {
                guard let info = exercise(workoutExercise.exerciseID) else { continue }
                let done = workoutExercise.sets.filter { $0.isCompleted && $0.kind.isWorkingSet }
                guard !done.isEmpty else { continue }
                let countsVolume = info.type == .weightAndReps || info.type == .bodyweight
                let lifted = countsVolume ? done.reduce(0.0) { $0 + ($1.weight ?? 0) * Double($1.reps ?? 0) } : 0
                for muscle in Set(info.primaryMuscles) {
                    sets[muscle, default: 0] += done.count
                    volume[muscle, default: 0] += lifted
                }
            }
        }
        return sets.keys
            .map { Entry(muscle: $0, sets: sets[$0] ?? 0, volume: volume[$0] ?? 0) }
            .sorted { ($0.sets, $0.volume, $1.muscle.displayName) > ($1.sets, $1.volume, $0.muscle.displayName) }
    }
}
