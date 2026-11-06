import XCTest

extension XCUIApplication {
    /// Launches Liftbook with a forced appearance and a fresh in-memory data store.
    /// - Parameter storeFile: keep data in this temporary store file instead of
    ///   memory, so a relaunch with the same name finds it again.
    /// - Parameter seedHistory: add finished workouts 1, 2 and 9 days ago
    ///   ("Upper Body", "Leg Day", "Upper Body"), each 52 minutes long.
    @MainActor
    static func launchLiftbook(appearance: String = "light", seedSampleData: Bool = false,
                               storeFile: String? = nil, seedHistory: Bool = false,
                               seedPhotos: Bool = false, seedMachines: Bool = false,
                               textSize: String? = nil) -> XCUIApplication {
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
        if seedHistory {
            app.launchArguments += ["-uiTestSeedHistory", "YES"]
        }
        if seedPhotos {
            // Two drawn photos: today and 30 days ago.
            app.launchArguments += ["-uiTestSeedPhotos", "YES"]
        }
        if seedMachines {
            // Bench press machines "Flat bench A", "Flat bench B" and "Smith";
            // a finished workout on A two days ago (50 kg × 10).
            app.launchArguments += ["-uiTestSeedMachines", "YES"]
        }
        if let textSize {
            // e.g. "UICTContentSizeCategoryAccessibilityL"
            app.launchArguments += ["-UIPreferredContentSizeCategoryName", textSize]
        }
        app.launch()
        return app
    }
}
