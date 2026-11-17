import Foundation
import Observation
import SwiftData

/// Opens the data store at launch. If it can't be opened, `container` stays
/// nil and the app shows the recovery screen, which can restore the newest
/// backup or start with no data. Either way the unreadable files are moved
/// to Damaged Data first, never deleted.
@MainActor
@Observable
final class DataStore {
    enum Failure: Error, LocalizedError {
        case stillUnreadable

        var errorDescription: String? {
            "Liftbook still can't create its data. Restart your iPhone and try again."
        }
    }

    /// The open store; nil while it can't be opened.
    private(set) var container: ModelContainer?
    /// Why the store couldn't be opened.
    private(set) var failure: String?
    /// The store file; nil for an in-memory store.
    let url: URL?
    private let onOpen: (ModelContainer) -> Void

    /// - Parameter onOpen: runs once the store is open, at launch or after a recovery.
    init(url: URL?, onOpen: @escaping (ModelContainer) -> Void) {
        self.url = url
        self.onOpen = onOpen
        open()
    }

    private func open() {
        do {
            let opened = try Persistence.openStore(at: url)
            container = opened
            failure = nil
            onOpen(opened)
        } catch {
            failure = String(describing: error)
        }
    }

    /// Moves the unreadable store aside and starts with no data.
    func startEmpty(damagedFolder: URL = StoreRecovery.damagedFolder) throws {
        if let url { try StoreRecovery.setAside(storeAt: url, in: damagedFolder) }
        open()
        guard container != nil else { throw Failure.stillUnreadable }
    }

    /// Moves the unreadable store aside and restores `file` into a new one.
    /// Nothing moves if the backup can't be read.
    @discardableResult
    func restore(_ file: AutoBackup.File, damagedFolder: URL = StoreRecovery.damagedFolder,
                 backupFolder: URL = AutoBackup.folder, defaults: UserDefaults = AppSettings.store,
                 stores: [BackupFiles.Kind: URL] = BackupFiles.appStores) throws -> DataRestore.Summary {
        let backup = try DataRestore.decode(Data(contentsOf: file.url))
        try startEmpty(damagedFolder: damagedFolder)
        guard let container else { throw Failure.stillUnreadable }
        return try AutoBackup.putBack(backup, into: container.mainContext, folder: backupFolder,
                                      defaults: defaults, stores: stores)
    }
}

enum StoreRecovery {
    /// Documents › Damaged Data, shown in Files under On My iPhone › Liftbook.
    /// UI tests use a temporary folder.
    static let damagedFolder: URL = UITestOverrides.isUITesting
        ? URL.temporaryDirectory.appending(path: "UITestDamagedData", directoryHint: .isDirectory)
        : URL.documentsDirectory.appending(path: "Damaged Data", directoryHint: .isDirectory)

    /// Moves the store file and its SQLite side files into a new folder named
    /// after the time, e.g. "Damaged Data/2026-11-17-090512". Returns it.
    @discardableResult
    static func setAside(storeAt url: URL, in folder: URL, now: Date = .now) throws -> URL {
        let files = FileManager.default
        let destination = folder.appending(path: AutoBackup.stamp(now), directoryHint: .isDirectory)
        try files.createDirectory(at: destination, withIntermediateDirectories: true)
        for suffix in ["", "-shm", "-wal"] {
            let file = URL(filePath: url.path(percentEncoded: false) + suffix)
            guard files.fileExists(atPath: file.path(percentEncoded: false)) else { continue }
            try files.moveItem(at: file, to: destination.appending(path: file.lastPathComponent))
        }
        return destination
    }

    /// The newest backup, counting safety copies.
    static func latestBackup(in folder: URL = AutoBackup.folder) -> AutoBackup.File? {
        AutoBackup.files(in: folder).first
    }
}
