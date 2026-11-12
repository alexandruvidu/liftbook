import Foundation
import SwiftData
import Testing
@testable import Liftbook

@MainActor
struct WorkoutStarterTests {
    private let container: ModelContainer
    private let context: ModelContext
    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }()

    init() {
        container = Persistence.makeContainer(inMemory: true)
        context = ModelContext(container)
    }

    private func date(hour: Int) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: 11, day: 5, hour: hour, minute: 30))!
    }

    @Test(arguments: [
        (3, "Night Workout"), (5, "Morning Workout"), (11, "Morning Workout"),
        (12, "Afternoon Workout"), (16, "Afternoon Workout"), (17, "Evening Workout"),
        (21, "Evening Workout"), (22, "Night Workout"),
    ])
    func defaultNameFollowsTimeOfDay(hour: Int, expected: String) {
        #expect(WorkoutStarter.defaultName(at: date(hour: hour), calendar: calendar) == expected)
    }

    @Test func emptyWorkoutStartsInProgressWithNoExercises() {
        let session = WorkoutStarter.emptyWorkout(at: date(hour: 18), calendar: calendar)
        #expect(session.name == "Evening Workout")
        #expect(session.exercises.isEmpty)
        #expect(session.isInProgress)
        #expect(session.routineID == nil)
    }

    @Test func workoutFromRoutineCopiesExercisesOrderAndSets() throws {
        Persistence.seedSampleData(in: context)
        let routine = try #require(try context.fetch(FetchDescriptor<Routine>()).first)

        let session = WorkoutStarter.workout(from: routine)
        context.insert(session)
        try context.save()

        #expect(session.name == "Upper Body")
        #expect(session.routineID == routine.routineID)
        #expect(session.orderedExercises.map(\.exerciseID) == ["barbell-bench-press", "bent-over-barbell-row", "overhead-press"])
        #expect(session.orderedExercises.map(\.sets.count) == [3, 3, 2])

        let sets = session.orderedExercises.flatMap(\.orderedSets)
        #expect(sets.allSatisfy { !$0.isCompleted && $0.kind == .normal && $0.measurement == SetMeasurement() })
        #expect(session.orderedExercises[0].orderedSets.map(\.position) == [0, 1, 2])
    }

    // MARK: Machines

    private func benchRoutine() throws -> (Routine, Machine, Machine) {
        Persistence.seedSampleData(in: context)
        let routine = try #require(try context.fetch(FetchDescriptor<Routine>()).first)
        let a = Machine(exerciseID: "barbell-bench-press", name: "A")
        let b = Machine(exerciseID: "barbell-bench-press", name: "B")
        context.insert(a)
        context.insert(b)
        return (routine, a, b)
    }

    @Test func routineMachineWins() throws {
        let (routine, a, b) = try benchRoutine()
        routine.orderedEntries[0].machineID = a.machineID
        let history = [MachineTests.session(daysAgo: 1, machine: b.machineID, weight: 50, reps: 8, now: date(hour: 18))]
        let session = WorkoutStarter.workout(from: routine, machines: [a, b], history: history)
        let bench = session.orderedExercises[0]
        #expect(bench.machineID == a.machineID)
        #expect(bench.machineConfirmed)
    }

    @Test func fallsBackToLastUsedUnconfirmed() throws {
        let (routine, a, b) = try benchRoutine()
        let history = [MachineTests.session(daysAgo: 1, machine: b.machineID, weight: 50, reps: 8, now: date(hour: 18))]
        let session = WorkoutStarter.workout(from: routine, machines: [a, b], history: history)
        let bench = session.orderedExercises[0]
        #expect(bench.machineID == b.machineID)
        #expect(!bench.machineConfirmed)
    }

    @Test func deletedRoutineMachineIsIgnored() throws {
        let (routine, a, _) = try benchRoutine()
        routine.orderedEntries[0].machineID = UUID()
        let session = WorkoutStarter.workout(from: routine, machines: [a], history: [])
        #expect(session.orderedExercises[0].machineID == nil)
    }

    @Test func noMachinesLeavesNil() throws {
        Persistence.seedSampleData(in: context)
        let routine = try #require(try context.fetch(FetchDescriptor<Routine>()).first)
        let session = WorkoutStarter.workout(from: routine, machines: [], history: [])
        #expect(session.orderedExercises.allSatisfy { $0.machineID == nil && $0.machineConfirmed })
    }

    @Test func repeatingKeepsTheMachineUnconfirmed() {
        let machine = Machine(exerciseID: "barbell-bench-press", name: "A")
        let past = MachineTests.session(daysAgo: 1, machine: machine.machineID, weight: 50, reps: 8, now: date(hour: 18))
        let bench = WorkoutStarter.repeating(past, machines: [machine]).orderedExercises[0]
        #expect(bench.machineID == machine.machineID)
        #expect(!bench.machineConfirmed)
    }

    @Test func repeatingDropsADeletedMachine() {
        let past = MachineTests.session(daysAgo: 1, machine: UUID(), weight: 50, reps: 8, now: date(hour: 18))
        let bench = WorkoutStarter.repeating(past, machines: []).orderedExercises[0]
        #expect(bench.machineID == nil)
        #expect(bench.machineConfirmed)
    }

    @Test func deletingAMachineKeepsItsSetsAsNoMachine() throws {
        let machine = Machine(exerciseID: "barbell-bench-press", name: "A")
        context.insert(machine)
        let past = MachineTests.session(daysAgo: 1, machine: machine.machineID, weight: 50, reps: 8, now: date(hour: 18))
        context.insert(past)
        Persistence.seedSampleData(in: context)
        let routine = try #require(try context.fetch(FetchDescriptor<Routine>()).first)
        routine.orderedEntries[0].machineID = machine.machineID
        try context.save()

        try Machine.delete(machine, in: context)
        #expect(past.exercises[0].machineID == nil)
        #expect(routine.orderedEntries[0].machineID == nil)
        #expect(try context.fetch(FetchDescriptor<Machine>()).isEmpty)
        let found = PreviousPerformance.find(exerciseID: "barbell-bench-press", machine: .none, in: [past])
        #expect(found?.sets == [SetMeasurement(weight: 50, reps: 8)])
    }

    @Test func swappingDropsTheMachine() {
        let exercise = WorkoutExercise(exerciseID: "barbell-bench-press", position: 0)
        exercise.machineID = UUID()
        exercise.machineConfirmed = false
        exercise.swap(to: "incline-barbell-bench-press")
        #expect(exercise.machineID == nil)
        #expect(exercise.machineConfirmed)
    }

    @Test func addExercisesAppendsAfterExisting() {
        let session = WorkoutStarter.emptyWorkout()
        context.insert(session)
        session.addExercises(["a", "b"])
        session.addExercises(["c"], setCount: 0)
        #expect(session.orderedExercises.map(\.exerciseID) == ["a", "b", "c"])
        #expect(session.orderedExercises.map(\.position) == [0, 1, 2])
        #expect(session.orderedExercises.allSatisfy { $0.sets.count == 1 })
    }

    @Test func discardingDeletesExercisesAndSets() throws {
        let session = WorkoutStarter.emptyWorkout()
        context.insert(session)
        session.addExercises(["a", "b"], setCount: 3)
        try context.save()
        #expect(try context.fetchCount(FetchDescriptor<WorkoutSet>()) == 6)

        context.delete(session)
        try context.save()
        #expect(try context.fetchCount(FetchDescriptor<WorkoutSession>()) == 0)
        #expect(try context.fetchCount(FetchDescriptor<WorkoutExercise>()) == 0)
        #expect(try context.fetchCount(FetchDescriptor<WorkoutSet>()) == 0)
    }

    @Test func setMeasurementAndKindRoundTrip() {
        let set = WorkoutSet(position: 0)
        set.measurement = SetMeasurement(weight: 80, reps: 5)
        set.kind = .drop
        #expect(set.weight == 80 && set.reps == 5)
        #expect(set.kindID == "drop")
        set.kindID = "unknown"
        #expect(set.kind == .normal)
    }
}

@MainActor
struct WorkoutDiscardTests {
    private let container = Persistence.makeContainer(inMemory: true)

    @Test func discardDeletesTheWorkoutsAndCancelsTheRestAlert() throws {
        let context = container.mainContext
        let running = WorkoutSession(name: "Running")
        let other = WorkoutSession(name: "Other")
        context.insert(running)
        context.insert(other)
        running.startRest(seconds: 90, for: "a")
        try context.save()

        var cancelled = 0
        WorkoutStarter.discard([running], in: context) { cancelled += 1 }

        #expect(cancelled == 1)
        let left = try context.fetch(FetchDescriptor<WorkoutSession>())
        #expect(left.map(\.name) == ["Other"])
    }
}
