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

    static func defaultName(at date: Date, calendar: Calendar = .current) -> String {
        switch calendar.component(.hour, from: date) {
        case 5..<12: "Morning Workout"
        case 12..<17: "Afternoon Workout"
        case 17..<22: "Evening Workout"
        default: "Night Workout"
        }
    }
}
