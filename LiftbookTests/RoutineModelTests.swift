import Foundation
import SwiftData
import Testing
@testable import Liftbook

@MainActor
struct RoutineModelTests {
    private let container: ModelContainer
    private let context: ModelContext

    init() {
        container = Persistence.makeContainer(inMemory: true)
        context = ModelContext(container)
    }

    private func makeRoutine(_ ids: [String], folder: RoutineFolder? = nil) -> Routine {
        var draft = RoutineDraft()
        draft.name = "  Push Day "
        draft.notes = " Heavy week "
        draft.add(ids)
        let routine = Routine()
        context.insert(routine)
        routine.apply(draft, folder: folder, in: context)
        return routine
    }

    private func count<T: PersistentModel>(_ type: T.Type) throws -> Int {
        try context.fetchCount(FetchDescriptor<T>())
    }

    @Test func applyStoresTrimmedFieldsAndOrder() {
        let routine = makeRoutine(["c", "a", "b"])
        #expect(routine.name == "Push Day")
        #expect(routine.notes == "Heavy week")
        #expect(routine.orderedEntries.map(\.exerciseID) == ["c", "a", "b"])
        #expect(routine.orderedEntries.map(\.position) == [0, 1, 2])
    }

    @Test func reapplyingReplacesEntries() throws {
        let routine = makeRoutine(["a", "b", "c"])
        var draft = RoutineDraft(routine: routine)
        draft.move(from: [2], to: 0)
        draft.remove(at: [2])
        draft.entries[0].setCount = 5
        routine.apply(draft, folder: nil, in: context)
        try context.save()

        #expect(routine.orderedEntries.map(\.exerciseID) == ["c", "a"])
        #expect(routine.orderedEntries.first?.setCount == 5)
        #expect(try count(RoutineEntry.self) == 2)
    }

    @Test func draftRoundTripsRoutine() {
        let folder = RoutineFolder(name: "Push", sortIndex: 0)
        context.insert(folder)
        let routine = makeRoutine(["a", "b"], folder: folder)
        let draft = RoutineDraft(routine: routine)
        #expect(draft.name == "Push Day")
        #expect(draft.folderID == folder.folderID)
        #expect(draft.entries.map(\.exerciseID) == ["a", "b"])
    }

    @Test func deletingFolderKeepsRoutines() throws {
        let folder = RoutineFolder(name: " Legs ", sortIndex: 0)
        context.insert(folder)
        #expect(folder.name == "Legs")
        let routine = makeRoutine(["a"], folder: folder)
        try context.save()

        context.delete(folder)
        try context.save()

        #expect(try count(RoutineFolder.self) == 0)
        #expect(try count(Routine.self) == 1)
        #expect(routine.folder == nil)
    }

    @Test func deletingRoutineDeletesEntries() throws {
        let routine = makeRoutine(["a", "b"])
        try context.save()
        #expect(try count(RoutineEntry.self) == 2)

        context.delete(routine)
        try context.save()
        #expect(try count(Routine.self) == 0)
        #expect(try count(RoutineEntry.self) == 0)
    }
}
