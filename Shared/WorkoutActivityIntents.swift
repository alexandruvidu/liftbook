import AppIntents

/// What the Live Activity's buttons ask the app to do. The intents run in the
/// app's process (that's what `LiveActivityIntent` means), where the app has
/// registered `handler`; in the widget extension it stays nil.
@MainActor
enum WorkoutActivityActions {
    enum Action: Sendable {
        case logNextSet
        case skipRest
    }

    static var handler: ((Action) -> Void)?

    static func perform(_ action: Action) {
        handler?(action)
    }
}

/// Checks off the next set of the workout in progress, with last time's
/// values for anything not typed in, and starts the rest timer.
struct LogNextSetIntent: LiveActivityIntent {
    static let title: LocalizedStringResource = "Log Next Set"
    static let description = IntentDescription("Checks off the next set of the workout in progress.")

    func perform() async throws -> some IntentResult {
        await WorkoutActivityActions.perform(.logNextSet)
        return .result()
    }
}

/// Ends the rest timer of the workout in progress.
struct SkipRestIntent: LiveActivityIntent {
    static let title: LocalizedStringResource = "Skip Rest"
    static let description = IntentDescription("Ends the rest timer of the workout in progress.")

    func perform() async throws -> some IntentResult {
        await WorkoutActivityActions.perform(.skipRest)
        return .result()
    }
}
