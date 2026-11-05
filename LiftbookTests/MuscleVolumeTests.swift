import Foundation
import SwiftData
import Testing
@testable import Liftbook

@MainActor
struct MuscleVolumeTests {
    private let container = Persistence.makeContainer(inMemory: true)
    private let model: MuscleVolume = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        calendar.firstWeekday = 2
        return MuscleVolume(calendar: calendar)
    }()

    private func exercise(_ id: String) -> LibraryExercise? {
        ExerciseLibrary.bundled.exercise(id: id)
    }

    private func date(_ day: Int) -> Date {
        model.calendar.date(from: DateComponents(year: 2026, month: 11, day: day, hour: 18))!
    }

    private func session(day: Int, _ items: [(String, [(Double?, Int, SetKind, Bool)])]) -> WorkoutSession {
        let session = WorkoutSession(name: "W", startedAt: date(day))
        container.mainContext.insert(session)
        for (index, (id, sets)) in items.enumerated() {
            let exercise = WorkoutExercise(exerciseID: id, position: index)
            session.exercises.append(exercise)
            for (weight, reps, kind, done) in sets {
                let set = exercise.addSet()
                set.measurement = SetMeasurement(weight: weight, reps: reps)
                set.kind = kind
                if done { set.toggleCompleted(for: .weightAndReps) }
            }
        }
        session.finish(at: date(day).addingTimeInterval(3600))
        return session
    }

    @Test func countsWorkingSetsPerPrimaryMuscleInTheWeek() throws {
        let bench = try #require(exercise("barbell-bench-press"))
        let sessions = [
            // Mon Nov 2 and Wed Nov 4 are in the week; Sun Nov 1 and Mon Nov 9 are not
            session(day: 2, [("barbell-bench-press", [(40, 10, .warmUp, true), (80, 5, .normal, true), (80, 5, .normal, false)])]),
            session(day: 4, [("barbell-bench-press", [(80, 5, .normal, true)])]),
            session(day: 1, [("barbell-bench-press", [(80, 5, .normal, true)])]),
            session(day: 9, [("barbell-bench-press", [(80, 5, .normal, true)])]),
        ]
        let week = model.week(containing: date(5))
        let entries = model.entries(for: week, in: sessions, exercise: exercise)
        #expect(Set(entries.map(\.muscle)) == Set(bench.primaryMuscles))
        let first = try #require(entries.first)
        #expect(first.sets == 2)
        #expect(first.volume == 800)
    }

    @Test func sortedBySetsAndWeekNavigation() {
        let sessions = [session(day: 3, [
            ("back-squat", [(100, 5, .normal, true), (100, 5, .normal, true), (100, 5, .normal, true)]),
            ("barbell-bench-press", [(80, 5, .normal, true)]),
        ])]
        let week = model.week(containing: date(3))
        let entries = model.entries(for: week, in: sessions, exercise: exercise)
        #expect(entries.first?.sets == 3)
        #expect(entries.last?.sets == 1)
        let previous = model.week(week, offsetBy: -1)
        #expect(previous.start == model.calendar.date(from: DateComponents(year: 2026, month: 10, day: 26))!)
        #expect(model.entries(for: previous, in: sessions, exercise: exercise).isEmpty)
    }
}
