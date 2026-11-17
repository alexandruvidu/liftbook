import Foundation
import SwiftData

/// A full JSON backup saved after every finished workout and at least once a
/// day the app is used, in the app's Documents folder, which
/// the Files app shows under On My iPhone › Liftbook › Backups, with copies of
/// the photo and video files in Backups › Files. Sideloaded apps can expire
/// or get reinstalled; the backups survive in Files.
enum AutoBackup {
    /// Settings key: whether backups happen on their own (on by default).
    static let enabledKey = "backup.automatic"
    /// Settings key: when the last backup was saved.
    static let lastDateKey = "backup.lastDate"
    static let interval: TimeInterval = 86_400

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

    /// Whether a day has passed since `last` (or there's never been one).
    static func isDue(last: Date?, now: Date = .now) -> Bool {
        guard let last else { return true }
        return now.timeIntervalSince(last) >= interval
    }

    /// "liftbook-backup-2026-11-13.json" in the user's time zone.
    static func fileName(at date: Date, timeZone: TimeZone = .current) -> String {
        "liftbook-backup-\(date.formatted(Date.ISO8601FormatStyle(timeZone: timeZone).year().month().day())).json"
    }

    /// Saves a backup now with copies of its photo and video files, and
    /// deletes those the rotation drops (`outdated(_:now:)`) with the copies
    /// no other backup needs.
    @MainActor
    @discardableResult
    static func backUp(from context: ModelContext, to folder: URL = folder, now: Date = .now,
                       defaults: UserDefaults = AppSettings.store,
                       stores: [BackupFiles.Kind: URL] = BackupFiles.appStores) throws -> URL {
        let files = FileManager.default
        let url = try write(DataExport.backup(from: context, now: now, defaults: defaults),
                            named: fileName(at: now), to: folder, stores: stores)
        let names = (try? files.contentsOfDirectory(atPath: folder.path())) ?? []
        for name in outdated(names, now: now) {
            try? files.removeItem(at: folder.appending(path: name))
        }
        pruneFiles(in: folder, stores: stores)
        defaults.set(now, forKey: lastDateKey)
        return url
    }

    /// Saves the current data next to the backups before a restore replaces
    /// it, e.g. "liftbook-before-restore-2026-11-13-183005.json".
    @MainActor
    @discardableResult
    static func saveSafetyCopy(from context: ModelContext, to folder: URL = folder, now: Date = .now,
                               timeZone: TimeZone = .current, defaults: UserDefaults = AppSettings.store,
                               stores: [BackupFiles.Kind: URL] = BackupFiles.appStores) throws -> URL {
        try write(DataExport.backup(from: context, now: now, defaults: defaults),
                  named: "\(safetyCopyPrefix)\(stamp(now, timeZone: timeZone)).json", to: folder, stores: stores)
    }

    /// "2026-11-13-183005": the local date and time, for file names.
    static func stamp(_ date: Date, timeZone: TimeZone = .current) -> String {
        let style = Date.ISO8601FormatStyle(dateSeparator: .dash, timeSeparator: .omitted, timeZone: timeZone)
            .year().month().day().time(includingFractionalSeconds: false)
        return date.formatted(style).replacingOccurrences(of: "T", with: "-")
    }

    /// Replaces all data and settings with the backup at `url`, saving a
    /// safety copy of the current data first, and puts back the backup's
    /// photo and video files. Nothing changes if the file can't be read.
    @MainActor
    @discardableResult
    static func restore(from url: URL, into context: ModelContext, folder: URL = folder, now: Date = .now,
                        defaults: UserDefaults = AppSettings.store,
                        stores: [BackupFiles.Kind: URL] = BackupFiles.appStores) throws -> DataRestore.Summary {
        let backup = try DataRestore.decode(Data(contentsOf: url))
        try saveSafetyCopy(from: context, to: folder, now: now, defaults: defaults, stores: stores)
        return try putBack(backup, into: context, folder: folder, defaults: defaults, stores: stores)
    }

    /// Replaces all data and settings with `backup` and puts back its files,
    /// without a safety copy.
    @MainActor
    @discardableResult
    static func putBack(_ backup: DataExport.Backup, into context: ModelContext, folder: URL = folder,
                        defaults: UserDefaults = AppSettings.store,
                        stores: [BackupFiles.Kind: URL] = BackupFiles.appStores) throws -> DataRestore.Summary {
        // Files first: if a copy fails, the data is still untouched.
        try BackupFiles(folder: filesFolder(in: folder), stores: stores).restore(for: backup)
        return try DataRestore.restore(backup, into: context, defaults: defaults)
    }

    /// Backups › Files, the copies of photos and videos.
    static func filesFolder(in folder: URL) -> URL {
        folder.appending(path: "Files", directoryHint: .isDirectory)
    }

    /// Copies the backup's files, then writes its JSON (so a backup never
    /// lists files that weren't copied).
    private static func write(_ backup: DataExport.Backup, named name: String, to folder: URL,
                              stores: [BackupFiles.Kind: URL]) throws -> URL {
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        try BackupFiles(folder: filesFolder(in: folder), stores: stores).save(for: backup)
        let url = folder.appending(path: name)
        try DataExport.json(backup).write(to: url, options: .atomic)
        return url
    }

    /// Deletes file copies no remaining backup points at. Skipped if any
    /// backup can't be read, so its files are never lost.
    private static func pruneFiles(in folder: URL, stores: [BackupFiles.Kind: URL]) {
        var backups: [DataExport.Backup] = []
        for file in files(in: folder) {
            guard let data = try? Data(contentsOf: file.url), let backup = try? DataRestore.decode(data) else { return }
            backups.append(backup)
        }
        BackupFiles(folder: filesFolder(in: folder), stores: stores).prune(keeping: backups)
    }

    /// Backs up right after a workout is finished, if automatic backups are on.
    /// Runs in UI tests too: they back up into their own temporary folder.
    @MainActor
    static func runAfterWorkout(from context: ModelContext, now: Date = .now, defaults: UserDefaults = AppSettings.store) {
        guard defaults.object(forKey: enabledKey) as? Bool ?? true else { return }
        try? backUp(from: context, now: now, defaults: defaults)
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
