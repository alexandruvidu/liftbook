import Foundation
import Testing
@testable import Liftbook

struct ResumePromptTests {
    private let now = Date(timeIntervalSince1970: 1_000_000)
    private let locale = Locale(identifier: "en_US")

    @Test func recentWorkoutSaysWhenItStarted() {
        let session = WorkoutSession(name: "Upper Body", startedAt: now.addingTimeInterval(-25 * 60))
        #expect(ResumePrompt.message(for: session, now: now, locale: locale) == "“Upper Body” started 25 minutes ago.")
    }

    @Test func oldWorkoutSuggestsDiscarding() {
        let session = WorkoutSession(name: "Legs", startedAt: now.addingTimeInterval(-7 * 3600))
        let message = ResumePrompt.message(for: session, now: now, locale: locale)
        #expect(message.hasPrefix("“Legs” started 7 hours ago."))
        #expect(message.contains("discard"))
    }
}
