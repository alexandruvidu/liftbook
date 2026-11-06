import Foundation
import SwiftData

/// Exports workouts as CSV (one row per set) and everything as a JSON backup.
enum DataExport {
    static let csvHeader = ["date", "workout", "duration_min", "exercise", "exercise_id", "machine", "set", "set_type",
                            "weight_kg", "reps", "seconds", "meters", "rpe", "done", "workout_notes", "exercise_notes"]

    static func isoDate(_ date: Date) -> String {
        date.formatted(.iso8601)
    }

    static func number(_ value: Double?) -> String {
        guard let value else { return "" }
        return String(format: "%g", value)
    }

    /// Finished workouts, oldest first, one row per set.
    /// Every finished workout, one row per set, oldest first.
    static func workoutsCSV(_ sessions: [WorkoutSession], catalog: ExerciseCatalog, machines: [Machine] = []) -> String {
        let finished = sessions.filter { $0.endedAt != nil }.sorted { $0.startedAt < $1.startedAt }
        let lines = [CSV.line(csvHeader)] + finished.flatMap { rows(for: $0, catalog: catalog, machines: machines) }
        return lines.joined(separator: "\n") + "\n"
    }

    /// One workout, with the same columns as the full export.
    static func workoutCSV(_ session: WorkoutSession, catalog: ExerciseCatalog, machines: [Machine] = []) -> String {
        ([CSV.line(csvHeader)] + rows(for: session, catalog: catalog, machines: machines)).joined(separator: "\n") + "\n"
    }

