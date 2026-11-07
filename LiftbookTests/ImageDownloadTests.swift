import Foundation
import SwiftData
import Testing
@testable import Liftbook

/// Serves canned bytes for URLs; throws for the ones listed in `failing`.
private struct FakeLoader: DataLoader {
    let manifest: Data
    var failing: Set<String> = []
    /// What the failing URLs throw: offline by default.
    var failure: URLError.Code = .notConnectedToInternet

    func load(_ url: URL) async throws -> Data {
        if failing.contains(url.lastPathComponent) || failing.contains(url.deletingLastPathComponent().lastPathComponent + "/" + url.lastPathComponent) {
            throw URLError(failure)
        }
        if url == ImageDownloader.manifestURL { return manifest }
        return Data([0xFF, 0xD8, 0xFF, 0xE0])
    }
}

@MainActor
struct ImageDownloadTests {
    private let container = Persistence.makeContainer(inMemory: true)
    private var context: ModelContext { container.mainContext }
    private let store = MediaStore(directory: URL.temporaryDirectory.appending(path: "dl-\(UUID().uuidString)", directoryHint: .isDirectory))

    private func exercise(_ id: String, _ name: String) -> LibraryExercise {
        LibraryExercise(id: id, name: name, primaryMuscles: [.chest], secondaryMuscles: [],
                        equipment: .barbell, type: .weightAndReps, details: "")
    }

    private var catalog: [LibraryExercise] {
        [exercise("barbell-bench-press", "Barbell Bench Press"), exercise("air-bike", "Air Bike"),
         exercise("burpee", "Burpee")]
    }

    private func manifest() throws -> Data {
        let items = [
            ["id": "Barbell_Bench_Press_-_Medium_Grip", "name": "Barbell Bench Press - Medium Grip",
             "images": ["Barbell_Bench_Press_-_Medium_Grip/0.jpg", "Barbell_Bench_Press_-_Medium_Grip/1.jpg"]],
            ["id": "Air_Bike", "name": "Air Bike", "images": ["Air_Bike/0.jpg", "Air_Bike/1.jpg"]],
        ] as [[String: Any]]
        return try JSONSerialization.data(withJSONObject: items)
    }

    private func media() throws -> [ExerciseMedia] {
        try context.fetch(FetchDescriptor<ExerciseMedia>())
    }

    @Test func normalizeIgnoresCaseAndPunctuation() {
        #expect(ImageMatching.normalize("Farmer's Carry") == ImageMatching.normalize("farmer s carry"))
        #expect(ImageMatching.normalize("Push-Ups") == "push ups")
        #expect(ImageMatching.normalize("The Barbell Rows") == "barbell row")
    }

    @Test func matchUsesAliasFirst() {
        let dataset = [DatasetExercise(id: "Barbell_Bench_Press_-_Medium_Grip", name: "Barbell Bench Press - Medium Grip", images: []),
                       DatasetExercise(id: "Barbell_Bench_Press", name: "Barbell Bench Press", images: [])]
        let matched = ImageMatching.match(catalog: catalog, dataset: dataset)
        #expect(matched["barbell-bench-press"]?.id == "Barbell_Bench_Press_-_Medium_Grip")
    }

    @Test func matchByNameAndUnmatchedLeftOut() {
        let dataset = [DatasetExercise(id: "Air_Bike", name: "Air Bike", images: [])]
        let matched = ImageMatching.match(catalog: catalog, dataset: dataset)
        #expect(matched["air-bike"]?.id == "Air_Bike")
        #expect(matched["burpee"] == nil)
    }

    @Test func aliasesPointAtRealCatalogExercises() {
        let ids = Set(ExerciseLibrary.bundled.exercises.map(\.id))
        #expect(ImageMatching.aliases.keys.allSatisfy(ids.contains))
    }

    @Test func downloadSavesTwoImagesPerExercise() async throws {
        let downloader = ImageDownloader()
        await downloader.run(context: context, catalog: catalog, store: store, loader: FakeLoader(manifest: try manifest()))
        let saved = try media()
        #expect(downloader.error == nil)
        #expect(saved.count == 4)
        #expect(Set(saved.map(\.exerciseID)) == ["barbell-bench-press", "air-bike"])
        #expect(saved.allSatisfy { $0.source == .downloaded })
        #expect(downloader.progress == 1)
    }

    @Test func failureKeepsEarlierImages() async throws {
        // Exercises go alphabetically: air-bike first, then bench press, whose
        // second image fails.
        let downloader = ImageDownloader()
        let loader = FakeLoader(manifest: try manifest(), failing: ["Barbell_Bench_Press_-_Medium_Grip/1.jpg"])
        await downloader.run(context: context, catalog: catalog, store: store, loader: loader)
        let saved = try media()
        #expect(downloader.error != nil)
        #expect(saved.filter { $0.exerciseID == "air-bike" }.count == 2)
        #expect(saved.filter { $0.exerciseID == "barbell-bench-press" }.count == 1)
        #expect(!downloader.isRunning)
    }

    @Test func rerunSkipsDownloaded() async throws {
        let downloader = ImageDownloader()
        let loader = FakeLoader(manifest: try manifest())
        await downloader.run(context: context, catalog: catalog, store: store, loader: loader)
        await downloader.run(context: context, catalog: catalog, store: store, loader: loader)
        #expect(try media().count == 4)
    }

    @Test func removeAllDeletesOnlyDownloaded() async throws {
        context.insert(ExerciseMedia(exerciseID: "barbell-bench-press", kind: .photo, source: .own, fileName: "mine.jpg", position: 0))
        let downloader = ImageDownloader()
        await downloader.run(context: context, catalog: catalog, store: store, loader: FakeLoader(manifest: try manifest()))
        downloader.removeAll(context: context, store: store)
        let left = try media()
        #expect(left.map(\.fileName) == ["mine.jpg"])
    }

    @Test func missingImageIsSkippedNotFatal() async throws {
        // A 404-style failure on one image: the rest still download.
        let downloader = ImageDownloader()
        let loader = FakeLoader(manifest: try manifest(), failing: ["Air_Bike/0.jpg"], failure: .badServerResponse)
        await downloader.run(context: context, catalog: catalog, store: store, loader: loader)
        #expect(downloader.error == nil)
        #expect(downloader.skipped == 1)
        #expect(try media().count == 3)
    }

    @Test func retryFillsInAPartlyDownloadedExercise() async throws {
        let downloader = ImageDownloader()
        let cutOff = FakeLoader(manifest: try manifest(), failing: ["Barbell_Bench_Press_-_Medium_Grip/1.jpg"])
        await downloader.run(context: context, catalog: catalog, store: store, loader: cutOff)
        #expect(try media().filter { $0.exerciseID == "barbell-bench-press" }.count == 1)

        await downloader.run(context: context, catalog: catalog, store: store, loader: FakeLoader(manifest: try manifest()))
        let bench = try media().filter { $0.exerciseID == "barbell-bench-press" }
        #expect(bench.map(\.position).sorted() == [0, 1])
        #expect(try media().count == 4)
    }
}
