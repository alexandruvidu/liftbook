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

    /// The matching exercises. With search text, the best matches come first:
    /// the exact name, then names starting with the text, then names holding
    /// every word, then matches through muscle or equipment. Within each,
    /// featured (everyday) exercises first, then shorter, more basic names.
    /// Without text, the order is kept.
    func apply(to exercises: [LibraryExercise],
               featured: Set<String> = ExerciseLibrary.bundled.featuredIDs) -> [LibraryExercise] {
        let matching = exercises.filter(matches)
        let words = Self.tokens(in: query)
        guard !words.isEmpty else { return matching }
        let joined = words.joined()
        let ranked = matching.map { exercise -> (exercise: LibraryExercise, rank: Int, featured: Int, length: Int) in
            let nameWords = Self.tokens(in: exercise.name)
            let name = nameWords.joined()
            let rank = name == joined ? 0
                : name.hasPrefix(joined) ? 1
                : words.allSatisfy { word in nameWords.contains { $0.hasPrefix(word) } } ? 2
                : words.allSatisfy { name.contains($0) } ? 3
                : 4
            return (exercise, rank, featured.contains(exercise.id) ? 0 : 1, exercise.name.count)
        }
        // Sorting is stable, so equal matches keep the library's A–Z order.
        return ranked.sorted { ($0.rank, $0.featured, $0.length) < ($1.rank, $1.featured, $1.length) }.map(\.exercise)
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
