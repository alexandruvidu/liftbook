import Foundation
import Testing
@testable import Liftbook

struct WorkoutStatsTests {
    private func session(sets: [(kind: SetKind, weight: Double, reps: Int, done: Bool)]) -> WorkoutSession {
        let session = WorkoutSession(name: "W", startedAt: Date(timeIntervalSince1970: 0))
        session.addExercises(["barbell-bench-press"], setCount: 0)
        let exercise = session.exercises[0]
        exercise.sets = []
        for (index, item) in sets.enumerated() {
            let set = WorkoutSet(position: index, kind: item.kind, measurement: SetMeasurement(weight: item.weight, reps: item.reps))
            exercise.sets.append(set)
            if item.done { set.toggleCompleted(for: .weightAndReps) }
        }
        return session
    }

    @Test func countsCompletedOfTotal() {
        let stats = WorkoutStats.of(session(sets: [
            (.normal, 50, 10, true), (.normal, 50, 10, true), (.normal, 50, 10, true),
            (.normal, 50, 10, false), (.normal, 50, 10, false),
        ])) { _ in .weightAndReps }
        #expect(stats.completedSets == 3)
        #expect(stats.totalSets == 5)
    }

    @Test func volumeSkipsWarmUpsAndUnchecked() {
        let stats = WorkoutStats.of(session(sets: [
            (.warmUp, 20, 10, true), (.normal, 50, 10, true), (.normal, 60, 10, false),
        ])) { _ in .weightAndReps }
        #expect(stats.volume == 500)
        #expect(stats.completedSets == 2)
    }

    @Test func timedExercisesAddNoVolume() {
        let stats = WorkoutStats.of(session(sets: [(.normal, 50, 10, true)])) { _ in .duration }
        #expect(stats.volume == 0)
    }
}
