import Foundation

/// Where app settings (`@AppStorage`) are kept.
enum AppSettings {
    private static let uiTestSuite = "io.github.alexandruvidu.liftbook.uitests"

    /// The standard defaults, or for UI tests a suite that starts empty on
    /// every launch so tests don't see each other's settings.
    static let store: UserDefaults = {
        guard UITestOverrides.isUITesting, let suite = UserDefaults(suiteName: uiTestSuite) else {
            return .standard
        }
        suite.removePersistentDomain(forName: uiTestSuite)
        return suite
    }()
}
