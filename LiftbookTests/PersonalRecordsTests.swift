import Foundation
import SwiftData
import Testing
@testable import Liftbook

@MainActor
struct PersonalRecordsTests {
    private let container = Persistence.makeContainer(inMemory: true)

    /// A finished session of "bench" with (weight, reps, kind, completed) sets.
    private func session(day: Double, finished: Bool = true,
                         _ sets: [(Double?, Int?, SetKind, Bool)]) -> WorkoutSession {
        let start = Date(timeIntervalSince1970: day * 86_400)
        let session = WorkoutSession(name: "W", startedAt: start)
        container.mainContext.insert(session)
        let exercise = WorkoutExercise(exerciseID: "bench", position: 0)
        session.exercises.append(exercise)
        for (weight, reps, kind, done) in sets {
            let set = exercise.addSet()
            set.measurement = SetMeasurement(weight: weight, reps: reps)
            set.kind = kind
            if done { set.toggleCompleted(for: .weightAndReps, at: start) }
        }
        if finished { session.finish(at: start.addingTimeInterval(3600)) }
        return session
    }

    private func record(_ kind: RecordKind, in records: [PersonalRecords.Record]) -> PersonalRecords.Record? {
        records.first { $0.kind == kind }
    }

    @Test func eachKindFindsItsBestSet() {
        let sessions = [
            session(day: 1, [(100, 3, .normal, true), (80, 10, .normal, true)]),
            session(day: 2, [(90, 6, .normal, true), (40, 20, .normal, true)]),
        ]
        let records = PersonalRecords.records(for: "bench", type: .weightAndReps, in: sessions)
        #expect(record(.heaviestWeight, in: records)?.value == 100)
        // Epley: 100×3 → 110, 90×6 → 108, 80×10 → 106.7
        #expect(record(.bestOneRepMax, in: records)?.set == SetMeasurement(weight: 100, reps: 3))
        #expect(record(.bestSetVolume, in: records)?.value == 800)
        #expect(record(.mostReps, in: records)?.value == 20)
        #expect(record(.mostReps, in: records)?.date == Date(timeIntervalSince1970: 2 * 86_400))
    }

    @Test func warmUpsSkippedAndUnfinishedSetsDontCount() {
        let sessions = [
            session(day: 1, [(200, 1, .warmUp, true), (60, 5, .normal, true), (150, 5, .normal, false)]),
            session(day: 2, finished: false, [(120, 5, .normal, true)]),
        ]
        let records = PersonalRecords.records(for: "bench", type: .weightAndReps, in: sessions)
        #expect(record(.heaviestWeight, in: records)?.value == 60)
    }

    @Test func tiesKeepTheEarliestSet() {
        let sessions = [session(day: 5, [(100, 5, .normal, true)]), session(day: 1, [(100, 5, .normal, true)])]
        let records = PersonalRecords.records(for: "bench", type: .weightAndReps, in: sessions)
        #expect(record(.heaviestWeight, in: records)?.date == Date(timeIntervalSince1970: 86_400))
    }

    @Test func kindsDependOnExerciseType() {
        #expect(RecordKind.kinds(for: .weightAndReps).count == 4)
        #expect(RecordKind.kinds(for: .bodyweight) == [.mostReps])
        #expect(RecordKind.kinds(for: .duration).isEmpty)
    }

    @Test func noHistoryMeansNoRecords() {
        #expect(PersonalRecords.records(for: "bench", type: .weightAndReps, in: []).isEmpty)
    }

    @Test func formatting() {
        #expect(RecordKind.heaviestWeight.formatted(100, unit: .kilograms) == "100 kg")
        #expect(RecordKind.mostReps.formatted(12, unit: .pounds) == "12 reps")
    }
}
