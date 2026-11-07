import Foundation
import SwiftData
import UIKit

/// A photo or video shown for an exercise: one the user added, or one
/// downloaded from the open exercise dataset.
@Model
final class ExerciseMedia {
    @Attribute(.unique) var mediaID: UUID
    var exerciseID: String
    /// `MediaKind` raw value.
    var kindID: String
    /// `MediaSource` raw value.
    var sourceID: String
    /// A file in `MediaStore.standard`.
    var fileName: String
    var position: Int
    var createdAt: Date

    init(exerciseID: String, kind: MediaKind, source: MediaSource, fileName: String, position: Int, createdAt: Date = .now) {
        mediaID = UUID()
        self.exerciseID = exerciseID
        kindID = kind.rawValue
        sourceID = source.rawValue
        self.fileName = fileName
        self.position = position
        self.createdAt = createdAt
    }

    var kind: MediaKind { MediaKind(rawValue: kindID) ?? .photo }
    var source: MediaSource { MediaSource(rawValue: sourceID) ?? .own }
}

enum MediaKind: String, Sendable {
    case photo, video
}

enum MediaSource: String, Sendable {
    /// Added by the user.
    case own
    /// Fetched from the open exercise dataset.
    case downloaded
}

extension Array where Element == ExerciseMedia {
    /// What to show for an exercise: the user's own first, then downloaded,
    /// each in their saved order.
    func display(for exerciseID: String) -> [ExerciseMedia] {
        filter { $0.exerciseID == exerciseID }
            .sorted { lhs, rhs in
                if lhs.source != rhs.source { return lhs.source == .own }
                return lhs.position < rhs.position
            }
    }
}

/// Where exercise photos and videos are kept on the phone.
struct MediaStore: Sendable {
    let directory: URL

    static let standard = MediaStore(directory: URL.applicationSupportDirectory.appending(path: "ExerciseMedia", directoryHint: .isDirectory))

    func url(for fileName: String) -> URL {
        directory.appending(path: fileName)
    }

    /// Downscales and saves a photo as JPEG; returns the file name.
    func savePhoto(_ image: UIImage) throws -> String {
        try PhotoStore(directory: directory).save(image)
    }

    /// Saves already-encoded image data as-is (e.g. a downloaded JPEG).
    func saveImageData(_ data: Data, fileExtension: String = "jpg") throws -> String {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let fileName = "\(UUID().uuidString).\(fileExtension)"
        try data.write(to: url(for: fileName), options: .atomic)
        return fileName
    }

    /// Copies a video into the store, leaving the original alone.
    func saveVideo(from source: URL) throws -> String {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let ext = source.pathExtension.isEmpty ? "mov" : source.pathExtension.lowercased()
        let fileName = "\(UUID().uuidString).\(ext)"
        try FileManager.default.copyItem(at: source, to: url(for: fileName))
        return fileName
    }

    /// Decoded images, so grids and thumbnails don't re-read files while scrolling.
    private nonisolated(unsafe) static let cache = NSCache<NSString, UIImage>()

    func loadImage(_ fileName: String) -> UIImage? {
        let key = url(for: fileName).path(percentEncoded: false) as NSString
        if let cached = Self.cache.object(forKey: key) { return cached }
        guard let image = UIImage(contentsOfFile: key as String) else { return nil }
        Self.cache.setObject(image, forKey: key)
        return image
    }

    func delete(_ fileName: String) {
        Self.cache.removeObject(forKey: url(for: fileName).path(percentEncoded: false) as NSString)
        try? FileManager.default.removeItem(at: url(for: fileName))
    }
}

extension ExerciseMedia {
    /// Removes photos an earlier build downloaded from free-exercise-db; the
    /// bundled animations replace them. The user's own media stays.
    @MainActor
    static func removeDownloaded(in context: ModelContext, store: MediaStore = .standard) {
        let source = MediaSource.downloaded.rawValue
        let old = (try? context.fetch(FetchDescriptor<ExerciseMedia>(predicate: #Predicate { $0.sourceID == source }))) ?? []
        guard !old.isEmpty else { return }
        for item in old {
            store.delete(item.fileName)
            context.delete(item)
        }
        try? context.save()
    }
}
