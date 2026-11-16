import Foundation
import SwiftData
import Testing
@testable import Liftbook

@MainActor
struct DataRestoreTests {
    private let now = Date(timeIntervalSince1970: 1_793_880_000)
    /// A context dies with its container, so the test keeps them alive.
    private let containers = (0..<2).map { _ in Persistence.makeContainer(inMemory: true) }
    private var context: ModelContext { containers[0].mainContext }
    private var otherContext: ModelContext { containers[1].mainContext }

    /// One of everything a backup holds.
    private func fillStore(_ context: ModelContext) throws {
        var draft = ExerciseDraft()
        draft.name = "Cable Fly"
        draft.primaryMuscles = [.chest]
        let custom = CustomExercise(draft: draft)
        context.insert(custom)

        let folder = RoutineFolder(name: "Push", sortIndex: 2)
        context.insert(folder)
        let machine = Machine(exerciseID: "barbell-bench-press", name: "Flat bench A", location: "back", createdAt: now)
        machine.photoFileName = "machine.jpg"
        context.insert(machine)
        var routineDraft = RoutineDraft()
        routineDraft.name = "Chest"
        routineDraft.add(["barbell-bench-press", custom.exerciseID])
        routineDraft.entries[0].machineID = machine.machineID
        let routine = Routine()
        context.insert(routine)
        routine.apply(routineDraft, folder: folder, in: context)

        let session = WorkoutSession(name: "Chest Day", startedAt: now, routineID: routine.routineID)
        session.notes = "Felt strong"
        context.insert(session)
        session.addExercises(["barbell-bench-press", custom.exerciseID], setCount: 2)
        let bench = session.orderedExercises[0]
        bench.machineID = machine.machineID
        bench.restSeconds = 120
        bench.supersetGroup = UUID()
        bench.notes = "Elbows in"
        bench.orderedSets[0].kind = .warmUp
        bench.orderedSets[1].measurement = SetMeasurement(weight: 80, reps: 6)
        bench.orderedSets[1].rpe = 8.5
        bench.orderedSets[1].toggleCompleted(for: .weightAndReps, at: now)
        session.finish(at: now.addingTimeInterval(3600))

        BodyMetrics.ensureBuiltIns(in: context)
        context.insert(BodyMetric(metricID: "metric-waist", name: "Waist", kind: .length, sortIndex: 2))
        context.insert(BodyMeasurement(metricID: BodyMetric.bodyWeightID, value: 81.5, date: now))
        context.insert(ExerciseMedia(exerciseID: "barbell-bench-press", kind: .video, source: .own,
                                     fileName: "clip.mov", position: 0))
        try context.save()
    }

    /// A backup with every list in a fixed order, to compare two backups.
    private func normalized(_ backup: DataExport.Backup) -> DataExport.Backup {
        var copy = backup
        copy.customExercises.sort { $0.id < $1.id }
        copy.folders.sort { $0.id.uuidString < $1.id.uuidString }
        copy.routines.sort { $0.id.uuidString < $1.id.uuidString }
        copy.bodyMetrics.sort { $0.id < $1.id }
        copy.media?.sort { $0.id.uuidString < $1.id.uuidString }
        return copy
    }

    @Test func restoringABackupGivesBackTheSameData() throws {
        let source = context
        try fillStore(source)
        let original = try DataExport.backup(from: source, now: now)
        let decoded = try DataRestore.decode(DataExport.json(original))

        let target = otherContext
        let summary = try DataRestore.restore(decoded, into: target)

        #expect(summary == DataRestore.Summary(workouts: 1, routines: 1))
        #expect(normalized(try DataExport.backup(from: target, now: now)) == normalized(original))
    }

