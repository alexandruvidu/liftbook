import XCTest

extension XCUIApplication {
    /// Launches Liftbook with a forced appearance and a fresh in-memory data store.
    @MainActor
    static func launchLiftbook(appearance: String = "light", seedSampleData: Bool = false) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments += ["-uiTestAppearance", appearance, "-uiTestInMemoryStore", "YES"]
        if seedSampleData {
            // Adds an "Upper Body" routine: bench press 3 sets, barbell row 3, overhead press 2.
            app.launchArguments += ["-uiTestSeedSampleData", "YES"]
        }
        app.launch()
        return app
    }
}
