import Foundation
import SwiftData
import Testing
@testable import Liftbook

@MainActor
struct WorkoutNotesTests {
    private let container = Persistence.makeContainer(inMemory: true)

    @Test func trimmedNoteRemovesSurroundingWhitespace() {
        #expect("  Felt strong \n\n".trimmedNote == "Felt strong")
        #expect(" \n ".trimmedNote.isEmpty)
        #expect("Line one\nLine two".trimmedNote == "Line one\nLine two")
    }

    @Test func finishEndsTheWorkoutAndTidiesNotes() {
        let session = WorkoutSession(name: "W")
        container.mainContext.insert(session)
        session.addExercises(["a"])
        session.notes = "  Good session \n"
        session.exercises[0].notes = "\nUse the wide grip  "
        session.startRest(seconds: 90, for: "a")
        let end = Date(timeIntervalSince1970: 5_000)

        session.finish(at: end)
        #expect(session.endedAt == end)
        #expect(!session.isInProgress)
        #expect(session.notes == "Good session")
        #expect(session.exercises[0].notes == "Use the wide grip")
        #expect(session.restEndsAt == nil)
    }

    @Test func lastExerciseNoteComesFromTheNewestFinishedWorkout() {
        func finished(daysAgo: Double, note: String) -> WorkoutSession {
            let session = WorkoutSession(name: "W", startedAt: Date(timeIntervalSince1970: 1_000_000 - daysAgo * 86_400))
            container.mainContext.insert(session)
            session.addExercises(["a"])
            session.exercises[0].notes = note
            session.finish(at: session.startedAt.addingTimeInterval(3600))
            return session
        }
        let old = finished(daysAgo: 9, note: "Old cue")
        let blank = finished(daysAgo: 1, note: "  ")
        let current = WorkoutSession(name: "Now")
        #expect(PreviousPerformance.note(exerciseID: "a", in: [old, blank, current], excluding: current) == "Old cue")
        #expect(PreviousPerformance.note(exerciseID: "b", in: [old, blank]) == nil)
    }
}

@MainActor
struct EditedWorkoutNameTests {
    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }()

    private func session(named name: String, hour: Int) -> WorkoutSession {
        let start = calendar.date(from: DateComponents(year: 2026, month: 11, day: 5, hour: hour))!
        return WorkoutSession(name: name, startedAt: start)
    }

    @Test func blankNameFallsBackToTheTimeOfDayName() {
        let workout = session(named: "  \n", hour: 18)
        workout.tidyAfterEditing(calendar: calendar)
        #expect(workout.name == "Evening Workout")
    }

    @Test func nameAndNotesAreTrimmed() {
        let workout = session(named: "  Push Day ", hour: 9)
        workout.notes = "\n Felt strong  "
        workout.tidyAfterEditing(calendar: calendar)
        #expect(workout.name == "Push Day")
        #expect(workout.notes == "Felt strong")
    }
}
