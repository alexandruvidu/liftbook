import Foundation

/// Search text plus optional muscle and equipment filters for the exercise list.
struct ExerciseFilter: Equatable, Sendable {
    var query: String = ""
    /// Matches exercises whose primary muscles include this one.
    var muscle: Muscle?
    var equipment: Equipment?

    /// Whether a muscle or equipment filter is set (search text has its own clear button).
    var hasMenuFilters: Bool {
        muscle != nil || equipment != nil
    }

    mutating func clearMenuFilters() {
        muscle = nil
        equipment = nil
    }

    func matches(_ exercise: LibraryExercise) -> Bool {
        if let muscle, !exercise.primaryMuscles.contains(muscle) { return false }
        if let equipment, exercise.equipment != equipment { return false }

        let words = Self.tokens(in: query)
        guard !words.isEmpty else { return true }
        let haystack = Self.normalize(
            ([exercise.name, exercise.equipment.displayName] + exercise.primaryMuscles.map(\.displayName))
                .joined(separator: " ")
        )
        return words.allSatisfy { haystack.contains($0) }
    }

    func apply(to exercises: [LibraryExercise]) -> [LibraryExercise] {
        exercises.filter(matches)
    }

    /// Lowercases, strips accents, and drops hyphens and apostrophes so that
    /// "Pull-Up", "pull up" and "pullup" all match.
    static func normalize(_ text: String) -> String {
        text.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: nil)
            .replacingOccurrences(of: "-", with: "")
            .replacingOccurrences(of: "'", with: "")
            .replacingOccurrences(of: "’", with: "")
    }

    static func tokens(in query: String) -> [String] {
        normalize(query).split(whereSeparator: \.isWhitespace).map(String.init)
    }
}
