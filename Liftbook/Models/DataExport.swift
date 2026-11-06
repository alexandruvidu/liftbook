import Foundation
import SwiftData

/// Exports workouts as CSV (one row per set) and everything as a JSON backup.
enum DataExport {
    static let csvHeader = ["date", "workout", "duration_min", "exercise", "exercise_id", "set", "set_type",
                            "weight_kg", "reps", "seconds", "meters", "rpe", "done", "workout_notes", "exercise_notes"]

    static func isoDate(_ date: Date) -> String {
        date.formatted(.iso8601)
    }

    static func number(_ value: Double?) -> String {
        guard let value else { return "" }
        return String(format: "%g", value)
    }

    /// Finished workouts, oldest first, one row per set.
    static func workoutsCSV(_ sessions: [WorkoutSession], catalog: ExerciseCatalog) -> String {
        var lines = [CSV.line(csvHeader)]
        for session in sessions.filter({ $0.endedAt != nil }).sorted(by: { $0.startedAt < $1.startedAt }) {
            for exercise in session.orderedExercises {
                for (index, set) in exercise.orderedSets.enumerated() {
                    lines.append(CSV.line([
                        isoDate(session.startedAt), session.name, "\(session.durationMinutes)",
                        catalog.name(for: exercise.exerciseID), exercise.exerciseID, "\(index + 1)", set.kind.rawValue,
                        number(set.weight), set.reps.map(String.init) ?? "", number(set.duration), number(set.distance),
                        number(set.rpe), set.isCompleted ? "yes" : "no", session.notes, exercise.notes,
                    ]))
                }
            }
        }
        return lines.joined(separator: "\n") + "\n"
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
        struct Entry: Codable { var exerciseID: String; var sets: Int }
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
                              exercises: routine.orderedEntries.map { .init(exerciseID: $0.exerciseID, sets: $0.setCount) })
            },
            workouts: sessions.map { session in
                WorkoutRecord(id: session.sessionID, name: session.name, notes: session.notes,
                              startedAt: session.startedAt, endedAt: session.endedAt, routineID: session.routineID,
                              exercises: session.orderedExercises.map { exercise in
                                  .init(exerciseID: exercise.exerciseID, notes: exercise.notes,
                                        restSeconds: exercise.restSeconds, supersetGroup: exercise.supersetGroup,
                                        sets: exercise.orderedSets.map { set in
                                            .init(type: set.kind.rawValue, weightKg: set.weight, reps: set.reps,
                                                  seconds: set.duration, meters: set.distance, rpe: set.rpe,
                                                  done: set.isCompleted, completedAt: set.completedAt)
                                        })
                              })
            },
            bodyMetrics: metrics.map { BodyMetricRecord(id: $0.metricID, name: $0.name, kind: $0.kindID, sortIndex: $0.sortIndex) },
            bodyMeasurements: measurements.map { BodyMeasurementRecord(metricID: $0.metricID, value: $0.value, date: $0.date) }
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
