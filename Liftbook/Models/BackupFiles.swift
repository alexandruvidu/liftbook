import Foundation

/// Copies of the photo and video files backups point at, in Backups › Files
/// next to the JSON files. File names are unique and a file never changes
/// once saved, so all backups share one copy of each.
struct BackupFiles {
    enum Kind: String, CaseIterable {
        case progressPhotos = "ProgressPhotos"
        case machinePhotos = "MachinePhotos"
        case media = "ExerciseMedia"
    }

    /// Where the copies go.
    let folder: URL
    /// Where the app keeps each kind of file.
    let stores: [Kind: URL]

    init(folder: URL, stores: [Kind: URL] = BackupFiles.appStores) {
        self.folder = folder
        self.stores = stores
    }

    static let appStores: [Kind: URL] = [
        .progressPhotos: PhotoStore.standard.directory,
        .machinePhotos: PhotoStore.machines.directory,
        .media: MediaStore.standard.directory,
    ]

    /// The files of each kind `backup` points at.
    static func names(in backup: DataExport.Backup) -> [Kind: Set<String>] {
        [
            .progressPhotos: Set((backup.progressPhotos ?? []).map(\.fileName)),
            .machinePhotos: Set((backup.machines ?? []).compactMap(\.photoFileName)),
            .media: Set((backup.media ?? []).map(\.fileName)),
        ]
    }

    /// Copies the app's files that `backup` points at into the folder.
    func save(for backup: DataExport.Backup) throws {
        try copy(Self.names(in: backup), from: { stores[$0] }, to: { folder.appending(path: $0.rawValue) })
    }

    /// Copies the backup's files back into the app where they're missing.
    func restore(for backup: DataExport.Backup) throws {
        try copy(Self.names(in: backup), from: { folder.appending(path: $0.rawValue) }, to: { stores[$0] })
    }

    /// Deletes copies that none of `backups` points at.
    func prune(keeping backups: [DataExport.Backup]) {
        let files = FileManager.default
        for kind in Kind.allCases {
            let needed = backups.reduce(into: Set<String>()) { $0.formUnion(Self.names(in: $1)[kind] ?? []) }
            let directory = folder.appending(path: kind.rawValue)
            for name in (try? files.contentsOfDirectory(atPath: directory.path(percentEncoded: false))) ?? []
            where !needed.contains(name) {
                try? files.removeItem(at: directory.appending(path: name))
            }
        }
    }

    /// Copies each named file that exists in the source and not yet in the
    /// destination. Files that are gone (e.g. deleted media) are skipped.
    private func copy(_ names: [Kind: Set<String>], from source: (Kind) -> URL?, to destination: (Kind) -> URL?) throws {
        let files = FileManager.default
        for (kind, names) in names where !names.isEmpty {
            guard let from = source(kind), let to = destination(kind) else { continue }
            try files.createDirectory(at: to, withIntermediateDirectories: true)
            // Plain names only: a picked backup file could point outside the folders.
            for name in names where !name.contains("/") && !name.hasPrefix(".") {
                let original = from.appending(path: name), copy = to.appending(path: name)
                guard files.fileExists(atPath: original.path(percentEncoded: false)),
                      !files.fileExists(atPath: copy.path(percentEncoded: false)) else { continue }
                try files.copyItem(at: original, to: copy)
            }
        }
    }
}
