import Foundation
import SwiftData
import Testing
import UIKit
@testable import Liftbook

struct ExerciseMediaTests {
    private func media(_ exerciseID: String, _ source: MediaSource, position: Int, name: String) -> ExerciseMedia {
        ExerciseMedia(exerciseID: exerciseID, kind: .photo, source: source, fileName: name, position: position)
    }

    private func temporaryStore() -> MediaStore {
        MediaStore(directory: URL.temporaryDirectory.appending(path: "media-\(UUID().uuidString)", directoryHint: .isDirectory))
    }

    @Test func ownBeforeDownloaded() {
        let all = [media("bench", .downloaded, position: 0, name: "d0"), media("bench", .own, position: 0, name: "o0")]
        #expect(all.display(for: "bench").map(\.fileName) == ["o0", "d0"])
    }

    @Test func orderedByPosition() {
        let all = [media("bench", .own, position: 2, name: "o2"), media("bench", .own, position: 0, name: "o0"),
                   media("bench", .downloaded, position: 1, name: "d1"), media("bench", .downloaded, position: 0, name: "d0")]
        #expect(all.display(for: "bench").map(\.fileName) == ["o0", "o2", "d0", "d1"])
    }

    @Test func otherExercisesExcluded() {
        let all = [media("bench", .own, position: 0, name: "b"), media("squat", .own, position: 0, name: "s")]
        #expect(all.display(for: "squat").map(\.fileName) == ["s"])
    }

    @Test func saveVideoCopiesFile() throws {
        let store = temporaryStore()
        let source = URL.temporaryDirectory.appending(path: "clip-\(UUID().uuidString).mov")
        try Data("not really a video".utf8).write(to: source)
        let name = try store.saveVideo(from: source)
        #expect(name.hasSuffix(".mov"))
        #expect(FileManager.default.fileExists(atPath: store.url(for: name).path(percentEncoded: false)))
        #expect(FileManager.default.fileExists(atPath: source.path(percentEncoded: false)), "Original was moved")
    }

    @Test func deleteRemovesFile() throws {
        let store = temporaryStore()
        let name = try store.saveImageData(Data([0xFF, 0xD8, 0xFF]))
        store.delete(name)
        #expect(!FileManager.default.fileExists(atPath: store.url(for: name).path(percentEncoded: false)))
    }

    @Test func kindAndSourceRoundTrip() {
        let item = ExerciseMedia(exerciseID: "x", kind: .video, source: .downloaded, fileName: "f", position: 0)
        #expect(item.kind == .video)
        #expect(item.source == .downloaded)
    }
}

@MainActor
struct DownloadedMediaCleanupTests {
    @Test func removesDownloadedKeepsOwn() throws {
        let context = Persistence.makeContainer(inMemory: true).mainContext
        let store = MediaStore(directory: URL.temporaryDirectory.appending(path: "clean-\(UUID().uuidString)", directoryHint: .isDirectory))
        let downloaded = try store.saveImageData(Data([0xFF, 0xD8]))
        context.insert(ExerciseMedia(exerciseID: "x", kind: .photo, source: .downloaded, fileName: downloaded, position: 0))
        context.insert(ExerciseMedia(exerciseID: "x", kind: .photo, source: .own, fileName: "mine.jpg", position: 0))
        try context.save()

        ExerciseMedia.removeDownloaded(in: context, store: store)
        #expect(try context.fetch(FetchDescriptor<ExerciseMedia>()).map(\.fileName) == ["mine.jpg"])
        #expect(!FileManager.default.fileExists(atPath: store.url(for: downloaded).path(percentEncoded: false)))
    }
}
