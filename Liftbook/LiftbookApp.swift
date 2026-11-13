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
        // Logged data may point at duplicates removed from the catalog.
        ExerciseAliases.migrate(in: container.mainContext)
        if UITestOverrides.seedSampleData {
            Persistence.seedSampleData(in: container.mainContext)
        }
        if UITestOverrides.seedHistory {
            Persistence.seedHistory(in: container.mainContext)
        }
        // The Live Activity's buttons can run with the app in the background.
        WorkoutLiveActivity.registerActions(container: container)
        ShortcutRequests.shared.container = container
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .preferredColorScheme(UITestOverrides.colorScheme)
                .defaultAppStorage(AppSettings.store)
                // Seeded after launch: drawing with UIKit in init, before any
                // window exists, made the app lose its accent color.
                .task {
                    ExerciseMedia.removeDownloaded(in: container.mainContext)
                    if UITestOverrides.seedPhotos { Persistence.seedPhotos(in: container.mainContext) }
                    if UITestOverrides.seedMachines { Persistence.seedMachines(in: container.mainContext) }
                    if UITestOverrides.seedMedia { Persistence.seedMedia(in: container.mainContext) }
                    AutoBackup.runIfDue(from: container.mainContext)
                }
        }
        .modelContainer(container)
        // Save before the app can be suspended or quit, so an in-progress
        // workout is there after a relaunch.
        .onChange(of: scenePhase) { _, phase in
            if phase != .active { try? container.mainContext.save() }
            if phase == .background { AutoBackup.runIfDue(from: container.mainContext) }
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

    /// `-uiTestSeedMachines YES` adds three bench press machines and a workout on one.
    static var seedMachines: Bool {
        UserDefaults.standard.bool(forKey: "uiTestSeedMachines")
    }

    /// `-uiTestSeedMedia YES` adds two drawn photos to bench press.
    static var seedMedia: Bool {
        UserDefaults.standard.bool(forKey: "uiTestSeedMedia")
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

    /// `-uiTestLiveActivity YES` shows the Live Activity, which other UI tests skip.
    static var showsLiveActivity: Bool {
        UserDefaults.standard.bool(forKey: "uiTestLiveActivity")
    }

    /// `-uiTestHideExerciseArt YES` shows no bundled exercise pictures, as
    /// when they aren't fetched (for the public store screenshots).
    nonisolated static var hidesExerciseArt: Bool {
        UserDefaults.standard.bool(forKey: "uiTestHideExerciseArt")
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
