import Foundation

/// Where app settings (`@AppStorage`) are kept.
enum AppSettings {
    private static let uiTestSuite = "io.github.alexandruvidu.liftbook.uitests"

    /// UserDefaults is thread-safe, so sharing it globally is fine.
    /// The standard defaults, or for UI tests a suite that starts empty on
    /// every launch so tests don't see each other's settings.
    nonisolated(unsafe) static let store: UserDefaults = {
        guard UITestOverrides.isUITesting, let suite = UserDefaults(suiteName: uiTestSuite) else {
            return .standard
        }
        suite.removePersistentDomain(forName: uiTestSuite)
        return suite
    }()
}
