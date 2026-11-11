import Foundation
import SwiftData
import Testing
@testable import Liftbook

@MainActor
struct SupersetTests {
    private let container = Persistence.makeContainer(inMemory: true)

    /// A session with exercises "a", "b", "c", "d".
    private func session() -> (WorkoutSession, [WorkoutExercise]) {
        let session = WorkoutSession(name: "W")
        container.mainContext.insert(session)
        session.addExercises(["a", "b", "c", "d"])
        return (session, session.orderedExercises)
    }

    @Test func noSupersetsByDefault() {
        let (session, e) = session()
        #expect(session.supersets.isEmpty)
        #expect(session.supersetLetter(for: e[0]) == nil)
        #expect(!session.isLinkedToNext(e[0]))
    }

    @Test func linkingTwoExercisesMakesASuperset() {
        let (session, e) = session()
        session.linkWithNext(e[1])
        #expect(session.supersets.map { $0.map(\.exerciseID) } == [["b", "c"]])
        #expect(session.supersetLetter(for: e[1]) == "A")
        #expect(session.supersetLetter(for: e[2]) == "A")
        #expect(session.supersetLetter(for: e[0]) == nil)
        #expect(session.isLinkedToNext(e[1]))
        #expect(!session.isLinkedToNext(e[2]))
    }

    @Test func linkingExtendsAnExistingSuperset() {
        let (session, e) = session()
        session.linkWithNext(e[1])
        session.linkWithNext(e[0])
        session.linkWithNext(e[2])
        #expect(session.supersets.map { $0.map(\.exerciseID) } == [["a", "b", "c", "d"]])
    }

    @Test func twoSeparateSupersetsGetDifferentLetters() {
        let (session, e) = session()
        session.linkWithNext(e[0])
        session.linkWithNext(e[2])
        #expect(session.supersets.count == 2)
        #expect(session.supersetLetter(for: e[3]) == "B")
    }

    @Test func linkingTheLastExerciseDoesNothing() {
        let (session, e) = session()
        session.linkWithNext(e[3])
        #expect(e[3].supersetGroup == nil)
    }

    @Test func unlinkingSplitsAndCleansUpSingles() {
        let (session, e) = session()
        session.linkWithNext(e[0])
        session.linkWithNext(e[1])
        session.linkWithNext(e[2])
        session.unlinkFromNext(e[0])
        #expect(session.supersets.map { $0.map(\.exerciseID) } == [["b", "c", "d"]])
        #expect(e[0].supersetGroup == nil)

        session.unlinkFromNext(e[2])
        #expect(session.supersets.map { $0.map(\.exerciseID) } == [["b", "c"]])
        #expect(e[3].supersetGroup == nil)
    }

    @Test func restOnlyAfterTheLastExerciseOfASuperset() {
        let (session, e) = session()
        session.linkWithNext(e[0])
        e[1].restSeconds = 60
        #expect(session.restSeconds(after: e[0], default: 90) == 0)
        #expect(session.restSeconds(after: e[1], default: 90) == 60)
        #expect(session.restSeconds(after: e[2], default: 90) == 90)
    }

    @Test func removingAnExerciseRenumbersAndBreaksItsSuperset() {
        let (session, e) = session()
        session.linkWithNext(e[0])
        session.removeExercise(e[1])
        #expect(session.orderedExercises.map(\.exerciseID) == ["a", "c", "d"])
        #expect(session.orderedExercises.map(\.position) == [0, 1, 2])
        #expect(session.supersets.isEmpty)
        #expect(e[0].supersetGroup == nil)
    }

    @Test func movingReordersAndRenumbers() {
        let (session, e) = session()
        session.moveExercises([e[3]], before: e[0])
        #expect(session.orderedExercises.map(\.exerciseID) == ["d", "a", "b", "c"])
        #expect(session.orderedExercises.map(\.position) == [0, 1, 2, 3])
        session.moveExercises([e[3]], before: nil)
        #expect(session.orderedExercises.map(\.exerciseID) == ["a", "b", "c", "d"])
    }

    @Test func movingASupersetTogetherKeepsIt() {
        let (session, e) = session()
        session.linkWithNext(e[1])
        session.moveExercises([e[1], e[2]], before: e[0])
        #expect(session.supersets.map { $0.map(\.exerciseID) } == [["b", "c"]])
    }

    @Test func movingOutOfASupersetUnlinksIt() {
        let (session, e) = session()
        session.linkWithNext(e[0])
        session.linkWithNext(e[1])
        // a+b+c, then b moves to the end: a+c stay linked, b is on its own.
        session.moveExercises([e[1]], before: nil)
        #expect(session.supersets.map { $0.map(\.exerciseID) } == [["a", "c"]])
        #expect(e[1].supersetGroup == nil)
    }

    @Test func splittingASupersetMakesSeparateGroups() {
        let (session, e) = session()
        session.linkWithNext(e[0])
        session.linkWithNext(e[1])
        session.linkWithNext(e[2])
        // a+b and c+d; moving c before b leaves every run a single exercise.
        session.unlinkFromNext(e[1])
        session.moveExercises([e[2]], before: e[1])
        #expect(session.orderedExercises.map(\.exerciseID) == ["a", "c", "b", "d"])
        #expect(session.supersets.isEmpty)
        #expect(session.exercises.allSatisfy { $0.supersetGroup == nil })
    }
}
