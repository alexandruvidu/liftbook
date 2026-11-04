import XCTest

extension XCUIApplication {
    /// Launches Liftbook with a forced appearance and a fresh in-memory data store.
    @MainActor
    static func launchLiftbook(appearance: String = "light") -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments += ["-uiTestAppearance", appearance, "-uiTestInMemoryStore", "YES"]
        app.launch()
        return app
    }
}
