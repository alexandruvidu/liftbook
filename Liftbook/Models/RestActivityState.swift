import Foundation

extension RestActivityAttributes.ContentState {
    /// The Live Activity state for a session's running rest, or nil when no
    /// rest is running.
    init?(session: WorkoutSession, exerciseName: String?) {
        guard let end = session.restEndsAt else { return nil }
        self.init(startedAt: end.addingTimeInterval(-max(session.restDuration, 1)),
                  endsAt: end,
                  exerciseName: exerciseName ?? "your workout")
    }
}
