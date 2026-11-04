import SwiftData
import SwiftUI

@main
struct LiftbookApp: App {
    private let container: ModelContainer

    init() {
        container = Persistence.makeContainer(inMemory: UITestOverrides.useInMemoryStore)
        if UITestOverrides.seedSampleData {
            Persistence.seedSampleData(in: container.mainContext)
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .preferredColorScheme(UITestOverrides.colorScheme)
        }
        .modelContainer(container)
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

    static func appearance(from value: String?) -> ColorScheme? {
        switch value {
        case "dark": .dark
        case "light": .light
        default: nil
        }
    }
}
