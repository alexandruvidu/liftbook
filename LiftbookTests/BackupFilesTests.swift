import Foundation
import SwiftData
import Testing
@testable import Liftbook

@MainActor
struct BackupFilesTests {
    private let container = Persistence.makeContainer(inMemory: true)
    private let now = Date(timeIntervalSince1970: 1_793_880_000)
    private let root = URL.temporaryDirectory.appending(path: "backup-files-\(UUID().uuidString)", directoryHint: .isDirectory)
    private var folder: URL { root.appending(path: "Backups", directoryHint: .isDirectory) }
    private var stores: [BackupFiles.Kind: URL] {
        Dictionary(uniqueKeysWithValues: BackupFiles.Kind.allCases.map {
            ($0, root.appending(path: "App/\($0.rawValue)", directoryHint: .isDirectory))
        })
    }

    private func makeDefaults() throws -> UserDefaults {
        try #require(UserDefaults(suiteName: "backup-files-test-\(UUID().uuidString)"))
    }

    /// Writes a file into the app's store for `kind`.
    private func addFile(_ name: String, _ kind: BackupFiles.Kind, contents: String = "image") throws {
        let directory = try #require(stores[kind])
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try Data(contents.utf8).write(to: directory.appending(path: name))
    }

    private func exists(_ url: URL) -> Bool {
        FileManager.default.fileExists(atPath: url.path(percentEncoded: false))
    }

    private func copy(_ name: String, _ kind: BackupFiles.Kind) -> URL {
        AutoBackup.filesFolder(in: folder).appending(path: "\(kind.rawValue)/\(name)")
    }

    /// A progress photo, a machine photo and an exercise video, with files.
    private func addPhotosAndMedia() throws {
        let context = container.mainContext
        context.insert(ProgressPhoto(date: now, fileName: "front.jpg"))
        let machine = Machine(exerciseID: "barbell-bench-press", name: "Flat bench A", location: "", createdAt: now)
        machine.photoFileName = "bench.jpg"
        context.insert(machine)
        context.insert(ExerciseMedia(exerciseID: "barbell-bench-press", kind: .video, source: .own,
                                     fileName: "clip.mov", position: 0))
        try context.save()
        try addFile("front.jpg", .progressPhotos)
        try addFile("bench.jpg", .machinePhotos)
        try addFile("clip.mov", .media, contents: "video")
    }

    @Test func settingsAreReadAndPutBack() throws {
        let defaults = try makeDefaults()
        defaults.set(WeightUnit.pounds.rawValue, forKey: WeightUnit.storageKey)
        defaults.set(5, forKey: WeeklyGoal.storageKey)
        defaults.set(false, forKey: RestTimer.soundKey)
        defaults.set(now, forKey: AutoBackup.lastDateKey)
        let record = DataExport.SettingsRecord(defaults: defaults)
        #expect(record == DataExport.SettingsRecord(weightUnit: "pounds", weeklyGoal: 5, restSound: false))

        let other = try makeDefaults()
        other.set(true, forKey: RestTimer.keepScreenOnKey)
        other.set(now, forKey: AutoBackup.lastDateKey)
        record.apply(to: other)
        #expect(DataExport.SettingsRecord(defaults: other) == record)
        // Settings the backup never changed go back to the default; the
        // phone's own last backup date stays.
        #expect(other.object(forKey: RestTimer.keepScreenOnKey) == nil)
        #expect(other.object(forKey: AutoBackup.lastDateKey) as? Date == now)
    }

    @Test func backUpCopiesThePhotoAndVideoFiles() throws {
        try addPhotosAndMedia()
        try AutoBackup.backUp(from: container.mainContext, to: folder, now: now, defaults: makeDefaults(), stores: stores)

        #expect(exists(copy("front.jpg", .progressPhotos)))
        #expect(exists(copy("bench.jpg", .machinePhotos)))
        #expect(try String(contentsOf: copy("clip.mov", .media), encoding: .utf8) == "video")
    }

    @Test func restorePutsBackMissingFiles() throws {
        try addPhotosAndMedia()
        let defaults = try makeDefaults()
        let url = try AutoBackup.backUp(from: container.mainContext, to: folder, now: now, defaults: defaults, stores: stores)
        // The app lost its files, e.g. after being reinstalled.
        for (_, directory) in stores { try FileManager.default.removeItem(at: directory) }

        try AutoBackup.restore(from: url, into: container.mainContext, folder: folder, now: now,
                               defaults: defaults, stores: stores)

        #expect(try exists(#require(stores[.progressPhotos]).appending(path: "front.jpg")))
        #expect(try exists(#require(stores[.machinePhotos]).appending(path: "bench.jpg")))
        #expect(try exists(#require(stores[.media]).appending(path: "clip.mov")))
        #expect(try container.mainContext.fetch(FetchDescriptor<ProgressPhoto>()).map(\.fileName) == ["front.jpg"])
    }

    @Test func copiesNoBackupNeedsAreDeleted() throws {
        let context = container.mainContext
        let defaults = try makeDefaults()
        let photo = ProgressPhoto(date: now, fileName: "old.jpg")
        context.insert(photo)
        try context.save()
        try addFile("old.jpg", .progressPhotos)
        try AutoBackup.backUp(from: context, to: folder, now: now, defaults: defaults, stores: stores)
        #expect(exists(copy("old.jpg", .progressPhotos)))

        // The photo is deleted; once every backup with it has rotated away,
        // so has its copy.
        context.delete(photo)
        try context.save()
        for week in 1...AutoBackup.kept {
            try AutoBackup.backUp(from: context, to: folder, now: now.addingTimeInterval(Double(week) * AutoBackup.interval),
                                  defaults: defaults, stores: stores)
        }
        #expect(!exists(copy("old.jpg", .progressPhotos)))
    }

    @Test func namesThatLeaveTheFolderAreIgnored() throws {
        var backup = try DataExport.backup(from: container.mainContext, now: now, defaults: makeDefaults())
        backup.progressPhotos = [.init(id: UUID(), date: now, fileName: "../secret.txt")]
        try FileManager.default.createDirectory(at: root.appending(path: "App"), withIntermediateDirectories: true)
        try Data("secret".utf8).write(to: root.appending(path: "App/secret.txt"))

        try BackupFiles(folder: AutoBackup.filesFolder(in: folder), stores: stores).save(for: backup)

        #expect(!exists(AutoBackup.filesFolder(in: folder).appending(path: "secret.txt")))
    }
}
