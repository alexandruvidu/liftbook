import Foundation
import SwiftData

/// A named group of routines, e.g. "Push / Pull / Legs".
@Model
final class RoutineFolder {
    @Attribute(.unique) var folderID: UUID
    var name: String
    var sortIndex: Int
    /// Deleting a folder keeps its routines; they become unfiled.
    @Relationship(deleteRule: .nullify, inverse: \Routine.folder)
    var routines: [Routine] = []

    init(name: String, sortIndex: Int) {
        folderID = UUID()
        self.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        self.sortIndex = sortIndex
    }
}

/// A saved plan of exercises that a workout can be started from.
@Model
final class Routine {
    @Attribute(.unique) var routineID: UUID
    var name: String
    var notes: String
    var folder: RoutineFolder?
    @Relationship(deleteRule: .cascade, inverse: \RoutineEntry.routine)
    var entries: [RoutineEntry] = []
    var createdAt: Date
    var updatedAt: Date

    init(name: String = "", createdAt: Date = .now) {
        routineID = UUID()
        self.name = name
        notes = ""
        self.createdAt = createdAt
        updatedAt = createdAt
    }

    /// Entries in the order the user arranged them.
    var orderedEntries: [RoutineEntry] {
        entries.sorted { $0.position < $1.position }
    }

    /// Replaces this routine's contents with the draft. The routine must
    /// already be inserted into `context`.
    func apply(_ draft: RoutineDraft, folder: RoutineFolder?, in context: ModelContext) {
        name = draft.trimmedName
        notes = draft.notes.trimmingCharacters(in: .whitespacesAndNewlines)
        self.folder = folder
        updatedAt = .now

        for entry in entries {
            context.delete(entry)
        }
        entries = draft.entries.enumerated().map { index, entry in
            RoutineEntry(exerciseID: entry.exerciseID, position: index, setCount: entry.setCount)
        }
    }
}

/// One exercise within a routine.
@Model
final class RoutineEntry {
    var exerciseID: String
    var position: Int
    var setCount: Int
    var routine: Routine?

    init(exerciseID: String, position: Int, setCount: Int) {
        self.exerciseID = exerciseID
        self.position = position
        self.setCount = setCount
    }
}
