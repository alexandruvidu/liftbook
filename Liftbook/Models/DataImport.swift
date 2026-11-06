import Foundation
import SwiftData

/// Imports workouts from a CSV in the export format.
enum DataImport {
    struct Result: Equatable, Sendable {
        var workouts = 0
        var sets = 0
        var skippedDuplicates = 0
    }

    enum Failure: Error, Equatable {
        case missingColumns([String])
        case empty
    }

    static let requiredColumns = ["date", "workout", "exercise_id", "set_type"]

    /// Adds the workouts in `csv` to `context`. A workout with the same name
    /// and start time as one already there is skipped, so importing the same
    /// file twice is harmless. Unknown exercise IDs are matched by name.
    @MainActor
    static func importWorkouts(csv: String, into context: ModelContext, catalog: ExerciseCatalog) throws -> Result {
        var rows = CSV.parse(csv)
        guard !rows.isEmpty else { throw Failure.empty }
        let header = rows.removeFirst().map { $0.trimmingCharacters(in: .whitespaces).lowercased() }
        let missing = requiredColumns.filter { !header.contains($0) }
        guard missing.isEmpty else { throw Failure.missingColumns(missing) }
        let column = Dictionary(header.enumerated().map { ($1, $0) }, uniquingKeysWith: { first, _ in first })
        func value(_ row: [String], _ name: String) -> String {
            guard let index = column[name], index < row.count else { return "" }
            return row[index].trimmingCharacters(in: .whitespaces)
        }

        let existing = try context.fetch(FetchDescriptor<WorkoutSession>())
        var known = Set(existing.map { key($0.name, $0.startedAt) })
        let byName = Dictionary(catalog.exercises.map { ($0.name.lowercased(), $0.id) }, uniquingKeysWith: { first, _ in first })

        var result = Result()
        var current: (key: String, session: WorkoutSession?)?
        var exercises: [String: WorkoutExercise] = [:]

        for row in rows {
            guard let date = parseDate(value(row, "date")) else { continue }
            let name = value(row, "workout").isEmpty ? "Imported Workout" : value(row, "workout")
            let rowKey = key(name, date)
            if current?.key != rowKey {
                exercises = [:]
                if known.contains(rowKey) {
                    // Already in the app, or earlier in this file
                    result.skippedDuplicates += 1
                    current = (rowKey, nil)
                    continue
                }
                let session = WorkoutSession(name: name, startedAt: date)
                session.notes = value(row, "workout_notes")
                let minutes = Double(value(row, "duration_min")) ?? 0
                session.endedAt = date.addingTimeInterval(max(minutes, 1) * 60)
                context.insert(session)
                known.insert(rowKey)
                current = (rowKey, session)
                result.workouts += 1
            }
            guard let session = current?.session else { continue }

            var exerciseID = value(row, "exercise_id")
            if catalog.exercise(id: exerciseID) == nil, let match = byName[value(row, "exercise").lowercased()] {
                exerciseID = match
            }
            guard !exerciseID.isEmpty else { continue }
            let exercise = exercises[exerciseID] ?? {
                let added = WorkoutExercise(exerciseID: exerciseID, position: session.exercises.count)
                added.notes = value(row, "exercise_notes")
                session.exercises.append(added)
                exercises[exerciseID] = added
                return added
            }()
            let set = WorkoutSet(position: exercise.sets.count,
                                 kind: SetKind(rawValue: value(row, "set_type")) ?? .normal,
                                 measurement: SetMeasurement(weight: Double(value(row, "weight_kg")),
                                                             reps: Int(value(row, "reps")),
                                                             duration: Double(value(row, "seconds")),
                                                             distance: Double(value(row, "meters"))))
            set.rpe = Double(value(row, "rpe"))
            if ["yes", "true", "1"].contains(value(row, "done").lowercased()) {
                set.isCompleted = true
                set.completedAt = date
            }
            exercise.sets.append(set)
            result.sets += 1
        }
        try context.save()
        return result
    }

    private static func key(_ name: String, _ date: Date) -> String {
        "\(name)|\(Int(date.timeIntervalSince1970))"
    }

    /// ISO 8601 with or without time; "2026-11-05" means midnight local time.
    static func parseDate(_ text: String) -> Date? {
        if let date = try? Date(text, strategy: .iso8601) { return date }
        let dayOnly = DateFormatter()
        dayOnly.locale = Locale(identifier: "en_US_POSIX")
        dayOnly.dateFormat = "yyyy-MM-dd"
        return dayOnly.date(from: text)
    }
}
