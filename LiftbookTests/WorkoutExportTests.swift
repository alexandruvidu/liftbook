import Foundation
import SwiftData
import Testing
@testable import Liftbook

/// Exporting one workout, and machines in CSV files.
@MainActor
struct WorkoutExportTests {
    private let catalog = ExerciseCatalog(custom: [])
    private let container = Persistence.makeContainer(inMemory: true)
    private var context: ModelContext { container.mainContext }
    private let start = Date(timeIntervalSince1970: 1_793_800_000)

    private func workout(_ name: String, daysAgo: Int = 0, machine: Machine? = nil, notes: String = "") -> WorkoutSession {
        let date = start.addingTimeInterval(TimeInterval(-daysAgo) * 86_400)
        let session = WorkoutSession(name: name, startedAt: date)
        context.insert(session)
        session.notes = notes
        session.addExercises(["t-bar-row"], setCount: 1)
        let exercise = session.exercises[0]
        exercise.machineID = machine?.machineID
        exercise.sets[0].measurement = SetMeasurement(weight: 40, reps: 10)
        exercise.sets[0].toggleCompleted(for: .weightAndReps, at: date)
        session.finish(at: date.addingTimeInterval(3600))
        return session
    }

    private func rows(_ csv: String) -> [[String]] { Array(CSV.parse(csv).dropFirst()) }

    @Test func singleWorkoutHasOnlyThatSession() {
        let mine = workout("Back Day")
        _ = workout("Leg Day", daysAgo: 1)
        let csv = DataExport.workoutCSV(mine, catalog: catalog)
        #expect(CSV.parse(csv).first == DataExport.csvHeader)
        #expect(rows(csv).count == 1)
        #expect(rows(csv)[0][1] == "Back Day")
    }

    @Test func machineColumnFilled() throws {
        let machine = Machine(exerciseID: "t-bar-row", name: "Plate-loaded")
        context.insert(machine)
        let csv = DataExport.workoutCSV(workout("Back Day", machine: machine), catalog: catalog, machines: [machine])
        let column = try #require(DataExport.csvHeader.firstIndex(of: "machine"))
        #expect(rows(csv)[0][column] == "Plate-loaded")
    }

    @Test func deletedMachineColumnEmpty() throws {
        let gone = Machine(exerciseID: "t-bar-row", name: "Gone")
        let csv = DataExport.workoutCSV(workout("Back Day", machine: gone), catalog: catalog, machines: [])
        let column = try #require(DataExport.csvHeader.firstIndex(of: "machine"))
        #expect(rows(csv)[0][column] == "")
    }

    @Test func commasQuotesNewlinesQuoted() throws {
        let machine = Machine(exerciseID: "t-bar-row", name: "Plate \"A\", corner")
        context.insert(machine)
        let csv = DataExport.workoutCSV(workout("Back Day", machine: machine, notes: "Line one\nline two"),
                                        catalog: catalog, machines: [machine])
        let row = rows(csv)[0]
        #expect(row[try #require(DataExport.csvHeader.firstIndex(of: "machine"))] == "Plate \"A\", corner")
        #expect(row[try #require(DataExport.csvHeader.firstIndex(of: "workout_notes"))] == "Line one\nline two")
    }

    @Test func fileNameSanitized() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        let session = WorkoutSession(name: "Back Day / Heavy", startedAt: start)
        #expect(DataExport.fileName(for: session, calendar: calendar) == "Liftbook-2026-11-04-Back-Day-Heavy.csv")
        session.name = "!!"
        #expect(DataExport.fileName(for: session, calendar: calendar) == "Liftbook-2026-11-04.csv")
    }

    @Test func importCreatesMachineByName() throws {
        let machine = Machine(exerciseID: "t-bar-row", name: "Plate-loaded")
        let csv = DataExport.workoutCSV(workout("Back Day", machine: machine), catalog: catalog, machines: [machine])
        let target = ModelContext(Persistence.makeContainer(inMemory: true))
        _ = try DataImport.importWorkouts(csv: csv, into: target, catalog: catalog)
        let machines = try target.fetch(FetchDescriptor<Machine>())
        #expect(machines.map(\.name) == ["Plate-loaded"])
        let imported = try #require(try target.fetch(FetchDescriptor<WorkoutSession>()).first)
        #expect(imported.exercises[0].machineID == machines[0].machineID)
    }

    @Test func twoMachinesSameExerciseStaySeparate() throws {
        let a = Machine(exerciseID: "t-bar-row", name: "A")
        let b = Machine(exerciseID: "t-bar-row", name: "B")
        let session = workout("Back Day", machine: a)
        session.addExercises(["t-bar-row"], setCount: 1)
        let second = session.orderedExercises[1]
        second.machineID = b.machineID
        second.sets[0].measurement = SetMeasurement(weight: 55, reps: 8)
        second.sets[0].toggleCompleted(for: .weightAndReps)
        let csv = DataExport.workoutCSV(session, catalog: catalog, machines: [a, b])

        let target = ModelContext(Persistence.makeContainer(inMemory: true))
        _ = try DataImport.importWorkouts(csv: csv, into: target, catalog: catalog)
        let imported = try #require(try target.fetch(FetchDescriptor<WorkoutSession>()).first)
        #expect(imported.exercises.count == 2)
        #expect(Set(try target.fetch(FetchDescriptor<Machine>()).map(\.name)) == ["A", "B"])
    }

    @Test func oldCSVWithoutMachineStillImports() throws {
        let csv = """
        date,workout,duration_min,exercise,exercise_id,set,set_type,weight_kg,reps,seconds,meters,rpe,done,workout_notes,exercise_notes
        2026-11-01T18:00:00Z,Old,40,T-Bar Row,t-bar-row,1,normal,40,10,,,,yes,,
        """
        let target = ModelContext(Persistence.makeContainer(inMemory: true))
        let result = try DataImport.importWorkouts(csv: csv, into: target, catalog: catalog)
        #expect(result.sets == 1)
        #expect(try target.fetch(FetchDescriptor<Machine>()).isEmpty)
    }

    @Test func backupListsMachines() throws {
        let machine = Machine(exerciseID: "t-bar-row", name: "Plate-loaded")
        context.insert(machine)
        _ = workout("Back Day", machine: machine)
        try context.save()
        let backup = try DataExport.backup(from: context)
        #expect(backup.machines?.map(\.name) == ["Plate-loaded"])
        #expect(backup.workouts.first?.exercises.first?.machineID == machine.machineID)
    }
}
