import Foundation
import SwiftData
import Testing
@testable import Liftbook

@MainActor
struct PreviousPerformanceTests {
    private let container = Persistence.makeContainer(inMemory: true)

    /// A session with one bench press exercise and the given sets.
    private func session(daysAgo: Double, finished: Bool = true,
                         sets: [(SetMeasurement, Bool)], exerciseID: String = "barbell-bench-press") -> WorkoutSession {
        let start = Date(timeIntervalSince1970: 1_000_000 - daysAgo * 86_400)
        let session = WorkoutSession(name: "W", startedAt: start)
        container.mainContext.insert(session)
        session.addExercises([exerciseID], setCount: sets.count)
        for (set, (measurement, done)) in zip(session.exercises[0].orderedSets, sets) {
            set.measurement = measurement
            if done { set.toggleCompleted(for: .weightAndReps) }
        }
        if finished { session.endedAt = start.addingTimeInterval(3600) }
        return session
    }

    private let heavy = SetMeasurement(weight: 80, reps: 5)
    private let light = SetMeasurement(weight: 60, reps: 8)

    @Test func usesTheMostRecentFinishedSession() {
        let old = session(daysAgo: 7, sets: [(light, true)])
        let recent = session(daysAgo: 2, sets: [(heavy, true), (heavy, true)])
        let result = PreviousPerformance.find(exerciseID: "barbell-bench-press", in: [old, recent])
        #expect(result?.sets == [heavy, heavy])
        #expect(result?.date == recent.startedAt)
    }

    @Test func skipsUnfinishedAndCurrentSessions() {
        let finished = session(daysAgo: 5, sets: [(light, true)])
        let inProgress = session(daysAgo: 0, finished: false, sets: [(heavy, true)])
        let result = PreviousPerformance.find(exerciseID: "barbell-bench-press",
                                              in: [finished, inProgress], excluding: inProgress)
        #expect(result?.sets == [light])
    }

    @Test func ignoresUncompletedSets() {
        let partial = session(daysAgo: 1, sets: [(heavy, true), (light, false)])
        #expect(PreviousPerformance.find(exerciseID: "barbell-bench-press", in: [partial])?.sets == [heavy])
    }

    @Test func fallsBackWhenTheNewestHasNoCompletedSets() {
        let older = session(daysAgo: 4, sets: [(light, true)])
        let skipped = session(daysAgo: 1, sets: [(heavy, false)])
        #expect(PreviousPerformance.find(exerciseID: "barbell-bench-press", in: [skipped, older])?.sets == [light])
    }

    @Test func otherExercisesDontCount() {
        let rows = session(daysAgo: 1, sets: [(heavy, true)], exerciseID: "bent-over-barbell-row")
        #expect(PreviousPerformance.find(exerciseID: "barbell-bench-press", in: [rows]) == nil)
    }

    @Test func setAtIndexIsNilPastTheEnd() {
        let performance = PreviousPerformance(sets: [light], date: .now)
        #expect(performance.set(at: 0) == light)
        #expect(performance.set(at: 1) == nil)
    }
}

struct PreviousPerformanceMachineTests {
    private let now = Date(timeIntervalSince1970: 1_793_880_000)
    private let a = UUID(), b = UUID()

    private var sessions: [WorkoutSession] {
        [MachineTests.session(daysAgo: 3, machine: a, weight: 40, reps: 10, now: now),
         MachineTests.session(daysAgo: 1, machine: b, weight: 55, reps: 8, now: now),
         MachineTests.session(daysAgo: 5, machine: nil, weight: 30, reps: 12, now: now)]
    }

    @Test func perMachineIgnoresOtherMachines() {
        let found = PreviousPerformance.find(exerciseID: "barbell-bench-press", machine: .machine(a), in: sessions)
        #expect(found?.sets == [SetMeasurement(weight: 40, reps: 10)])
    }

    @Test func noMachineUsesOnlyNilHistory() {
        let found = PreviousPerformance.find(exerciseID: "barbell-bench-press", machine: .none, in: sessions)
        #expect(found?.sets == [SetMeasurement(weight: 30, reps: 12)])
    }

    @Test func allUsesTheNewest() {
        let found = PreviousPerformance.find(exerciseID: "barbell-bench-press", in: sessions)
        #expect(found?.sets == [SetMeasurement(weight: 55, reps: 8)])
    }

    @Test func newMachineHasNoHistory() {
        #expect(PreviousPerformance.find(exerciseID: "barbell-bench-press", machine: .machine(UUID()), in: sessions) == nil)
    }
}
