import Foundation
import Testing
@testable import Liftbook

struct ExerciseArtTests {
    private func folder(with names: [String]) throws -> URL {
        let directory = URL.temporaryDirectory.appending(path: "art-\(UUID().uuidString)", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        for name in names {
            try Data([0]).write(to: directory.appending(path: name))
        }
        return directory
    }

    @Test func startAndPeakMakeTwoPoses() throws {
        let directory = try folder(with: ["bench-start.webp", "bench-peak.webp"])
        #expect(ExerciseArt.of("bench", in: directory)
            == .poses(start: directory.appending(path: "bench-start.webp"), peak: directory.appending(path: "bench-peak.webp")))
    }

    @Test func mainPoseStandsAlone() throws {
        let directory = try folder(with: ["plank-main.webp"])
        #expect(ExerciseArt.of("plank", in: directory) == .poses(start: directory.appending(path: "plank-main.webp"), peak: nil))
    }

    @Test func illustrationWinsOverAnimation() throws {
        let directory = try folder(with: ["row-start.webp", "row-peak.webp", "row.gif"])
        guard case .poses = ExerciseArt.of("row", in: directory) else {
            Issue.record("expected the illustration")
            return
        }
    }

    @Test func animationWhenNoIllustration() throws {
        let directory = try folder(with: ["sissy-squat.gif"])
        #expect(ExerciseArt.of("sissy-squat", in: directory) == .animation(directory.appending(path: "sissy-squat.gif")))
    }

    @Test func nothingWithoutFiles() throws {
        let directory = try folder(with: ["bench-start.webp"])
        #expect(ExerciseArt.of("squat", in: directory) == nil)
        #expect(ExerciseArt.of("bench", in: nil) == nil)
    }

    /// Each mapped exercise exists in the catalog, and no exercise is in both
    /// mappings (the illustration would hide the animation).
    @Test func mappingsMatchTheCatalog() throws {
        func keys(_ resource: String) throws -> Set<String> {
            let url = try #require(Bundle.main.url(forResource: resource, withExtension: "json"))
            let object = try JSONSerialization.jsonObject(with: Data(contentsOf: url))
            return Set(try #require(object as? [String: Any]).keys)
        }
        let illustrated = try keys("exercise-illustrations")
        let animated = try keys("exercise-animations")
        let catalog = Set(ExerciseLibrary.bundled.exercises.map(\.id))
        #expect(illustrated.subtracting(catalog).isEmpty)
        #expect(animated.subtracting(catalog).isEmpty)
        #expect(illustrated.isDisjoint(with: animated))
        #expect(illustrated.count >= 190)
    }
}
