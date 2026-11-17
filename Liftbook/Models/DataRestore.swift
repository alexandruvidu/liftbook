import Foundation
import SwiftData

/// Puts a JSON backup (`DataExport.Backup`) back: everything in the store is
/// replaced by the backup's contents, keeping their IDs so workouts still
/// point at their routines and machines.
enum DataRestore {
    enum Failure: Error, LocalizedError {
        case notABackup
        case newerVersion(Int)

        var errorDescription: String? {
            switch self {
            case .notABackup: "This file isn't a Liftbook backup."
            case .newerVersion: "This backup was made by a newer version of Liftbook. Update the app first."
            }
        }
    }

    struct Summary: Equatable {
        var workouts: Int
        var routines: Int
    }

    /// Reads a backup file without touching any data.
    static func decode(_ data: Data) throws -> DataExport.Backup {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let backup: DataExport.Backup
        do {
            backup = try decoder.decode(DataExport.Backup.self, from: data)
        } catch {
            throw Failure.notABackup
        }
        guard backup.format == DataExport.Backup.formatName else { throw Failure.notABackup }
        guard backup.version <= DataExport.Backup.currentVersion else { throw Failure.newerVersion(backup.version) }
        return backup
    }

    /// Deletes everything in the store and inserts the backup's contents.
    @MainActor
    @discardableResult
    static func restore(_ backup: DataExport.Backup, into context: ModelContext,
                        defaults: UserDefaults = AppSettings.store) throws -> Summary {
        try deleteEverything(in: context)
        // Saved in between: the backup reuses the deleted rows' unique IDs.
        try context.save()

        for record in backup.customExercises {
            let exercise = CustomExercise(draft: ExerciseDraft(), createdAt: backup.exportedAt)
            exercise.exerciseID = record.id
            exercise.name = record.name
            exercise.equipmentID = record.equipment
            exercise.typeID = record.type
            exercise.details = record.details
            exercise.primaryMuscleIDs = record.primaryMuscles
            exercise.secondaryMuscleIDs = record.secondaryMuscles
            context.insert(exercise)
        }

        var folders: [UUID: RoutineFolder] = [:]
        for record in backup.folders {
            let folder = RoutineFolder(name: record.name, sortIndex: record.sortIndex)
            folder.folderID = record.id
            context.insert(folder)
            folders[record.id] = folder
        }

        for record in backup.routines {
            let routine = Routine(name: record.name, createdAt: backup.exportedAt)
            routine.routineID = record.id
            routine.notes = record.notes
            context.insert(routine)
            routine.folder = record.folderID.flatMap { folders[$0] }
            routine.entries = record.exercises.enumerated().map { index, entry in
                let saved = RoutineEntry(exerciseID: entry.exerciseID, position: index, setCount: entry.sets)
                saved.machineID = entry.machineID
                return saved
            }
        }

        for record in backup.workouts {
            let session = WorkoutSession(name: record.name, startedAt: record.startedAt, routineID: record.routineID)
            session.sessionID = record.id
            session.notes = record.notes
            session.endedAt = record.endedAt
            context.insert(session)
            session.exercises = record.exercises.enumerated().map { index, item in
                let exercise = WorkoutExercise(exerciseID: item.exerciseID, position: index)
                exercise.notes = item.notes
                exercise.machineID = item.machineID
                exercise.restSeconds = item.restSeconds
                exercise.supersetGroup = item.supersetGroup
                exercise.sets = item.sets.enumerated().map { position, set in
                    let saved = WorkoutSet(position: position, kind: SetKind(rawValue: set.type) ?? .normal,
                                           measurement: SetMeasurement(weight: set.weightKg, reps: set.reps,
                                                                       duration: set.seconds, distance: set.meters))
                    saved.rpe = set.rpe
                    saved.isCompleted = set.done
                    saved.completedAt = set.completedAt
                    return saved
                }
                return exercise
            }
        }

        let builtIns: Set = [BodyMetric.bodyWeightID, BodyMetric.bodyFatID]
        for record in backup.bodyMetrics {
            context.insert(BodyMetric(metricID: record.id, name: record.name,
                                      kind: BodyMetricKind(rawValue: record.kind) ?? .number,
                                      sortIndex: record.sortIndex, isBuiltIn: builtIns.contains(record.id)))
        }
        for record in backup.bodyMeasurements {
            context.insert(BodyMeasurement(metricID: record.metricID, value: record.value, date: record.date))
        }

        // The backup lists machines oldest first and has no dates; one
        // second apart keeps that order (machine lists sort by `createdAt`).
        let machines = backup.machines ?? []
        for (index, record) in machines.enumerated() {
            let machine = Machine(exerciseID: record.exerciseID, name: record.name, location: record.location,
                                  createdAt: backup.exportedAt.addingTimeInterval(TimeInterval(index - machines.count)))
            machine.machineID = record.id
            machine.photoFileName = record.photoFileName
            context.insert(machine)
        }

        for record in backup.media ?? [] {
            let media = ExerciseMedia(exerciseID: record.exerciseID, kind: MediaKind(rawValue: record.kind) ?? .photo,
                                      source: MediaSource(rawValue: record.source) ?? .own,
                                      fileName: record.fileName, position: record.position)
            media.mediaID = record.id
            context.insert(media)
        }

        for record in backup.progressPhotos ?? [] {
            context.insert(ProgressPhoto(photoID: record.id, date: record.date, fileName: record.fileName))
        }

        try context.save()
        // Older backups have no settings; the current ones stay.
        backup.settings?.apply(to: defaults)
        BodyMetrics.ensureBuiltIns(in: context)
        return Summary(workouts: backup.workouts.count, routines: backup.routines.count)
    }

    /// Removes every stored record. Child rows go with their parents.
    @MainActor
    private static func deleteEverything(in context: ModelContext) throws {
        func deleteAll<T: PersistentModel>(_ type: T.Type) throws {
            for item in try context.fetch(FetchDescriptor<T>()) { context.delete(item) }
        }
        try deleteAll(WorkoutSession.self)
        try deleteAll(Routine.self)
        try deleteAll(RoutineFolder.self)
        try deleteAll(CustomExercise.self)
        try deleteAll(BodyMeasurement.self)
        try deleteAll(BodyMetric.self)
        try deleteAll(Machine.self)
        try deleteAll(ExerciseMedia.self)
        try deleteAll(ProgressPhoto.self)
    }
}
