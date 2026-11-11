import Foundation

/// Bundled and custom exercises together, looked up by ID.
struct ExerciseCatalog {
    let exercises: [LibraryExercise]
    private let byID: [String: LibraryExercise]

    init(library: ExerciseLibrary = .bundled, custom: [LibraryExercise]) {
        // The library is already sorted and indexed: only the few custom
        // exercises are sorted and merged in, since views build this often.
        guard !custom.isEmpty else {
            exercises = library.exercises
            byID = library.byID
            return
        }
        let added = custom.sorted(by: ExerciseLibrary.inOrder)
        var merged: [LibraryExercise] = []
        merged.reserveCapacity(library.exercises.count + added.count)
        var i = library.exercises.startIndex, j = added.startIndex
        while i < library.exercises.endIndex || j < added.endIndex {
            if j == added.endIndex || (i < library.exercises.endIndex && !ExerciseLibrary.inOrder(added[j], library.exercises[i])) {
                merged.append(library.exercises[i])
                i += 1
            } else {
                merged.append(added[j])
                j += 1
            }
        }
        exercises = merged
        byID = library.byID.merging(added.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
    }

    func exercise(id: String) -> LibraryExercise? {
        byID[id] ?? byID[ExerciseAliases.resolve(id)]
    }

    /// The exercise name, or a placeholder if it was deleted.
    func name(for id: String) -> String {
        exercise(id: id)?.name ?? "Deleted exercise"
    }
}
