import Foundation
import SwiftData
import Testing
@testable import Liftbook

@MainActor
struct ExerciseProgressTests {
    private let container = Persistence.makeContainer(inMemory: true)

    private func session(day: Double, finished: Bool = true, exerciseID: String = "bench",
                         _ sets: [(Double, Int, SetKind)]) -> WorkoutSession {
        let start = Date(timeIntervalSince1970: day * 86_400)
        let session = WorkoutSession(name: "W", startedAt: start)
        container.mainContext.insert(session)
        let exercise = WorkoutExercise(exerciseID: exerciseID, position: 0)
        session.exercises.append(exercise)
        for (weight, reps, kind) in sets {
            let set = exercise.addSet()
            set.measurement = SetMeasurement(weight: weight, reps: reps)
            set.kind = kind
            set.toggleCompleted(for: .weightAndReps)
        }
        if finished { session.finish(at: start.addingTimeInterval(3600)) }
        return session
    }

    @Test func onePointPerWorkoutOldestFirst() {
        let sessions = [
            session(day: 3, [(80, 5, .normal), (70, 8, .normal)]),
            session(day: 1, [(40, 10, .warmUp), (75, 5, .normal)]),
        ]
        let maxWeight = ExerciseProgress.points(for: "bench", metric: .maxWeight, in: sessions)
        #expect(maxWeight.map(\.value) == [75, 80])
        #expect(maxWeight.first?.date == Date(timeIntervalSince1970: 86_400))

        let volume = ExerciseProgress.points(for: "bench", metric: .volume, in: sessions)
        #expect(volume.map(\.value) == [375, 960]) // warm-up left out

        let oneRepMax = ExerciseProgress.points(for: "bench", metric: .oneRepMax, in: sessions)
        #expect(abs(oneRepMax[1].value - 93.33) < 0.01) // 80 × 5 → 93.3 beats 70 × 8 → 88.7
    }

    @Test func skipsOtherExercisesAndUnfinishedWorkouts() {
        let sessions = [
            session(day: 1, exerciseID: "squat", [(100, 5, .normal)]),
            session(day: 2, finished: false, [(90, 5, .normal)]),
        ]
        #expect(ExerciseProgress.points(for: "bench", metric: .maxWeight, in: sessions).isEmpty)
    }

    @Test func changeNeedsTwoPoints() {
        let one = [ExerciseProgress.Point(date: .now, value: 50)]
        #expect(ExerciseProgress.change(in: one) == nil)
        let two = one + [ExerciseProgress.Point(date: .now.addingTimeInterval(1), value: 57.5)]
        #expect(ExerciseProgress.change(in: two) == 7.5)
    }
}
