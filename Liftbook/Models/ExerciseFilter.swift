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
    /// every word, then matches through muscle or equipment. Among name
    /// matches, featured (everyday) exercises come first; shorter, more basic
    /// names first within each.
    /// Without text, the order is kept.
    func apply(to exercises: [LibraryExercise],
               featured: Set<String> = ExerciseLibrary.bundled.featuredIDs) -> [LibraryExercise] {
        let matching = exercises.filter(matches)
        let words = Self.tokens(in: query)
        guard !words.isEmpty else { return matching }
        // Nothing matched as typed: try again allowing small typos ("bnech pres").
        if matching.isEmpty { return fuzzyMatches(in: exercises, words: words, featured: featured) }
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
        // The exact name, then name matches (everyday exercises first), then the rest.
        func key(_ r: (exercise: LibraryExercise, rank: Int, featured: Int, length: Int)) -> (Int, Int, Int, Int, Int) {
            (r.rank == 0 ? 0 : 1, r.rank >= 3 ? 1 : 0, r.featured, r.rank, r.length)
        }
        return ranked.sorted { key($0) < key($1) }.map(\.exercise)
    }

    /// Exercises whose name has, for every search word, a word within a small
    /// edit distance (1 for 4–6 letters, 2 from 7), closest first. Words of
    /// three letters or fewer must match exactly. Menu filters still apply.
    func fuzzyMatches(in exercises: [LibraryExercise], words: [String], featured: Set<String>) -> [LibraryExercise] {
        func allowed(_ word: String) -> Int { word.count >= 7 ? 2 : word.count >= 4 ? 1 : 0 }
        var found: [(exercise: LibraryExercise, distance: Int)] = []
        for exercise in exercises {
            if let muscle, !exercise.primaryMuscles.contains(muscle) { continue }
            if let equipment, exercise.equipment != equipment { continue }
            let nameWords = Self.tokens(in: exercise.name)
            var total = 0
            var matchesAll = true
            for word in words {
                // Also against same-length prefixes, so a half-typed word still counts.
                let best = nameWords.map { min(Self.distance(word, $0), Self.distance(word, String($0.prefix(word.count)))) }.min() ?? .max
                guard best <= allowed(word) else { matchesAll = false; break }
                total += best
            }
            if matchesAll { found.append((exercise, total)) }
        }
        return found.sorted { lhs, rhs in
            if lhs.distance != rhs.distance { return lhs.distance < rhs.distance }
            let lf = featured.contains(lhs.exercise.id), rf = featured.contains(rhs.exercise.id)
            if lf != rf { return lf }
            return lhs.exercise.name.count < rhs.exercise.name.count
        }.map(\.exercise)
    }

    /// Edit distance between two short words, counting two swapped
    /// neighbouring letters ("bnech") as one typo (optimal string alignment).
    static func distance(_ a: String, _ b: String) -> Int {
        let a = Array(a), b = Array(b)
        if a.isEmpty { return b.count }
        if b.isEmpty { return a.count }
        var d = Array(repeating: Array(repeating: 0, count: b.count + 1), count: a.count + 1)
        for i in 0...a.count { d[i][0] = i }
        for j in 0...b.count { d[0][j] = j }
        for i in 1...a.count {
            for j in 1...b.count {
                let cost = a[i - 1] == b[j - 1] ? 0 : 1
                d[i][j] = min(d[i - 1][j] + 1, d[i][j - 1] + 1, d[i - 1][j - 1] + cost)
                if i > 1, j > 1, a[i - 1] == b[j - 2], a[i - 2] == b[j - 1] {
                    d[i][j] = min(d[i][j], d[i - 2][j - 2] + 1)
                }
            }
        }
        return d[a.count][b.count]
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
