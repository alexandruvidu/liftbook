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
}
