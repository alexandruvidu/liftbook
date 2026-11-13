import Foundation
import SwiftData
import Testing
@testable import Liftbook

@MainActor
struct AutoBackupTests {
    private let container = Persistence.makeContainer(inMemory: true)
    private let now = Date(timeIntervalSince1970: 1_793_880_000)

    @Test func dueAfterAWeekOrWhenNeverBackedUp() {
        #expect(AutoBackup.isDue(last: nil, now: now))
        #expect(!AutoBackup.isDue(last: now.addingTimeInterval(-6 * 86_400), now: now))
        #expect(AutoBackup.isDue(last: now.addingTimeInterval(-7 * 86_400), now: now))
    }

    @Test func fileNameUsesTheLocalDay() {
        let utc = TimeZone(identifier: "UTC")!
        #expect(AutoBackup.fileName(at: now, timeZone: utc) == "liftbook-backup-2026-11-05.json")
    }

    @Test func onlyTheNewestBackupsAreKept() {
        let names = ["liftbook-backup-2026-10-01.json", "liftbook-backup-2026-10-15.json", "notes.txt",
                     "liftbook-backup-2026-10-08.json", "liftbook-backup-2026-10-22.json", "liftbook-backup-2026-10-29.json"]
        #expect(AutoBackup.outdated(names, keeping: 4) == ["liftbook-backup-2026-10-01.json"])
        #expect(AutoBackup.outdated(names, keeping: 10).isEmpty)
    }

    @Test func backUpWritesARestorableFileAndRemembersTheDate() throws {
        let folder = URL.temporaryDirectory.appending(path: "backups-\(UUID().uuidString)", directoryHint: .isDirectory)
        let defaults = try #require(UserDefaults(suiteName: "backup-test-\(UUID().uuidString)"))
        let session = WorkoutSession(name: "Legs", startedAt: now)
        session.endedAt = now.addingTimeInterval(3600)
        container.mainContext.insert(session)
        try container.mainContext.save()

        let url = try AutoBackup.backUp(from: container.mainContext, to: folder, now: now, defaults: defaults)
        let text = try String(contentsOf: url, encoding: .utf8)
        #expect(text.contains("Legs"))
        #expect(defaults.object(forKey: AutoBackup.lastDateKey) as? Date == now)
    }
}
