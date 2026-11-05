import Foundation
import SwiftData
import UIKit

/// A progress photo. The image lives in a file; this records when it was taken.
@Model
final class ProgressPhoto {
    @Attribute(.unique) var photoID: UUID
    var date: Date
    var fileName: String

    init(photoID: UUID = UUID(), date: Date = .now, fileName: String) {
        self.photoID = photoID
        self.date = date
        self.fileName = fileName
    }
}

/// Saves, loads and deletes progress photo files in the app's own storage.
/// Photos never leave the device.
struct PhotoStore: Sendable {
    let directory: URL
    /// Longest side after downscaling, in pixels.
    static let maxDimension: CGFloat = 1600
    static let jpegQuality: CGFloat = 0.82

    static let standard = PhotoStore(directory: URL.applicationSupportDirectory.appending(path: "ProgressPhotos", directoryHint: .isDirectory))

    func url(for fileName: String) -> URL {
        directory.appending(path: fileName)
    }

    /// Downscales and writes the image as JPEG; returns the file name.
    func save(_ image: UIImage) throws -> String {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        guard let data = Self.downscaled(image).jpegData(compressionQuality: Self.jpegQuality) else {
            throw CocoaError(.fileWriteUnknown)
        }
        let fileName = "\(UUID().uuidString).jpg"
        try data.write(to: url(for: fileName), options: [.atomic, .completeFileProtection])
        return fileName
    }

    func load(_ fileName: String) -> UIImage? {
        UIImage(contentsOfFile: url(for: fileName).path(percentEncoded: false))
    }

    func delete(_ fileName: String) {
        try? FileManager.default.removeItem(at: url(for: fileName))
    }

    /// The image scaled so its longest side is at most `maxDimension`.
    static func downscaled(_ image: UIImage) -> UIImage {
        let size = image.size
        let longest = max(size.width, size.height)
        guard longest > maxDimension else { return image }
        let scale = maxDimension / longest
        let target = CGSize(width: (size.width * scale).rounded(), height: (size.height * scale).rounded())
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        return UIGraphicsImageRenderer(size: target, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: target))
        }
    }

    /// Photos grouped by month, newest first.
    static func months(of photos: [ProgressPhoto], calendar: Calendar = .current) -> [(month: Date, photos: [ProgressPhoto])] {
        let sorted = photos.sorted { $0.date > $1.date }
        let grouped = Dictionary(grouping: sorted) { calendar.dateInterval(of: .month, for: $0.date)?.start ?? $0.date }
        return grouped.keys.sorted(by: >).map { ($0, grouped[$0] ?? []) }
    }
}
