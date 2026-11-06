import Foundation
import Testing
@testable import Liftbook

/// Records, charts and the finish summary per machine.
struct MachineRecordsTests {
    private let now = Date(timeIntervalSince1970: 1_793_880_000)
    private let a = UUID(), b = UUID()
    private let bench = "barbell-bench-press"

    private func session(daysAgo: Int, machine: UUID?, weight: Double, reps: Int = 8) -> WorkoutSession {
        MachineTests.session(daysAgo: daysAgo, machine: machine, weight: weight, reps: reps, now: now)
    }

    @Test func recordsPerMachine() {
        let sessions = [session(daysAgo: 3, machine: a, weight: 40), session(daysAgo: 1, machine: b, weight: 55)]
        let heaviest = { (filter: MachineFilter) in
            PersonalRecords.records(for: bench, type: .weightAndReps, machine: filter, in: sessions)
                .first { $0.kind == .heaviestWeight }?.value
        }
        #expect(heaviest(.machine(a)) == 40)
        #expect(heaviest(.machine(b)) == 55)
        #expect(heaviest(.all) == 55)
        #expect(heaviest(.none) == nil)
    }

    @Test func pointsPerMachine() {
        let sessions = [session(daysAgo: 3, machine: a, weight: 40), session(daysAgo: 2, machine: b, weight: 55),
                        session(daysAgo: 1, machine: a, weight: 42.5)]
        let onA = ExerciseProgress.points(for: bench, metric: .maxWeight, machine: .machine(a), in: sessions)
        #expect(onA.map(\.value) == [40, 42.5])
        #expect(ExerciseProgress.points(for: bench, metric: .maxWeight, in: sessions).count == 3)
    }

    @Test func lighterMachineRecordIsItsOwn() {
        // B's best is 55; today on A, 45 beats A's 40 — a record on A.
        let history = [session(daysAgo: 3, machine: a, weight: 40), session(daysAgo: 2, machine: b, weight: 55)]
        let today = MachineTests.session(daysAgo: 0, machine: a, weight: 45, reps: 8, now: now)
        let summary = WorkoutSummary(session: today, history: history) { _ in .weightAndReps }
        let heaviest = summary.records.filter { $0.kind == .heaviestWeight }
        #expect(heaviest.count == 1)
        #expect(heaviest.first?.machineID == a)
        #expect(heaviest.first?.value == 45)
    }

    @Test func nilMachineGroupSeparate() {
        // Sets without a machine aren't compared with machine sets.
        let history = [session(daysAgo: 3, machine: a, weight: 80)]
        let today = MachineTests.session(daysAgo: 0, machine: nil, weight: 50, reps: 8, now: now)
        let summary = WorkoutSummary(session: today, history: history) { _ in .weightAndReps }
        #expect(summary.records.isEmpty, "First time without a machine is a baseline")
    }
}
