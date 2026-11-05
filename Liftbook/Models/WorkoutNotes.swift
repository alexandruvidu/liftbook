import Foundation

extension String {
    /// Text with surrounding whitespace and blank lines removed.
    var trimmedNote: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

extension WorkoutSession {
    /// Ends the workout: stops the rest timer and tidies up notes.
    func finish(at date: Date = .now) {
        stopRest()
        notes = notes.trimmedNote
        for exercise in exercises { exercise.notes = exercise.notes.trimmedNote }
        endedAt = date
    }
}

extension PreviousPerformance {
    /// The exercise note from that workout, if one was written.
    static func note(exerciseID: String, in sessions: [WorkoutSession], excluding current: WorkoutSession? = nil) -> String? {
        sessions
            .filter { $0.endedAt != nil && $0.sessionID != current?.sessionID }
            .sorted { $0.startedAt > $1.startedAt }
            .lazy
            .compactMap { session in
                session.orderedExercises.first { $0.exerciseID == exerciseID && !$0.notes.trimmedNote.isEmpty }?.notes
            }
            .first
    }
}
