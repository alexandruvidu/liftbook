import Foundation
import SwiftData

/// Builds new workout sessions. Callers insert the result into a ModelContext.
enum WorkoutStarter {
    /// A blank session named after the time of day, e.g. "Evening Workout".
    static func emptyWorkout(at date: Date = .now, calendar: Calendar = .current) -> WorkoutSession {
        WorkoutSession(name: defaultName(at: date, calendar: calendar), startedAt: date)
    }

    /// A session pre-filled with the routine's exercises, order and set counts.
    /// - Parameters:
    ///   - machines: every machine, to check the routine's choices still exist.
    ///   - history: finished workouts, for the machine used last time.
    static func workout(from routine: Routine, at date: Date = .now,
                        machines: [Machine] = [], history: [WorkoutSession] = []) -> WorkoutSession {
        let session = WorkoutSession(name: routine.name, startedAt: date, routineID: routine.routineID)
        for entry in routine.orderedEntries {
            session.addExercises([entry.exerciseID], setCount: entry.setCount)
            let exercise = session.orderedExercises.last!
            let known = Set(machines.of(entry.exerciseID).map(\.machineID))
            if let chosen = entry.machineID, known.contains(chosen) {
                exercise.machineID = chosen
            } else if let last = Machine.lastUsed(exerciseID: entry.exerciseID, in: history), known.contains(last) {
                // A guess: shown as unconfirmed until the user checks it.
                exercise.machineID = last
                exercise.machineConfirmed = false
            }
        }
        return session
    }

    /// A new session with the same exercises, set types and values as a past
    /// one, ready to check off again. Supersets and rest times carry over.
    /// - Parameter machines: every machine; a machine that was deleted since
    ///   isn't carried over, and one that is shows as unconfirmed.
    static func repeating(_ past: WorkoutSession, at date: Date = .now, machines: [Machine] = []) -> WorkoutSession {
        let session = WorkoutSession(name: past.name, startedAt: date, routineID: past.routineID)
        var groups: [UUID: UUID] = [:]
        for (index, old) in past.orderedExercises.enumerated() {
            let exercise = WorkoutExercise(exerciseID: old.exerciseID, position: index)
            exercise.restSeconds = old.restSeconds
            if let id = old.machineID, machines.contains(where: { $0.machineID == id }) {
                exercise.machineID = id
                exercise.machineConfirmed = false
            }
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

    /// Deletes workouts in progress (to start another, or a leftover one) and
    /// cancels the end-of-rest alert they may have scheduled.
    @MainActor
    static func discard(_ sessions: [WorkoutSession], in context: ModelContext,
                        cancelAlerts: @MainActor () -> Void = RestAlerts.cancel) {
        cancelAlerts()
        for session in sessions {
            context.delete(session)
        }
        try? context.save()
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
