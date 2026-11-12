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

    /// Tidies a workout after editing, however the editor was closed: a
    /// blank name becomes the time-of-day name (as `displayName` shows it),
    /// and notes lose surrounding whitespace.
    func tidyAfterEditing(calendar: Calendar = .current) {
        let trimmed = name.trimmedNote
        name = trimmed.isEmpty ? WorkoutStarter.defaultName(at: startedAt, calendar: calendar) : trimmed
        notes = notes.trimmedNote
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
