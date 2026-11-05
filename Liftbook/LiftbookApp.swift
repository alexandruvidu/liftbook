import SwiftData
import SwiftUI

@main
struct LiftbookApp: App {
    private let container: ModelContainer
    @Environment(\.scenePhase) private var scenePhase

    init() {
        if let file = UITestOverrides.storeFile {
            let url = URL.temporaryDirectory.appending(path: "\(file).store")
            container = Persistence.makeContainer(url: url)
        } else {
            container = Persistence.makeContainer(inMemory: UITestOverrides.useInMemoryStore)
        }
        if UITestOverrides.seedSampleData {
            Persistence.seedSampleData(in: container.mainContext)
        }
        if UITestOverrides.seedHistory {
            Persistence.seedHistory(in: container.mainContext)
        }
        if UITestOverrides.seedPhotos {
            Persistence.seedPhotos(in: container.mainContext)
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .preferredColorScheme(UITestOverrides.colorScheme)
                .defaultAppStorage(AppSettings.store)
        }
        .modelContainer(container)
        // Save before the app can be suspended or quit, so an in-progress
        // workout is there after a relaunch.
        .onChange(of: scenePhase) { _, phase in
            if phase != .active { try? container.mainContext.save() }
        }
    }
}

/// Launch-argument hooks used only by UI tests, e.g. `-uiTestAppearance dark`.
/// Launch arguments of the form `-key value` are readable through UserDefaults.
enum UITestOverrides {
    static var colorScheme: ColorScheme? {
        appearance(from: UserDefaults.standard.string(forKey: "uiTestAppearance"))
    }

    /// `-uiTestInMemoryStore YES` keeps each UI test run's data isolated.
    static var useInMemoryStore: Bool {
        UserDefaults.standard.bool(forKey: "uiTestInMemoryStore")
    }

    /// `-uiTestSeedSampleData YES` adds a sample routine on launch.
    static var seedSampleData: Bool {
        UserDefaults.standard.bool(forKey: "uiTestSeedSampleData")
    }

    /// `-uiTestSeedPhotos YES` adds two drawn progress photos.
    static var seedPhotos: Bool {
        UserDefaults.standard.bool(forKey: "uiTestSeedPhotos")
    }

    /// `-uiTestSeedHistory YES` adds a few finished workouts from the past days.
    static var seedHistory: Bool {
        UserDefaults.standard.bool(forKey: "uiTestSeedHistory")
    }

    /// `-uiTestStoreFile <name>` keeps data in a temporary file so a UI test
    /// can relaunch the app and find it again.
    static var storeFile: String? {
        UserDefaults.standard.string(forKey: "uiTestStoreFile").flatMap { $0.isEmpty ? nil : $0 }
    }

    /// UI tests launch with a test store; treat that as "under test".
    static var isUITesting: Bool { useInMemoryStore || storeFile != nil }

    static func appearance(from value: String?) -> ColorScheme? {
        switch value {
        case "dark": .dark
        case "light": .light
        default: nil
        }
    }
}
