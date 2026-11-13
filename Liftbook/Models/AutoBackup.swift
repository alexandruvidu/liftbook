import Foundation
import SwiftData

/// A full JSON backup saved once a week to the app's Documents folder, which
/// the Files app shows under On My iPhone › Liftbook › Backups. Sideloaded
/// apps can expire or get reinstalled; the backups survive in Files.
enum AutoBackup {
    /// Settings key: whether backups happen on their own (on by default).
    static let enabledKey = "backup.automatic"
    /// Settings key: when the last backup was saved.
    static let lastDateKey = "backup.lastDate"
    static let interval: TimeInterval = 7 * 86_400
    /// How many backups to keep; older ones are deleted.
    static let kept = 4

    static var folder: URL { URL.documentsDirectory.appending(path: "Backups", directoryHint: .isDirectory) }

    /// Whether a week has passed since `last` (or there's never been one).
    static func isDue(last: Date?, now: Date = .now) -> Bool {
        guard let last else { return true }
        return now.timeIntervalSince(last) >= interval
    }

    /// "liftbook-backup-2026-11-13.json" in the user's time zone.
    static func fileName(at date: Date, timeZone: TimeZone = .current) -> String {
        "liftbook-backup-\(date.formatted(Date.ISO8601FormatStyle(timeZone: timeZone).year().month().day())).json"
    }

    /// Backup files beyond the newest `kept` (names sort by date).
    static func outdated(_ names: [String], keeping count: Int = kept) -> [String] {
        let backups = names.filter { $0.hasPrefix("liftbook-backup-") && $0.hasSuffix(".json") }.sorted()
        return Array(backups.dropLast(count))
    }

    /// Saves a backup now and deletes the oldest beyond `kept`.
    @MainActor
    @discardableResult
    static func backUp(from context: ModelContext, to folder: URL = folder, now: Date = .now,
                       defaults: UserDefaults = AppSettings.store) throws -> URL {
        let files = FileManager.default
        try files.createDirectory(at: folder, withIntermediateDirectories: true)
        let url = folder.appending(path: fileName(at: now))
        try DataExport.json(DataExport.backup(from: context, now: now)).write(to: url, options: .atomic)
        let names = (try? files.contentsOfDirectory(atPath: folder.path())) ?? []
        for name in outdated(names) {
            try? files.removeItem(at: folder.appending(path: name))
        }
        defaults.set(now, forKey: lastDateKey)
        return url
    }

    /// Backs up if automatic backups are on and one is due. Skipped in UI tests.
    @MainActor
    static func runIfDue(from context: ModelContext, now: Date = .now, defaults: UserDefaults = AppSettings.store) {
        guard !UITestOverrides.isUITesting,
              defaults.object(forKey: enabledKey) as? Bool ?? true,
              isDue(last: defaults.object(forKey: lastDateKey) as? Date, now: now) else { return }
        try? backUp(from: context, now: now, defaults: defaults)
    }
}
