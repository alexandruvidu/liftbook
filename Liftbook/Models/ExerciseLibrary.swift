import Foundation

/// The exercises bundled with the app: the hand-written ones in
/// `exercises.json`, then the ones merged from free databases in
/// `exercises-more.json` (built by `scripts/build_catalog.py`).
struct ExerciseLibrary: Sendable {
    struct Section: Identifiable, Hashable, Sendable {
        let letter: String
        let exercises: [LibraryExercise]
        var id: String { letter }
    }

    let exercises: [LibraryExercise]
    let byID: [String: LibraryExercise]
    /// The hand-written, everyday exercises: search lists them first among
    /// equally good matches, so "bench press" finds Barbell Bench Press.
    let featuredIDs: Set<String>

    init(exercises: [LibraryExercise], featuredIDs: Set<String> = []) {
        self.exercises = exercises.sorted(by: Self.inOrder)
        byID = Dictionary(self.exercises.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        self.featuredIDs = featuredIDs
    }

    init(data: Data) throws {
        self.init(exercises: try JSONDecoder().decode([LibraryExercise].self, from: data))
    }

    /// The library order: by name, ignoring case.
    static func inOrder(_ a: LibraryExercise, _ b: LibraryExercise) -> Bool {
        a.name.localizedCaseInsensitiveCompare(b.name) == .orderedAscending
    }

    /// Both bundled files together. Exercises with no description of their own
    /// take one from `descriptions` (RepDB text, added to the build by CI).
    static func load(core: Data, more: Data?, descriptions: [String: String] = [:]) throws -> ExerciseLibrary {
        let decoder = JSONDecoder()
        var exercises = try decoder.decode([LibraryExercise].self, from: core)
        let featured = Set(exercises.map(\.id))
        if let more {
            exercises += try decoder.decode([LibraryExercise].self, from: more).map { exercise in
                guard exercise.details.isEmpty, let text = descriptions[exercise.id] else { return exercise }
                return exercise.withDetails(text)
            }
        }
        return ExerciseLibrary(exercises: exercises, featuredIDs: featured)
    }

    /// The library shipped in the app bundle.
    static let bundled: ExerciseLibrary = {
        func data(_ name: String, in subdirectory: String? = nil) -> Data? {
            Bundle.main.url(forResource: name, withExtension: "json", subdirectory: subdirectory)
                .flatMap { try? Data(contentsOf: $0) }
        }
        guard let core = data("exercises") else {
            fatalError("exercises.json is missing from the app bundle")
        }
        let descriptions = data("repdb-descriptions", in: "ExerciseArt")
            .flatMap { try? JSONDecoder().decode([String: String].self, from: $0) } ?? [:]
        do {
            return try load(core: core, more: data("exercises-more"), descriptions: descriptions)
        } catch {
            fatalError("The exercise library could not be decoded: \(error)")
        }
    }()

    func exercise(id: String) -> LibraryExercise? {
        byID[id]
    }

    /// Exercises grouped by the first letter of their name, A–Z.
    var sections: [Section] {
        Self.sections(for: exercises)
    }

    /// Groups already-sorted exercises by first letter, A–Z.
    static func sections(for exercises: [LibraryExercise]) -> [Section] {
        let groups = Dictionary(grouping: exercises) { exercise in
            exercise.name.prefix(1).uppercased()
        }
        return groups.keys.sorted().map { Section(letter: $0, exercises: groups[$0] ?? []) }
    }
}
