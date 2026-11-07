import Foundation
import SwiftData
import Testing
@testable import Liftbook

/// The stored models exactly as they were before machines and media
/// (commit 94a892c): the shape of the owner's real data on the phone.
/// Only stored properties matter here; behaviour lives in the app.
enum StoreV1 {
    @Model final class CustomExercise {
        @Attribute(.unique) var exerciseID: String
        var name: String
        var primaryMuscleIDs: [String]
        var secondaryMuscleIDs: [String]
        var equipmentID: String
        var typeID: String
        var details: String
        var createdAt: Date
        init(exerciseID: String, name: String) {
            self.exerciseID = exerciseID
            self.name = name
            primaryMuscleIDs = ["chest"]
            secondaryMuscleIDs = []
            equipmentID = "barbell"
            typeID = "weightAndReps"
            details = ""
            createdAt = .now
        }
    }

    @Model final class RoutineFolder {
        @Attribute(.unique) var folderID: UUID
        var name: String
        var sortIndex: Int
        @Relationship(deleteRule: .nullify, inverse: \Routine.folder)
        var routines: [Routine] = []
        init(name: String) {
            folderID = UUID()
            self.name = name
            sortIndex = 0
        }
    }

    @Model final class Routine {
        @Attribute(.unique) var routineID: UUID
        var name: String
        var notes: String
        var folder: RoutineFolder?
        @Relationship(deleteRule: .cascade, inverse: \RoutineEntry.routine)
        var entries: [RoutineEntry] = []
        var createdAt: Date
        var updatedAt: Date
        init(name: String) {
            routineID = UUID()
            self.name = name
            notes = ""
            createdAt = .now
            updatedAt = .now
        }
    }

    @Model final class RoutineEntry {
        var exerciseID: String
        var position: Int
        var setCount: Int
        var routine: Routine?
        init(exerciseID: String, position: Int, setCount: Int) {
            self.exerciseID = exerciseID
            self.position = position
            self.setCount = setCount
        }
    }

    @Model final class WorkoutSession {
        @Attribute(.unique) var sessionID: UUID
        var name: String
        var startedAt: Date
        var endedAt: Date?
        var notes: String
        var routineID: UUID?
        var restEndsAt: Date? = nil
        var restDuration: Double = 0
        var restExerciseID: String? = nil
        @Relationship(deleteRule: .cascade, inverse: \WorkoutExercise.session)
        var exercises: [WorkoutExercise] = []
        init(name: String, startedAt: Date) {
            sessionID = UUID()
            self.name = name
            self.startedAt = startedAt
            notes = ""
        }
    }

    @Model final class WorkoutExercise {
        var exerciseID: String
        var position: Int
        var notes: String
        var restSeconds: Int? = nil
        var supersetGroup: UUID? = nil
        var session: WorkoutSession?
        @Relationship(deleteRule: .cascade, inverse: \WorkoutSet.exercise)
        var sets: [WorkoutSet] = []
        init(exerciseID: String, position: Int) {
            self.exerciseID = exerciseID
            self.position = position
            notes = ""
        }
    }

    @Model final class WorkoutSet {
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
        init(position: Int, weight: Double, reps: Int) {
            self.position = position
            kindID = "normal"
            self.weight = weight
            self.reps = reps
            isCompleted = true
        }
    }

    @Model final class BodyMetric {
        @Attribute(.unique) var metricID: String
        var name: String
        var kindID: String
        var sortIndex: Int
        var isBuiltIn: Bool
        init(metricID: String, name: String) {
            self.metricID = metricID
            self.name = name
            kindID = "weight"
            sortIndex = 0
            isBuiltIn = true
        }
    }

    @Model final class BodyMeasurement {
        var metricID: String
        var value: Double
        var date: Date
        init(metricID: String, value: Double) {
            self.metricID = metricID
            self.value = value
            date = .now
        }
    }

    @Model final class ProgressPhoto {
        @Attribute(.unique) var photoID: UUID
        var date: Date
        var fileName: String
        init(fileName: String) {
            photoID = UUID()
            date = .now
            self.fileName = fileName
        }
    }

    static let schema = Schema([CustomExercise.self, RoutineFolder.self, Routine.self, RoutineEntry.self,
                                WorkoutSession.self, WorkoutExercise.self, WorkoutSet.self,
                                BodyMetric.self, BodyMeasurement.self, ProgressPhoto.self])
}

@MainActor
struct StoreUpgradeTests {
    /// A store written before machines and media opens with the current
    /// schema, with every workout, set, routine and measurement intact.
    @Test func storeFromBeforeMachinesOpensWithEverything() throws {
        let url = URL.temporaryDirectory.appending(path: "upgrade-\(UUID().uuidString).store")
        let start = Date(timeIntervalSince1970: 1_790_000_000)
        do {
            let old = try ModelContainer(for: StoreV1.schema,
                                         configurations: ModelConfiguration(schema: StoreV1.schema, url: url))
            let context = ModelContext(old)
            let session = StoreV1.WorkoutSession(name: "Back Day", startedAt: start)
            session.endedAt = start.addingTimeInterval(3600)
            context.insert(session)
            let exercise = StoreV1.WorkoutExercise(exerciseID: "t-bar-row", position: 0)
            session.exercises.append(exercise)
            exercise.sets.append(StoreV1.WorkoutSet(position: 0, weight: 40, reps: 10))
            let routine = StoreV1.Routine(name: "Pull")
            context.insert(routine)
            routine.entries.append(StoreV1.RoutineEntry(exerciseID: "t-bar-row", position: 0, setCount: 3))
            context.insert(StoreV1.BodyMeasurement(metricID: "body-weight", value: 80))
            try context.save()
        }

        let current = ModelContext(Persistence.makeContainer(url: url))
        let sessions = try current.fetch(FetchDescriptor<WorkoutSession>())
        #expect(sessions.map(\.name) == ["Back Day"])
        let exercise = try #require(sessions.first?.exercises.first)
        #expect(exercise.machineID == nil)
        #expect(exercise.machineConfirmed)
        #expect(exercise.sets.first?.measurement == SetMeasurement(weight: 40, reps: 10))
        let entry = try #require(try current.fetch(FetchDescriptor<Routine>()).first?.entries.first)
        #expect(entry.machineID == nil)
        #expect(entry.setCount == 3)
        #expect(try current.fetch(FetchDescriptor<BodyMeasurement>()).map(\.value) == [80])
        #expect(try current.fetch(FetchDescriptor<Machine>()).isEmpty)
        #expect(try current.fetch(FetchDescriptor<ExerciseMedia>()).isEmpty)
    }
}
