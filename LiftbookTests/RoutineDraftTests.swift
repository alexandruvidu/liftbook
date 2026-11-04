import Foundation
import Testing
@testable import Liftbook

struct RoutineDraftTests {
    private func draft(_ ids: [String]) -> RoutineDraft {
        var draft = RoutineDraft()
        draft.name = "Push Day"
        draft.add(ids)
        return draft
    }

    private func ids(_ draft: RoutineDraft) -> [String] {
        draft.entries.map(\.exerciseID)
    }

    @Test func newDraftNeedsNameAndExercises() {
        #expect(RoutineDraft().problems == [.missingName, .noExercises])
        #expect(draft(["a"]).problems.isEmpty)
    }

    @Test func addAppendsWithDefaultSets() {
        let draft = draft(["a", "b"])
        #expect(ids(draft) == ["a", "b"])
        #expect(draft.entries.allSatisfy { $0.setCount == RoutineDraft.defaultSetCount })
    }

    @Test func sameExerciseCanAppearTwice() {
        let draft = draft(["a", "a"])
        #expect(draft.entries.count == 2)
        #expect(draft.entries[0].id != draft.entries[1].id)
    }

    @Test(arguments: [
        (IndexSet([0]), 3, ["b", "c", "a", "d"]),
        (IndexSet([0]), 4, ["b", "c", "d", "a"]),
        (IndexSet([3]), 0, ["d", "a", "b", "c"]),
        (IndexSet([1, 2]), 4, ["a", "d", "b", "c"]),
        (IndexSet([2]), 1, ["a", "c", "b", "d"]),
        (IndexSet([1]), 1, ["a", "b", "c", "d"]),
    ])
    func moveMatchesSwiftUISemantics(source: IndexSet, destination: Int, expected: [String]) {
        var draft = draft(["a", "b", "c", "d"])
        draft.move(from: source, to: destination)
        #expect(ids(draft) == expected)
    }

    @Test func removeDropsEntries() {
        var draft = draft(["a", "b", "c", "d"])
        draft.remove(at: IndexSet([0, 2]))
        #expect(ids(draft) == ["b", "d"])
        draft.remove(at: IndexSet([9]))
        #expect(ids(draft) == ["b", "d"])
    }

    @Test func routineSummaryTruncates() {
        #expect(RoutineRow.summary(of: ["A", "B"]) == "A, B")
        #expect(RoutineRow.summary(of: ["A", "B", "C"]) == "A, B, C")
        #expect(RoutineRow.summary(of: ["A", "B", "C", "D", "E"]) == "A, B +3 more")
    }

    @Test func catalogNamesDeletedExercises() {
        let catalog = ExerciseCatalog(custom: [])
        #expect(catalog.name(for: "barbell-bench-press") == "Barbell Bench Press")
        #expect(catalog.name(for: "custom-gone") == "Deleted exercise")
    }
}
