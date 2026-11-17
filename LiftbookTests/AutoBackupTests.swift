import Foundation
import SwiftData
import Testing
@testable import Liftbook

@MainActor
struct AutoBackupTests {
    private let container = Persistence.makeContainer(inMemory: true)
    private let now = Date(timeIntervalSince1970: 1_793_880_000)

    @Test func dueAfterADayOrWhenNeverBackedUp() {
        #expect(AutoBackup.isDue(last: nil, now: now))
        #expect(!AutoBackup.isDue(last: now.addingTimeInterval(-23 * 3600), now: now))
        #expect(AutoBackup.isDue(last: now.addingTimeInterval(-86_400), now: now))
    }

    @Test func fileNameUsesTheLocalDay() {
        let utc = TimeZone(identifier: "UTC")!
        #expect(AutoBackup.fileName(at: now, timeZone: utc) == "liftbook-backup-2026-11-05.json")
    }

    /// "liftbook-backup-…" for the day `daysAgo` before `now`.
    private func name(daysAgo: Int, calendar: Calendar) -> String {
        let day = calendar.date(byAdding: .day, value: -daysAgo, to: now) ?? now
        let c = calendar.dateComponents([.year, .month, .day], from: day)
        return String(format: "liftbook-backup-%04d-%02d-%02d.json", c.year ?? 0, c.month ?? 0, c.day ?? 0)
    }

    @Test func recentBackupsAreKeptDailyThenWeekly() throws {
        var calendar = Calendar(identifier: .iso8601)
        calendar.timeZone = try #require(TimeZone(identifier: "UTC"))
        // `now` is Thursday 5 November 2026: one backup a day for 80 days.
        let names = (0..<80).map { name(daysAgo: $0, calendar: calendar) }
            + ["liftbook-before-restore-2026-01-01-120000.json", "notes.txt"]

        let outdated = Set(AutoBackup.outdated(names, now: now, calendar: calendar))
        let kept = names.filter { !outdated.contains($0) && $0.hasPrefix("liftbook-backup-") }

        // The last 7 days, then the newest of each older week back to 63 days.
        let daily = (0..<7).map { name(daysAgo: $0, calendar: calendar) }
        #expect(Array(kept.prefix(7)) == daily)
        let weekly = kept.dropFirst(7)
        #expect(weekly.count == 9, "Weekly backups: \(weekly)")
        #expect(weekly.allSatisfy { name in
            (7..<63).contains { name == self.name(daysAgo: $0, calendar: calendar) }
        })
        let days = weekly.compactMap { AutoBackup.day(of: $0, calendar: calendar) }
        let weeks = Set(days.map { calendar.component(.weekOfYear, from: $0) })
        #expect(weeks.count == days.count, "Two backups kept in one week")
        // Safety copies and other files are never rotated away.
        #expect(!outdated.contains("liftbook-before-restore-2026-01-01-120000.json"))
        #expect(!outdated.contains("notes.txt"))
    }

    @Test func afterAWorkoutBacksUpUnlessSwitchedOff() throws {
        let defaults = try #require(UserDefaults(suiteName: "backup-test-\(UUID().uuidString)"))
        defaults.set(false, forKey: AutoBackup.enabledKey)
        AutoBackup.runAfterWorkout(from: container.mainContext, now: now, defaults: defaults)
        #expect(defaults.object(forKey: AutoBackup.lastDateKey) == nil)
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
