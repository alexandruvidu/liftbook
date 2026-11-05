import Foundation

/// Builds new workout sessions. Callers insert the result into a ModelContext.
enum WorkoutStarter {
    /// A blank session named after the time of day, e.g. "Evening Workout".
    static func emptyWorkout(at date: Date = .now, calendar: Calendar = .current) -> WorkoutSession {
        WorkoutSession(name: defaultName(at: date, calendar: calendar), startedAt: date)
    }

    /// A session pre-filled with the routine's exercises, order and set counts.
    static func workout(from routine: Routine, at date: Date = .now) -> WorkoutSession {
        let session = WorkoutSession(name: routine.name, startedAt: date, routineID: routine.routineID)
        for entry in routine.orderedEntries {
            session.addExercises([entry.exerciseID], setCount: entry.setCount)
        }
        return session
    }

    /// A new session with the same exercises, set types and values as a past
    /// one, ready to check off again. Supersets and rest times carry over.
    static func repeating(_ past: WorkoutSession, at date: Date = .now) -> WorkoutSession {
        let session = WorkoutSession(name: past.name, startedAt: date, routineID: past.routineID)
        var groups: [UUID: UUID] = [:]
        for (index, old) in past.orderedExercises.enumerated() {
            let exercise = WorkoutExercise(exerciseID: old.exerciseID, position: index)
            exercise.restSeconds = old.restSeconds
            exercise.supersetGroup = old.supersetGroup.map { group in
                if let mapped = groups[group] { return mapped }
                let fresh = UUID()
                groups[group] = fresh
                return fresh
            }
            let oldSets = old.orderedSets
            exercise.sets = oldSets.isEmpty
                ? [WorkoutSet(position: 0)]
                : oldSets.enumerated().map { WorkoutSet(position: $0, kind: $1.kind, measurement: $1.measurement) }
            session.exercises.append(exercise)
        }
        return session
    }

    static func defaultName(at date: Date, calendar: Calendar = .current) -> String {
        switch calendar.component(.hour, from: date) {
        case 5..<12: "Morning Workout"
        case 12..<17: "Afternoon Workout"
        case 17..<22: "Evening Workout"
        default: "Night Workout"
        }
    }
}