    @Test func restoreReplacesWhatWasThere() throws {
        try fillStore(context)
        let backup = try DataExport.backup(from: context, now: now)
        // Changes after the backup: a new workout and a renamed routine.
        context.insert(WorkoutSession(name: "Extra", startedAt: now.addingTimeInterval(86_400)))
        try context.fetch(FetchDescriptor<Routine>())[0].name = "Renamed"
        try context.save()

        try DataRestore.restore(backup, into: context)

        let sessions = try context.fetch(FetchDescriptor<WorkoutSession>())
        #expect(sessions.map(\.name) == ["Chest Day"])
        #expect(try context.fetch(FetchDescriptor<Routine>()).map(\.name) == ["Chest"])
        #expect(try context.fetchCount(FetchDescriptor<WorkoutSet>()) == 4)
        #expect(try context.fetchCount(FetchDescriptor<RoutineEntry>()) == 2)
        let builtIns = try context.fetch(FetchDescriptor<BodyMetric>()).filter(\.isBuiltIn).map(\.metricID).sorted()
        #expect(builtIns == [BodyMetric.bodyFatID, BodyMetric.bodyWeightID])
    }

    @Test func oldBackupsWithoutMachinesOrMediaRestore() throws {
        var backup = try DataExport.backup(from: otherContext, now: now)
        backup.machines = nil
        backup.media = nil
        try fillStore(context)
        try DataRestore.restore(backup, into: context)
        #expect(try context.fetchCount(FetchDescriptor<WorkoutSession>()) == 0)
        #expect(try context.fetchCount(FetchDescriptor<Machine>()) == 0)
    }

    @Test func otherFilesAreRejected() throws {
        #expect(throws: DataRestore.Failure.self) { try DataRestore.decode(Data("date,workout\n".utf8)) }
        var backup = try DataExport.backup(from: otherContext, now: now)
        backup.format = "something-else"
        #expect(throws: DataRestore.Failure.self) { try DataRestore.decode(DataExport.json(backup)) }
        backup.format = DataExport.Backup.formatName
        backup.version = DataExport.Backup.currentVersion + 1
        #expect(throws: DataRestore.Failure.self) { try DataRestore.decode(DataExport.json(backup)) }
    }

    @Test func restoringAFileSavesTheCurrentDataFirst() throws {
        let folder = URL.temporaryDirectory.appending(path: "restore-\(UUID().uuidString)", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let empty = try DataExport.json(DataExport.backup(from: otherContext, now: now))
        let file = folder.appending(path: "liftbook-backup-2026-11-01.json")
        try empty.write(to: file)
        try fillStore(context)

        try AutoBackup.restore(from: file, into: context, folder: folder, now: now)

        #expect(try context.fetchCount(FetchDescriptor<WorkoutSession>()) == 0)
        let safetyCopies = AutoBackup.files(in: folder).filter(\.isSafetyCopy)
        let safety = try #require(safetyCopies.first)
        #expect(safety.url.lastPathComponent.hasPrefix(AutoBackup.safetyCopyPrefix))
        #expect(try String(contentsOf: safety.url, encoding: .utf8).contains("Chest Day"))
        // Safety copies are never rotated away.
        #expect(AutoBackup.outdated([safety.url.lastPathComponent], keeping: 0).isEmpty)
    }

    @Test func aBadFileChangesNothing() throws {
        let folder = URL.temporaryDirectory.appending(path: "restore-\(UUID().uuidString)", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let file = folder.appending(path: "notes.json")
        try Data("{}".utf8).write(to: file)
        try fillStore(context)

        #expect(throws: DataRestore.Failure.self) { try AutoBackup.restore(from: file, into: context, folder: folder) }
        #expect(try context.fetchCount(FetchDescriptor<WorkoutSession>()) == 1)
        #expect(AutoBackup.files(in: folder).isEmpty)
    }

    @Test func safetyCopyNameHasTheLocalTime() throws {
        let folder = URL.temporaryDirectory.appending(path: "restore-\(UUID().uuidString)", directoryHint: .isDirectory)
        let utc = try #require(TimeZone(identifier: "UTC"))
        let url = try AutoBackup.saveSafetyCopy(from: otherContext, to: folder,
                                                now: now, timeZone: utc)
        #expect(url.lastPathComponent == "liftbook-before-restore-2026-11-05-120000.json")
    }
}
