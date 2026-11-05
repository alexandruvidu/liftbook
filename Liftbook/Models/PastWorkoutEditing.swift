import Foundation

extension WorkoutSession {
    /// Length in whole minutes (0 while in progress).
    var durationMinutes: Int {
        guard let endedAt else { return 0 }
        return max(Int((endedAt.timeIntervalSince(startedAt) / 60).rounded()), 0)
    }

    /// Moves the start of a finished workout, keeping its length.
    func moveStart(to date: Date) {
        let length = endedAt.map { $0.timeIntervalSince(startedAt) }
        startedAt = date
        if let length { endedAt = date.addingTimeInterval(length) }
    }

    /// Sets the length of a finished workout, between 1 minute and 24 hours.
    func setDuration(minutes: Int) {
        guard endedAt != nil else { return }
        endedAt = startedAt.addingTimeInterval(TimeInterval(min(max(minutes, 1), 24 * 60) * 60))
    }
}