    /// "Liftbook-2026-11-04-Back-Day-Heavy.csv": the date, then the name with
    /// anything but letters and digits turned into single dashes.
    static func fileName(for session: WorkoutSession, calendar: Calendar = .current) -> String {
        let c = calendar.dateComponents([.year, .month, .day], from: session.startedAt)
        let day = String(format: "%04d-%02d-%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0)
        let words = session.name.split { !$0.isLetter && !$0.isNumber }.joined(separator: "-")
        return "Liftbook-\(day)\(words.isEmpty ? "" : "-" + words).csv"
    }

    private static func rows(for session: WorkoutSession, catalog: ExerciseCatalog, machines: [Machine]) -> [String] {
        session.orderedExercises.flatMap { exercise in
            exercise.orderedSets.enumerated().map { index, set in
                CSV.line([
                    isoDate(session.startedAt), session.name, "\(session.durationMinutes)",
                    catalog.name(for: exercise.exerciseID), exercise.exerciseID,
                    machines.name(for: exercise.machineID) ?? "", "\(index + 1)", set.kind.rawValue,
                    number(set.weight), set.reps.map(String.init) ?? "", number(set.duration), number(set.distance),
                    number(set.rpe), set.isCompleted ? "yes" : "no", session.notes, exercise.notes,
                ])
            }
        }
    }

    // MARK: JSON backup

    struct Backup: Codable {
        var format = "liftbook-backup"
        var version = 1
        var exportedAt: Date
        var customExercises: [CustomExerciseRecord]
        var folders: [FolderRecord]
        var routines: [RoutineRecord]
        var workouts: [WorkoutRecord]
        var bodyMetrics: [BodyMetricRecord]
        var bodyMeasurements: [BodyMeasurementRecord]
        /// Added later; missing in older backups.
        var machines: [MachineRecord]?
        /// Photo and video records (not the files themselves).
        var media: [MediaRecord]?
    }

    struct MachineRecord: Codable {
        var id: UUID
        var exerciseID, name, location: String
        var photoFileName: String?
    }

    struct MediaRecord: Codable {
        var id: UUID
        var exerciseID, kind, source, fileName: String
        var position: Int
    }

    struct CustomExerciseRecord: Codable {
        var id, name, equipment, type, details: String
        var primaryMuscles, secondaryMuscles: [String]
    }

    struct FolderRecord: Codable { var id: UUID; var name: String; var sortIndex: Int }

    struct RoutineRecord: Codable {
        var id: UUID
        var name, notes: String
        var folderID: UUID?
        var exercises: [Entry]
        struct Entry: Codable { var exerciseID: String; var sets: Int; var machineID: UUID? }
    }

    struct WorkoutRecord: Codable {
        var id: UUID
        var name, notes: String
        var startedAt: Date
        var endedAt: Date?
        var routineID: UUID?
        var exercises: [Exercise]
        struct Exercise: Codable {
            var exerciseID, notes: String
            var machineID: UUID?
            var restSeconds: Int?
            var supersetGroup: UUID?
            var sets: [SetRecord]
        }
        struct SetRecord: Codable {
            var type: String
            var weightKg: Double?, reps: Int?, seconds: Double?, meters: Double?, rpe: Double?
            var done: Bool
            var completedAt: Date?
        }
    }

    struct BodyMetricRecord: Codable { var id, name, kind: String; var sortIndex: Int }
    struct BodyMeasurementRecord: Codable { var metricID: String; var value: Double; var date: Date }

    @MainActor
    static func backup(from context: ModelContext, now: Date = .now) throws -> Backup {
        let customs = try context.fetch(FetchDescriptor<CustomExercise>())
        let folders = try context.fetch(FetchDescriptor<RoutineFolder>())
        let routines = try context.fetch(FetchDescriptor<Routine>())
        let sessions = try context.fetch(FetchDescriptor<WorkoutSession>(sortBy: [SortDescriptor(\.startedAt)]))
        let metrics = try context.fetch(FetchDescriptor<BodyMetric>())
        let measurements = try context.fetch(FetchDescriptor<BodyMeasurement>(sortBy: [SortDescriptor(\.date)]))
        let machines = try context.fetch(FetchDescriptor<Machine>(sortBy: [SortDescriptor(\.createdAt)]))
        let media = try context.fetch(FetchDescriptor<ExerciseMedia>())
        return Backup(
            exportedAt: now,
            customExercises: customs.map {
                CustomExerciseRecord(id: $0.exerciseID, name: $0.name, equipment: $0.equipmentID, type: $0.typeID,
                                     details: $0.details, primaryMuscles: $0.primaryMuscleIDs,
                                     secondaryMuscles: $0.secondaryMuscleIDs)
            },
            folders: folders.map { FolderRecord(id: $0.folderID, name: $0.name, sortIndex: $0.sortIndex) },
            routines: routines.map { routine in
                RoutineRecord(id: routine.routineID, name: routine.name, notes: routine.notes,
                              folderID: routine.folder?.folderID,
                              exercises: routine.orderedEntries.map { .init(exerciseID: $0.exerciseID, sets: $0.setCount, machineID: $0.machineID) })
            },
            workouts: sessions.map { session in
                WorkoutRecord(id: session.sessionID, name: session.name, notes: session.notes,
                              startedAt: session.startedAt, endedAt: session.endedAt, routineID: session.routineID,
                              exercises: session.orderedExercises.map { exercise in
                                  .init(exerciseID: exercise.exerciseID, notes: exercise.notes,
                                        machineID: exercise.machineID,
                                        restSeconds: exercise.restSeconds, supersetGroup: exercise.supersetGroup,
                                        sets: exercise.orderedSets.map { set in
                                            .init(type: set.kind.rawValue, weightKg: set.weight, reps: set.reps,
                                                  seconds: set.duration, meters: set.distance, rpe: set.rpe,
                                                  done: set.isCompleted, completedAt: set.completedAt)
                                        })
                              })
            },
            bodyMetrics: metrics.map { BodyMetricRecord(id: $0.metricID, name: $0.name, kind: $0.kindID, sortIndex: $0.sortIndex) },
            bodyMeasurements: measurements.map { BodyMeasurementRecord(metricID: $0.metricID, value: $0.value, date: $0.date) },
            machines: machines.map {
                MachineRecord(id: $0.machineID, exerciseID: $0.exerciseID, name: $0.name, location: $0.location,
                              photoFileName: $0.photoFileName)
            },
            media: media.map {
                MediaRecord(id: $0.mediaID, exerciseID: $0.exerciseID, kind: $0.kindID, source: $0.sourceID,
                            fileName: $0.fileName, position: $0.position)
            }
        )
    }

    static func json(_ backup: Backup) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(backup)
    }

    /// Writes `data` to a temporary file to hand to the share sheet.
    static func temporaryFile(named name: String, data: Data) throws -> URL {
        let url = URL.temporaryDirectory.appending(path: name)
        try data.write(to: url, options: .atomic)
        return url
    }
}
