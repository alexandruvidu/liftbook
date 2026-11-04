import Foundation

/// The exercises bundled with the app in `exercises.json`.
struct ExerciseLibrary: Sendable {
    struct Section: Identifiable, Hashable, Sendable {
        let letter: String
        let exercises: [LibraryExercise]
        var id: String { letter }
    }

    let exercises: [LibraryExercise]

    init(exercises: [LibraryExercise]) {
        self.exercises = exercises.sorted {
            $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }
    }

    init(data: Data) throws {
        self.init(exercises: try JSONDecoder().decode([LibraryExercise].self, from: data))
    }

    /// The library shipped in the app bundle.
    static let bundled: ExerciseLibrary = {
        guard let url = Bundle.main.url(forResource: "exercises", withExtension: "json") else {
            fatalError("exercises.json is missing from the app bundle")
        }
        do {
            return try ExerciseLibrary(data: Data(contentsOf: url))
        } catch {
            fatalError("exercises.json could not be decoded: \(error)")
        }
    }()

    func exercise(id: String) -> LibraryExercise? {
        exercises.first { $0.id == id }
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
