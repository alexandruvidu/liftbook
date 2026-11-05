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
