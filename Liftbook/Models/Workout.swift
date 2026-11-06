import Foundation
import SwiftData

/// One training session. In progress while `endedAt` is nil.
@Model
final class WorkoutSession {
    @Attribute(.unique) var sessionID: UUID
    var name: String
    var startedAt: Date
    var endedAt: Date?
    var notes: String
    /// The routine this workout was started from, if any.
    var routineID: UUID?
    /// When the running rest timer ends; nil when no timer is running.
    var restEndsAt: Date? = nil
    /// Length of the running rest timer in seconds, for its progress.
    var restDuration: Double = 0
    /// The exercise whose set started the running rest timer.
    var restExerciseID: String? = nil
    @Relationship(deleteRule: .cascade, inverse: \WorkoutExercise.session)
    var exercises: [WorkoutExercise] = []

    init(name: String, startedAt: Date = .now, routineID: UUID? = nil) {
        sessionID = UUID()
        self.name = name
        self.startedAt = startedAt
        notes = ""
        self.routineID = routineID
    }

    var isInProgress: Bool { endedAt == nil }

    var orderedExercises: [WorkoutExercise] {
        exercises.sorted { $0.position < $1.position }
    }

    /// Appends exercises, each with `setCount` empty sets.
    func addExercises(_ exerciseIDs: [String], setCount: Int = 1) {
        let start = (exercises.map(\.position).max() ?? -1) + 1
        for (offset, id) in exerciseIDs.enumerated() {
            let exercise = WorkoutExercise(exerciseID: id, position: start + offset)
            exercise.sets = (0..<max(setCount, 1)).map { WorkoutSet(position: $0) }
            exercises.append(exercise)
        }
    }
}

/// An exercise performed within a session.
@Model
final class WorkoutExercise {
    var exerciseID: String
    var position: Int
    var notes: String
    /// Rest after each set in seconds; nil uses the default, 0 turns it off.
    var restSeconds: Int? = nil
    /// Exercises in the same session with the same group form a superset.
    var supersetGroup: UUID? = nil
    /// The machine used, if the exercise has machines; nil = no specific one.
    var machineID: UUID? = nil
    /// False while the machine was picked automatically (from the routine or
    /// last time) and the user hasn't confirmed it yet.
    var machineConfirmed: Bool = true
    var session: WorkoutSession?
    @Relationship(deleteRule: .cascade, inverse: \WorkoutSet.exercise)
    var sets: [WorkoutSet] = []

    init(exerciseID: String, position: Int) {
        self.exerciseID = exerciseID
        self.position = position
        notes = ""
    }

    var orderedSets: [WorkoutSet] {
        sets.sorted { $0.position < $1.position }
    }
}

/// How a set counts towards the workout.
enum SetKind: String, Codable, CaseIterable, Identifiable, Sendable {
    case normal, warmUp, drop, failure

    var id: String { rawValue }
}

/// A single set within a workout exercise.
@Model
final class WorkoutSet {
    var position: Int
    var kindID: String
    var weight: Double?
    var reps: Int?
    var duration: Double?
    var distance: Double?
    var rpe: Double?
    var isCompleted: Bool
    var completedAt: Date?
    var exercise: WorkoutExercise?

    init(position: Int, kind: SetKind = .normal, measurement: SetMeasurement = SetMeasurement()) {
        self.position = position
        kindID = kind.rawValue
        weight = measurement.weight
        reps = measurement.reps
        duration = measurement.duration
        distance = measurement.distance
        isCompleted = false
    }

    var kind: SetKind {
        get { SetKind(rawValue: kindID) ?? .normal }
        set { kindID = newValue.rawValue }
    }

    var measurement: SetMeasurement {
        get { SetMeasurement(weight: weight, reps: reps, duration: duration, distance: distance) }
        set {
            weight = newValue.weight
            reps = newValue.reps
            duration = newValue.duration
            distance = newValue.distance
        }
    }
}

extension WorkoutExercise {
    /// Identity for SwiftUI lists that never changes, unlike `persistentModelID`,
    /// which switches from temporary to permanent on the first save.
    var stableID: ObjectIdentifier { ObjectIdentifier(self) }
}

extension WorkoutSet {
    /// See `WorkoutExercise.stableID`.
    var stableID: ObjectIdentifier { ObjectIdentifier(self) }
}
