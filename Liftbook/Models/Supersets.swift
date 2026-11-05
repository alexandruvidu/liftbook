import Foundation

extension WorkoutSession {
    /// Consecutive runs of exercises that share a superset group, in order.
    /// Exercises not in a superset are left out.
    var supersets: [[WorkoutExercise]] {
        var result: [[WorkoutExercise]] = []
        var current: [WorkoutExercise] = []
        var currentGroup: UUID?
        for exercise in orderedExercises {
            if let group = exercise.supersetGroup, group == currentGroup {
                current.append(exercise)
                continue
            }
            if current.count > 1 { result.append(current) }
            current = exercise.supersetGroup == nil ? [] : [exercise]
            currentGroup = exercise.supersetGroup
        }
        if current.count > 1 { result.append(current) }
        return result
    }

    /// "Superset A", "Superset B"… letter for the exercise, if it's in one.
    func supersetLetter(for exercise: WorkoutExercise) -> String? {
        guard let index = supersets.firstIndex(where: { $0.contains { $0 === exercise } }) else { return nil }
        let letters = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ")
        return String(letters[index % letters.count])
    }

    /// The exercise right after this one, if any.
    func exercise(after exercise: WorkoutExercise) -> WorkoutExercise? {
        let ordered = orderedExercises
        guard let index = ordered.firstIndex(where: { $0 === exercise }), index + 1 < ordered.count else { return nil }
        return ordered[index + 1]
    }

    /// Whether the exercise is linked to the one after it.
    func isLinkedToNext(_ exercise: WorkoutExercise) -> Bool {
        guard let group = exercise.supersetGroup, let next = self.exercise(after: exercise) else { return false }
        return next.supersetGroup == group
    }

    /// Links the exercise with the next one, joining an existing superset on
    /// either side.
    func linkWithNext(_ exercise: WorkoutExercise) {
        guard let next = self.exercise(after: exercise) else { return }
        let group = exercise.supersetGroup ?? next.supersetGroup ?? UUID()
        let oldNextGroup = next.supersetGroup
        exercise.supersetGroup = group
        // Pull the rest of the next exercise's superset along with it.
        for other in orderedExercises where other.supersetGroup == oldNextGroup && oldNextGroup != nil {
            other.supersetGroup = group
        }
        next.supersetGroup = group
    }

    /// Splits the superset between this exercise and the next one.
    func unlinkFromNext(_ exercise: WorkoutExercise) {
        guard isLinkedToNext(exercise), let next = self.exercise(after: exercise) else { return }
        let newGroup = UUID()
        var after = false
        for other in orderedExercises {
            if other === next { after = true }
            if after && other.supersetGroup == exercise.supersetGroup { other.supersetGroup = newGroup }
        }
        cleanUpSupersets()
    }

    /// Removes groups that only contain a single exercise.
    func cleanUpSupersets() {
        let linked = Set(supersets.flatMap { $0 }.map(ObjectIdentifier.init))
        for exercise in exercises where exercise.supersetGroup != nil && !linked.contains(ObjectIdentifier(exercise)) {
            exercise.supersetGroup = nil
        }
    }

    /// Rest after a set: none between exercises of a superset, so the timer
    /// only runs after the last exercise in the round.
    func restSeconds(after exercise: WorkoutExercise, default defaultSeconds: Int) -> Int {
        isLinkedToNext(exercise) ? 0 : exercise.effectiveRestSeconds(default: defaultSeconds)
    }
}

extension WorkoutSession {
    /// Deletes an exercise and its sets, renumbering the rest.
    func removeExercise(_ exercise: WorkoutExercise) {
        exercises.removeAll { $0 === exercise }
        exercise.modelContext?.delete(exercise)
        for (index, remaining) in orderedExercises.enumerated() { remaining.position = index }
        cleanUpSupersets()
        if restExerciseID == exercise.exerciseID { stopRest() }
    }
}
