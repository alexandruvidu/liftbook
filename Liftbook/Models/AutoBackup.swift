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

    /// Documents › Backups. UI tests get an empty temporary folder instead
    /// (kept across a relaunch with the same store file).
    static let folder: URL = {
        guard UITestOverrides.isUITesting else {
            return URL.documentsDirectory.appending(path: "Backups", directoryHint: .isDirectory)
        }
        let url = URL.temporaryDirectory.appending(path: "UITestBackups", directoryHint: .isDirectory)
        if UITestOverrides.storeFile == nil { try? FileManager.default.removeItem(at: url) }
        return url
    }()

    /// A backup file in the folder, for the restore list.
    struct File: Identifiable, Equatable {
        let url: URL
        let date: Date
        /// Saved just before a restore replaced the data.
        let isSafetyCopy: Bool
        var id: URL { url }
    }

    /// The folder's backups, newest first.
    static func files(in folder: URL = folder) -> [File] {
        let urls = (try? FileManager.default.contentsOfDirectory(at: folder, includingPropertiesForKeys: [.contentModificationDateKey])) ?? []
        return urls
            .filter { $0.pathExtension == "json" && $0.lastPathComponent.hasPrefix("liftbook-") }
            .map { url in
                let date = (try? url.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
                return File(url: url, date: date, isSafetyCopy: url.lastPathComponent.hasPrefix(safetyCopyPrefix))
            }
            .sorted { $0.date > $1.date }
    }

    /// Safety copies don't use the backup prefix, so rotation never deletes them.
    static let safetyCopyPrefix = "liftbook-before-restore-"

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

    /// Saves the current data next to the backups before a restore replaces
    /// it, e.g. "liftbook-before-restore-2026-11-13-183005.json".
    @MainActor
    @discardableResult
    static func saveSafetyCopy(from context: ModelContext, to folder: URL = folder, now: Date = .now,
                               timeZone: TimeZone = .current) throws -> URL {
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let style = Date.ISO8601FormatStyle(dateSeparator: .dash, timeSeparator: .omitted, timeZone: timeZone)
            .year().month().day().time(includingFractionalSeconds: false)
        let stamp = now.formatted(style).replacingOccurrences(of: "T", with: "-")
        let url = folder.appending(path: "\(safetyCopyPrefix)\(stamp).json")
        try DataExport.json(DataExport.backup(from: context, now: now)).write(to: url, options: .atomic)
        return url
    }

    /// Replaces all data with the backup at `url`, saving a safety copy of the
    /// current data first. Nothing changes if the file can't be read.
    @MainActor
    @discardableResult
    static func restore(from url: URL, into context: ModelContext, folder: URL = folder,
                        now: Date = .now) throws -> DataRestore.Summary {
        let backup = try DataRestore.decode(Data(contentsOf: url))
        try saveSafetyCopy(from: context, to: folder, now: now)
        return try DataRestore.restore(backup, into: context)
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
