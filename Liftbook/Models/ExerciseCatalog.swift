import Foundation

/// Bundled and custom exercises together, looked up by ID.
struct ExerciseCatalog {
    let exercises: [LibraryExercise]
    private let byID: [String: LibraryExercise]

    init(library: ExerciseLibrary = .bundled, custom: [LibraryExercise]) {
        exercises = ExerciseLibrary(exercises: library.exercises + custom).exercises
        byID = Dictionary(exercises.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
    }

    func exercise(id: String) -> LibraryExercise? {
        byID[id]
    }

    /// The exercise name, or a placeholder if it was deleted.
    func name(for id: String) -> String {
        byID[id]?.name ?? "Deleted exercise"
    }
}
