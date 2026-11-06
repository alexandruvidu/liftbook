import Foundation
import Testing
@testable import Liftbook

struct MachineTests {
    private let now = Date(timeIntervalSince1970: 1_793_880_000)

    /// A finished bench session `daysAgo` days back, on `machine`, at `weight` × `reps`.
    static func session(daysAgo: Int, machine: UUID?, weight: Double, reps: Int,
                        exerciseID: String = "barbell-bench-press", now: Date, finished: Bool = true) -> WorkoutSession {
        let start = now.addingTimeInterval(TimeInterval(-daysAgo) * 86_400)
        let session = WorkoutSession(name: "W", startedAt: start)
        session.addExercises([exerciseID], setCount: 1)
        let exercise = session.exercises[0]
        exercise.machineID = machine
        exercise.sets[0].measurement = SetMeasurement(weight: weight, reps: reps)
        exercise.sets[0].toggleCompleted(for: .weightAndReps, at: start)
        if finished { session.finish(at: start.addingTimeInterval(3600)) }
        return session
    }

    @Test func filterNoneMatchesOnlyNil() {
        let plain = WorkoutExercise(exerciseID: "x", position: 0)
        let onMachine = WorkoutExercise(exerciseID: "x", position: 0)
        onMachine.machineID = UUID()
        #expect(MachineFilter.none.matches(plain))
        #expect(!MachineFilter.none.matches(onMachine))
    }

    @Test func filterMachineMatchesThatID() {
        let id = UUID()
        let exercise = WorkoutExercise(exerciseID: "x", position: 0)
        exercise.machineID = id
        #expect(MachineFilter.machine(id).matches(exercise))
        #expect(!MachineFilter.machine(UUID()).matches(exercise))
        #expect(MachineFilter(id) == .machine(id))
        #expect(MachineFilter(nil) == .none)
    }

    @Test func filterAllMatchesEverything() {
        let exercise = WorkoutExercise(exerciseID: "x", position: 0)
        #expect(MachineFilter.all.matches(exercise))
        exercise.machineID = UUID()
        #expect(MachineFilter.all.matches(exercise))
    }

    @Test func lastUsedIsNewestFinished() {
        let a = UUID(), b = UUID()
        let sessions = [Self.session(daysAgo: 5, machine: a, weight: 40, reps: 10, now: now),
                        Self.session(daysAgo: 1, machine: b, weight: 55, reps: 8, now: now),
                        Self.session(daysAgo: 0, machine: nil, weight: 30, reps: 8, now: now)]
        #expect(Machine.lastUsed(exerciseID: "barbell-bench-press", in: sessions) == b)
        #expect(Machine.lastUsed(exerciseID: "back-squat", in: sessions) == nil)
    }

    @Test func lastUsedIgnoresInProgress() {
        let a = UUID(), b = UUID()
        let sessions = [Self.session(daysAgo: 3, machine: a, weight: 40, reps: 10, now: now),
                        Self.session(daysAgo: 0, machine: b, weight: 55, reps: 8, now: now, finished: false)]
        #expect(Machine.lastUsed(exerciseID: "barbell-bench-press", in: sessions) == a)
    }

    @Test func deletedMachineNameIsNil() {
        let machine = Machine(exerciseID: "barbell-bench-press", name: " Flat bench A ")
        let machines = [machine]
        #expect(machine.name == "Flat bench A")
        #expect(machines.name(for: machine.machineID) == "Flat bench A")
        #expect(machines.name(for: UUID()) == nil)
        #expect(machines.name(for: nil) == nil)
    }

    @Test func machinesOfAnExerciseOldestFirst() {
        let late = Machine(exerciseID: "x", name: "B", createdAt: now)
        let early = Machine(exerciseID: "x", name: "A", createdAt: now.addingTimeInterval(-60))
        let other = Machine(exerciseID: "y", name: "C")
        #expect([late, other, early].of("x").map(\.name) == ["A", "B"])
    }
}
