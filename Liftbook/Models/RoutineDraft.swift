import Foundation

/// Editable copy of a routine. Changes only reach SwiftData when saved.
struct RoutineDraft: Equatable, Sendable {
    struct Entry: Identifiable, Equatable, Sendable {
        let id: UUID
        var exerciseID: String
        var setCount: Int
        /// The machine to start on; nil = whichever was used last.
        var machineID: UUID?

        init(exerciseID: String, setCount: Int = RoutineDraft.defaultSetCount, machineID: UUID? = nil) {
            id = UUID()
            self.exerciseID = exerciseID
            self.setCount = setCount
            self.machineID = machineID
        }
    }

    enum Problem: Equatable, Sendable {
        case missingName
        case noExercises

        var message: String {
            switch self {
            case .missingName: "Give the routine a name."
            case .noExercises: "Add at least one exercise."
            }
        }
    }

    static let defaultSetCount = 3
    static let setCountRange = 1...20

    var name = ""
    var notes = ""
    var folderID: UUID?
    var entries: [Entry] = []

    init() {}

    init(routine: Routine) {
        name = routine.name
        notes = routine.notes
        folderID = routine.folder?.folderID
        entries = routine.orderedEntries.map { Entry(exerciseID: $0.exerciseID, setCount: $0.setCount, machineID: $0.machineID) }
    }

    /// A new routine copying a past workout: its name, exercises in order,
    /// machines, and how many sets of each, not counting warm-ups.
    init(session: WorkoutSession) {
        name = session.displayName
        entries = session.orderedExercises.map { exercise in
            let working = exercise.sets.filter { $0.kind != .warmUp }.count
            let count = min(max(working, RoutineDraft.setCountRange.lowerBound), RoutineDraft.setCountRange.upperBound)
            return Entry(exerciseID: exercise.exerciseID, setCount: count, machineID: exercise.machineID)
        }
    }

    var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var problems: [Problem] {
        var problems: [Problem] = []
        if trimmedName.isEmpty { problems.append(.missingName) }
        if entries.isEmpty { problems.append(.noExercises) }
        return problems
    }

    mutating func add(_ exerciseIDs: [String]) {
        entries += exerciseIDs.map { Entry(exerciseID: $0) }
    }

    mutating func remove(at offsets: IndexSet) {
        for index in offsets.sorted(by: >) where entries.indices.contains(index) {
            entries.remove(at: index)
        }
    }

    /// Same semantics as SwiftUI's `move(fromOffsets:toOffset:)`: `destination`
    /// is an index in the list before the move.
    mutating func move(from source: IndexSet, to destination: Int) {
        let moving = source.sorted().filter(entries.indices.contains).map { entries[$0] }
        let shift = source.filter { $0 < destination }.count
        remove(at: source)
        let insertAt = min(max(destination - shift, 0), entries.count)
        entries.insert(contentsOf: moving, at: insertAt)
    }

    /// Moves the entries with `ids` (keeping their order) to just before the
    /// entry `target`, or to the end when `target` is nil.
    mutating func move(_ ids: [UUID], before target: UUID?) {
        let moving = entries.filter { ids.contains($0.id) }
        guard !moving.isEmpty else { return }
        entries.removeAll { ids.contains($0.id) }
        let index = target.flatMap { target in entries.firstIndex { $0.id == target } } ?? entries.endIndex
        entries.insert(contentsOf: moving, at: index)
    }
}
