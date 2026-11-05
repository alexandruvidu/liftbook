import Foundation

/// Text for the prompt shown at launch when a workout was left in progress.
enum ResumePrompt {
    static let title = "Pick Up Where You Left Off?"
    /// After this long, the prompt points out the workout may be forgotten.
    static let staleAfter: TimeInterval = 6 * 3600

    static func message(for session: WorkoutSession, now: Date = .now, locale: Locale = .current) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = locale
        formatter.unitsStyle = .full
        let started = formatter.localizedString(for: session.startedAt, relativeTo: now)
        var text = "“\(session.name)” started \(started)."
        if now.timeIntervalSince(session.startedAt) >= staleAfter {
            text += " If you forgot to finish it, you can discard it."
        }
        return text
    }
}
