import Foundation

extension WorkoutSession {
    /// The first set not checked off yet, in workout order, with its index in its exercise.
    var nextSetToLog: (exercise: WorkoutExercise, set: WorkoutSet, index: Int)? {
        for exercise in orderedExercises {
            for (index, set) in exercise.orderedSets.enumerated() where !set.isCompleted {
                return (exercise, set, index)
            }
        }
        return nil
    }

    /// Checks off the next set as its row's check button does: empty values
    /// come from `placeholder` (last time's set), a guessed machine counts as
    /// confirmed, and the rest timer starts. Returns false when there's no
    /// set left or it lacks a value the exercise needs.
    @discardableResult
    func logNextSet(type: (String) -> ExerciseType,
                    placeholder: (WorkoutExercise, Int) -> SetMeasurement?,
                    defaultRest: Int, at date: Date = .now) -> Bool {
        guard let next = nextSetToLog else { return false }
        let exerciseType = type(next.exercise.exerciseID)
        guard next.set.toggleCompleted(for: exerciseType, placeholder: placeholder(next.exercise, next.index), at: date) else {
            return false
        }
        next.exercise.machineConfirmed = true
        startRest(seconds: restSeconds(after: next.exercise, default: defaultRest), for: next.exercise.exerciseID, at: date)
        return true
    }
}

extension WorkoutActivityAttributes.ContentState {
    /// The Live Activity's view of `session`.
    init(session: WorkoutSession, name: (String) -> String, type: (String) -> ExerciseType,
         placeholder: (WorkoutExercise, Int) -> SetMeasurement?, unit: WeightUnit) {
        let sets = session.exercises.flatMap(\.sets)
        var exerciseName: String?
        var setLabel = "All sets done"
        var target = ""
        var canLog = false
        if let next = session.nextSetToLog {
            let exerciseType = type(next.exercise.exerciseID)
            let filled = next.set.measurement.filled(from: placeholder(next.exercise, next.index) ?? SetMeasurement(),
                                                     fields: exerciseType.fieldSpecs.map(\.field))
            exerciseName = name(next.exercise.exerciseID)
            setLabel = "Set \(next.index + 1) of \(next.exercise.sets.count)"
            canLog = filled.isComplete(for: exerciseType)
            target = canLog ? filled.formatted(for: exerciseType, unit: unit) : ""
        }
        self.init(workoutName: session.displayName, startedAt: session.startedAt, exerciseName: exerciseName,
                  setLabel: setLabel, target: target, canLog: canLog,
                  completedSets: sets.filter(\.isCompleted).count, totalSets: sets.count,
                  restEndsAt: session.restEndsAt,
                  restStartedAt: session.restEndsAt?.addingTimeInterval(-session.restDuration))
    }
}
