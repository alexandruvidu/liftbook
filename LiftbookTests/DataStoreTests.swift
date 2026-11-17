import Foundation
import SwiftData
import Testing
@testable import Liftbook

@MainActor
struct DataStoreTests {
    private let root = URL.temporaryDirectory.appending(path: "data-store-\(UUID().uuidString)", directoryHint: .isDirectory)
    private var storeURL: URL { root.appending(path: "default.store") }
    private var damaged: URL { root.appending(path: "Damaged Data", directoryHint: .isDirectory) }
    private var backups: URL { root.appending(path: "Backups", directoryHint: .isDirectory) }
    private var stores: [BackupFiles.Kind: URL] {
        Dictionary(uniqueKeysWithValues: BackupFiles.Kind.allCases.map { ($0, root.appending(path: "App/\($0.rawValue)")) })
    }
    private let now = Date(timeIntervalSince1970: 1_793_880_000)

    /// A store file that isn't a database.
    private func writeJunkStore() throws {
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        try Data("not a database".utf8).write(to: storeURL)
    }

    private func damagedFiles() -> [String] {
        let files = FileManager.default
        let folders = (try? files.contentsOfDirectory(atPath: damaged.path(percentEncoded: false))) ?? []
        return folders.flatMap { (try? files.contentsOfDirectory(atPath: damaged.appending(path: $0).path(percentEncoded: false))) ?? [] }
    }

    /// A backup file with one finished workout.
    private func writeBackup() throws -> AutoBackup.File {
        let container = Persistence.makeContainer(inMemory: true)
        let session = WorkoutSession(name: "Back Day", startedAt: now)
        session.endedAt = now.addingTimeInterval(3600)
        container.mainContext.insert(session)
        try container.mainContext.save()
        let defaults = try #require(UserDefaults(suiteName: "data-store-test-\(UUID().uuidString)"))
        try AutoBackup.backUp(from: container.mainContext, to: backups, now: now, defaults: defaults, stores: stores)
        return try #require(StoreRecovery.latestBackup(in: backups))
    }

    @Test func aReadableStoreOpens() throws {
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        var opened = 0
        let store = DataStore(url: storeURL) { _ in opened += 1 }
        #expect(store.container != nil)
        #expect(store.failure == nil)
        #expect(opened == 1)
    }

    @Test func anUnreadableStoreWaitsForRecovery() throws {
        try writeJunkStore()
        var opened = 0
        let store = DataStore(url: storeURL) { _ in opened += 1 }
        #expect(store.container == nil)
        #expect(store.failure != nil)
        #expect(opened == 0)
    }

    @Test func startingEmptyKeepsTheUnreadableFile() throws {
        try writeJunkStore()
        let store = DataStore(url: storeURL) { _ in }

        try store.startEmpty(damagedFolder: damaged)

        let container = try #require(store.container)
        #expect(try container.mainContext.fetchCount(FetchDescriptor<WorkoutSession>()) == 0)
        #expect(damagedFiles() == ["default.store"])
        let kept = try #require(FileManager.default.enumerator(atPath: damaged.path(percentEncoded: false))?
            .compactMap { $0 as? String }.first { $0.hasSuffix("default.store") })
        #expect(try String(contentsOf: damaged.appending(path: kept), encoding: .utf8) == "not a database")
    }

    @Test func restoringTheLatestBackupBringsBackTheData() throws {
        let backup = try writeBackup()
        try writeJunkStore()
        let store = DataStore(url: storeURL) { _ in }
        let defaults = try #require(UserDefaults(suiteName: "data-store-test-\(UUID().uuidString)"))

        let summary = try store.restore(backup, damagedFolder: damaged, backupFolder: backups,
                                        defaults: defaults, stores: stores)

        #expect(summary.workouts == 1)
        let context = try #require(store.container).mainContext
        #expect(try context.fetch(FetchDescriptor<WorkoutSession>()).map(\.name) == ["Back Day"])
        #expect(damagedFiles() == ["default.store"])
    }

    @Test func anUnreadableBackupMovesNothing() throws {
        try writeJunkStore()
        try FileManager.default.createDirectory(at: backups, withIntermediateDirectories: true)
        let bad = backups.appending(path: "liftbook-backup-2026-11-01.json")
        try Data("{}".utf8).write(to: bad)
        let store = DataStore(url: storeURL) { _ in }
        let file = try #require(StoreRecovery.latestBackup(in: backups))

        #expect(throws: DataRestore.Failure.self) {
            try store.restore(file, damagedFolder: damaged, backupFolder: backups, stores: stores)
        }
        #expect(store.container == nil)
        #expect(damagedFiles().isEmpty)
        #expect(FileManager.default.fileExists(atPath: storeURL.path(percentEncoded: false)))
    }

    @Test func theLatestBackupIsTheNewest() throws {
        try FileManager.default.createDirectory(at: backups, withIntermediateDirectories: true)
        let old = backups.appending(path: "liftbook-backup-2026-11-01.json")
        let new = backups.appending(path: "liftbook-before-restore-2026-11-08-101500.json")
        for (url, date) in [(old, now), (new, now.addingTimeInterval(86_400))] {
            try Data("{}".utf8).write(to: url)
            try FileManager.default.setAttributes([.modificationDate: date], ofItemAtPath: url.path(percentEncoded: false))
        }
        #expect(StoreRecovery.latestBackup(in: backups)?.url.lastPathComponent == new.lastPathComponent)
        #expect(StoreRecovery.latestBackup(in: root.appending(path: "none")) == nil)
    }
}
