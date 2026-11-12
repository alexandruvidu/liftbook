import Foundation
import SwiftData
import Testing
@testable import Liftbook

@MainActor
struct RoutineFromWorkoutTests {
    private let container = Persistence.makeContainer(inMemory: true)

    @Test func copiesExercisesWorkingSetsAndMachines() {
        let session = WorkoutSession(name: "Back Day")
        container.mainContext.insert(session)
        session.addExercises(["row", "curl"], setCount: 1)
        let (row, curl) = (session.orderedExercises[0], session.orderedExercises[1])
        _ = row.addSet()
        _ = row.addSet()
        row.orderedSets[0].kind = .warmUp
        let machine = UUID()
        curl.machineID = machine

        let draft = RoutineDraft(session: session)
        #expect(draft.name == "Back Day")
        #expect(draft.entries.map(\.exerciseID) == ["row", "curl"])
        // The warm-up isn't a planned set.
        #expect(draft.entries.map(\.setCount) == [2, 1])
        #expect(draft.entries.map(\.machineID) == [nil, machine])
        #expect(draft.problems.isEmpty)
    }

    @Test func onlyWarmUpsStillPlansOneSet() {
        let session = WorkoutSession(name: "W")
        container.mainContext.insert(session)
        session.addExercises(["row"], setCount: 1)
        session.orderedExercises[0].orderedSets[0].kind = .warmUp
        #expect(RoutineDraft(session: session).entries.map(\.setCount) == [1])
    }

    @Test func moveByIDPlacesBeforeTargetOrAtEnd() {
        var draft = RoutineDraft()
        draft.add(["a", "b", "c"])
        let ids = draft.entries.map(\.id)
        draft.move([ids[2]], before: ids[0])
        #expect(draft.entries.map(\.exerciseID) == ["c", "a", "b"])
        draft.move([ids[2]], before: nil)
        #expect(draft.entries.map(\.exerciseID) == ["a", "b", "c"])
    }
}
