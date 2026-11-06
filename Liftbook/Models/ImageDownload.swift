import Foundation
import Observation
import SwiftData

/// One exercise in the free-exercise-db manifest (only the fields we use).
struct DatasetExercise: Decodable, Equatable, Sendable {
    let id: String
    let name: String
    /// Paths relative to the images base URL, e.g. "Air_Bike/0.jpg".
    let images: [String]
}

/// Matches catalog exercises to dataset exercises by name.
enum ImageMatching {
    /// Lowercase, punctuation and filler words removed, plurals folded:
    /// "Barbell Bench Press - Medium Grip" → "barbell bench pres medium grip".
    static func normalize(_ name: String) -> String {
        let spaced = name.lowercased().replacingOccurrences(of: "-", with: " ")
        let cleaned = String(spaced.map { $0.isLetter || $0.isNumber ? $0 : " " })
        return cleaned.split(separator: " ")
            .map(String.init)
            .filter { !["the", "a", "with", "and"].contains($0) }
            .map { $0.count > 3 && $0.hasSuffix("s") ? String($0.dropLast()) : $0 }
            .joined(separator: " ")
    }

    /// Catalog exercise ID → its dataset exercise. Aliases win; otherwise the
    /// normalized names must be equal.
    static func match(catalog: [LibraryExercise], dataset: [DatasetExercise]) -> [String: DatasetExercise] {
        let byID = Dictionary(dataset.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        let byName = Dictionary(dataset.map { (normalize($0.name), $0) }, uniquingKeysWith: { first, _ in first })
        var result: [String: DatasetExercise] = [:]
        for exercise in catalog {
            if let alias = aliases[exercise.id], let found = byID[alias] {
                result[exercise.id] = found
            } else if let found = byName[normalize(exercise.name)] {
                result[exercise.id] = found
            }
        }
        return result
    }
}

/// Fetches bytes from a URL; the real one is `URLSession`, tests use a fake.
protocol DataLoader: Sendable {
    func load(_ url: URL) async throws -> Data
}

extension URLSession: DataLoader {
    func load(_ url: URL) async throws -> Data {
        let (data, response) = try await data(from: url)
        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            throw URLError(.badServerResponse)
        }
        return data
    }
}

/// Downloads exercise photos from the free-exercise-db project onto the
/// phone. Nothing is bundled with the app; each photo is saved as soon as it
/// arrives, so a failed run keeps what it already got.
@MainActor
@Observable
final class ImageDownloader {
    static let manifestURL = URL(string: "https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/dist/exercises.json")!
    static let imagesBaseURL = URL(string: "https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/")!
    /// Start and end position.
    static let imagesPerExercise = 2

    private(set) var progress: Double = 0
    private(set) var isRunning = false
    private(set) var error: String?

    func run(context: ModelContext, catalog: [LibraryExercise], store: MediaStore = .standard,
             loader: DataLoader = URLSession.shared) async {
        guard !isRunning else { return }
        isRunning = true
        error = nil
        progress = 0
        defer { isRunning = false }
        do {
            let dataset = try JSONDecoder().decode([DatasetExercise].self, from: try await loader.load(Self.manifestURL))
            let have = Set(downloaded(in: context).map(\.exerciseID))
            let todo = ImageMatching.match(catalog: catalog, dataset: dataset)
                .filter { !have.contains($0.key) }
                .sorted { $0.key < $1.key }
            for (index, (exerciseID, entry)) in todo.enumerated() {
                for (position, path) in entry.images.prefix(Self.imagesPerExercise).enumerated() {
                    let data = try await loader.load(Self.imagesBaseURL.appending(path: path))
                    let name = try store.saveImageData(data)
                    context.insert(ExerciseMedia(exerciseID: exerciseID, kind: .photo, source: .downloaded,
                                                 fileName: name, position: position))
                    try context.save()
                }
                progress = Double(index + 1) / Double(todo.count)
            }
            progress = 1
        } catch {
            self.error = "The download stopped. Photos already saved are kept; try again to get the rest."
        }
    }

    /// Deletes every downloaded photo; the user's own media stays.
    func removeAll(context: ModelContext, store: MediaStore = .standard) {
        for item in downloaded(in: context) {
            store.delete(item.fileName)
            context.delete(item)
        }
        try? context.save()
        progress = 0
    }

    func downloaded(in context: ModelContext) -> [ExerciseMedia] {
        let source = MediaSource.downloaded.rawValue
        return (try? context.fetch(FetchDescriptor<ExerciseMedia>(predicate: #Predicate { $0.sourceID == source }))) ?? []
    }
}
