import Foundation
import SwiftData
import Testing
@testable import Liftbook

@MainActor
struct WorkoutSummaryTests {
    private let container = Persistence.makeContainer(inMemory: true)
    private let types: [String: ExerciseType] = ["bench": .weightAndReps, "pullup": .bodyweight, "plank": .duration]
    private func type(_ id: String) -> ExerciseType { types[id] ?? .weightAndReps }

    /// A finished session; each set is (exerciseID, weight, reps, kind, completed).
    private func session(daysAgo: Double, minutes: Double = 60,
                         sets: [(String, Double?, Int?, SetKind, Bool)]) -> WorkoutSession {
        let start = Date(timeIntervalSince1970: 1_000_000 - daysAgo * 86_400)
        let session = WorkoutSession(name: "W", startedAt: start)
        container.mainContext.insert(session)
        for (id, weight, reps, kind, done) in sets {
            let exercise = session.exercises.first(where: { $0.exerciseID == id }) ?? {
                let added = WorkoutExercise(exerciseID: id, position: session.exercises.count)
                session.exercises.append(added)
                return added
            }()
            let set = exercise.addSet()
            set.measurement = SetMeasurement(weight: weight, reps: reps)
            set.kind = kind
            if done { set.toggleCompleted(for: type(id)) }
        }
        session.finish(at: start.addingTimeInterval(minutes * 60))
        return session
    }

    @Test func totalsCountOnlyCompletedWorkingSets() {
        let today = session(daysAgo: 0, minutes: 45, sets: [
            ("bench", 40, 10, .warmUp, true),
            ("bench", 80, 5, .normal, true),
            ("bench", 80, 5, .normal, true),
            ("bench", 80, 5, .normal, false),
            ("pullup", nil, 10, .normal, true),
            ("plank", nil, nil, .normal, false),
        ])
        let summary = WorkoutSummary(session: today, history: [], type: type)
        #expect(summary.duration == 45 * 60)
        #expect(summary.setCount == 3)
        #expect(summary.exerciseCount == 2)
        #expect(summary.volume == 800)
        #expect(summary.records.isEmpty)
    }

    @Test func recordsNeedHistoryAndMustBeatIt() {
        let old = session(daysAgo: 7, sets: [("bench", 80, 5, .normal, true), ("pullup", nil, 8, .normal, true)])
        let today = session(daysAgo: 0, sets: [("bench", 85, 3, .normal, true), ("pullup", nil, 8, .normal, true)])
        let summary = WorkoutSummary(session: today, history: [old, today], type: type)
        // 85 kg beats 80 kg; 85×3 ≈ 93.5 e1RM beats 80×5 ≈ 93.3; 8 reps only ties
        #expect(summary.records.map(\.kind) == [.heaviestWeight, .bestOneRepMax])
        #expect(summary.records.first?.value == 85)
    }

    @Test func warmUpsDontSetRecords() {
        let old = session(daysAgo: 7, sets: [("bench", 80, 5, .normal, true)])
        let today = session(daysAgo: 0, sets: [("bench", 100, 1, .warmUp, true), ("bench", 70, 5, .normal, true)])
        #expect(WorkoutSummary(session: today, history: [old], type: type).records.isEmpty)
    }

    @Test(arguments: [(100.0, 1, 100.0), (100, 10, 133.33), (60, 5, 70.0)])
    func epleyOneRepMax(weight: Double, reps: Int, expected: Double) {
        let value = WorkoutSummary.estimatedOneRepMax(weight: weight, reps: reps) ?? 0
        #expect(abs(value - expected) < 0.01)
    }

    @Test func noOneRepMaxWithoutWeightOrReps() {
        #expect(WorkoutSummary.estimatedOneRepMax(weight: 0, reps: 5) == nil)
        #expect(WorkoutSummary.estimatedOneRepMax(weight: 50, reps: 0) == nil)
    }
}
