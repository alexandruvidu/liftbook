import XCTest

extension XCUIApplication {
    /// Launches Liftbook with a forced appearance and a fresh in-memory data store.
    /// - Parameter storeFile: keep data in this temporary store file instead of
    ///   memory, so a relaunch with the same name finds it again.
    @MainActor
    static func launchLiftbook(appearance: String = "light", seedSampleData: Bool = false,
                               storeFile: String? = nil) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments += ["-uiTestAppearance", appearance]
        if let storeFile {
            app.launchArguments += ["-uiTestStoreFile", storeFile]
        } else {
            app.launchArguments += ["-uiTestInMemoryStore", "YES"]
        }
        if seedSampleData {
            // Adds an "Upper Body" routine: bench press 3 sets, barbell row 3, overhead press 2.
            app.launchArguments += ["-uiTestSeedSampleData", "YES"]
        }
        app.launch()
        return app
    }
}
