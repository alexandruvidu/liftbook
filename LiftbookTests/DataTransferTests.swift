import Foundation
import SwiftData
import Testing
@testable import Liftbook

@MainActor
struct DataTransferTests {
    private let catalog = ExerciseCatalog(custom: [])

    @Test func csvEscapesAndParsesTrickyFields() {
        let fields = ["plain", "has, comma", "has \"quotes\"", "two\nlines", ""]
        let line = CSV.line(fields)
        #expect(line == "plain,\"has, comma\",\"has \"\"quotes\"\"\",\"two\nlines\",")
        #expect(CSV.parse(line + "\r\nnext,row\n\n") == [fields, ["next", "row"]])
    }

    private func seededContext() -> ModelContext {
        let container = Persistence.makeContainer(inMemory: true)
        let context = ModelContext(container)
        let session = WorkoutSession(name: "Push, heavy", startedAt: Date(timeIntervalSince1970: 1_780_000_000))
        context.insert(session)
        session.notes = "Felt \"great\""
        session.addExercises(["barbell-bench-press", "plank"], setCount: 2)
        let bench = session.orderedExercises[0]
        bench.orderedSets[0].kind = .warmUp
        bench.orderedSets[0].measurement = SetMeasurement(weight: 40, reps: 10)
        bench.orderedSets[1].measurement = SetMeasurement(weight: 82.5, reps: 5)
        bench.orderedSets[1].rpe = 8.5
        bench.orderedSets.forEach { $0.toggleCompleted(for: .weightAndReps) }
        session.orderedExercises[1].orderedSets[0].measurement = SetMeasurement(duration: 60)
        session.orderedExercises[1].orderedSets[0].toggleCompleted(for: .duration)
        session.finish(at: session.startedAt.addingTimeInterval(45 * 60))
        try? context.save()
        return context
    }

    @Test func csvRoundTripsThroughImport() throws {
        let source = seededContext()
        let sessions = try source.fetch(FetchDescriptor<WorkoutSession>())
        let csv = DataExport.workoutsCSV(sessions, catalog: catalog)
        #expect(csv.hasPrefix(DataExport.csvHeader.joined(separator: ",") + "\n"))
        #expect(csv.split(separator: "\n").count == 5) // header + 4 sets

        let target = ModelContext(Persistence.makeContainer(inMemory: true))
        let result = try DataImport.importWorkouts(csv: csv, into: target, catalog: catalog)
        #expect(result == DataImport.Result(workouts: 1, sets: 4, skippedDuplicates: 0))

        let imported = try #require(try target.fetch(FetchDescriptor<WorkoutSession>()).first)
        #expect(imported.name == "Push, heavy")
        #expect(imported.notes == "Felt \"great\"")
        #expect(imported.durationMinutes == 45)
        #expect(imported.orderedExercises.map(\.exerciseID) == ["barbell-bench-press", "plank"])
        let bench = imported.orderedExercises[0].orderedSets
        #expect(bench.map(\.kind) == [.warmUp, .normal])
        #expect(bench[1].measurement == SetMeasurement(weight: 82.5, reps: 5))
        #expect(bench[1].rpe == 8.5)
        #expect(bench[1].isCompleted)
        #expect(imported.orderedExercises[1].orderedSets[0].duration == 60)
        #expect(!imported.orderedExercises[1].orderedSets[1].isCompleted)
    }

    @Test func importingTwiceSkipsDuplicates() throws {
        let source = seededContext()
        let csv = DataExport.workoutsCSV(try source.fetch(FetchDescriptor<WorkoutSession>()), catalog: catalog)
        let result = try DataImport.importWorkouts(csv: csv, into: source, catalog: catalog)
        #expect(result.workouts == 0)
        #expect(result.skippedDuplicates == 1)
    }

    @Test func unknownIDsAreMatchedByName() throws {
        let csv = """
        date,workout,exercise,exercise_id,set_type,weight_kg,reps,done
        2026-11-01,Imported,Barbell Bench Press,some-other-app-id,normal,70,6,yes
        """
        let context = ModelContext(Persistence.makeContainer(inMemory: true))
        let result = try DataImport.importWorkouts(csv: csv, into: context, catalog: catalog)
        #expect(result.sets == 1)
        let session = try #require(try context.fetch(FetchDescriptor<WorkoutSession>()).first)
        #expect(session.orderedExercises.first?.exerciseID == "barbell-bench-press")
    }

    @Test func rejectsFilesWithoutTheNeededColumns() {
        let context = ModelContext(Persistence.makeContainer(inMemory: true))
        #expect(throws: DataImport.Failure.missingColumns(["exercise_id", "set_type"])) {
            try DataImport.importWorkouts(csv: "date,workout\n2026-11-01,X\n", into: context, catalog: catalog)
        }
    }

    @Test func jsonBackupContainsEverything() throws {
        let context = seededContext()
        BodyMetrics.ensureBuiltIns(in: context)
        context.insert(BodyMeasurement(metricID: BodyMetric.bodyWeightID, value: 80))
        let backup = try DataExport.backup(from: context, now: Date(timeIntervalSince1970: 0))
        #expect(backup.workouts.count == 1)
        #expect(backup.workouts[0].exercises[0].sets[1].weightKg == 82.5)
        #expect(backup.bodyMetrics.count == 2)
        #expect(backup.bodyMeasurements.count == 1)
        let data = try DataExport.json(backup)
        let decoded = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        #expect(decoded?["format"] as? String == "liftbook-backup")
        #expect(decoded?["version"] as? Int == 1)
    }
}
