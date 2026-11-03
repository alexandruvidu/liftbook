import SwiftUI

@main
struct LiftbookApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
                .preferredColorScheme(UITestOverrides.colorScheme)
        }
    }
}

/// Launch-argument hooks used only by UI tests, e.g. `-uiTestAppearance dark`.
/// Launch arguments of the form `-key value` are readable through UserDefaults.
enum UITestOverrides {
    static var colorScheme: ColorScheme? {
        appearance(from: UserDefaults.standard.string(forKey: "uiTestAppearance"))
    }

    static func appearance(from value: String?) -> ColorScheme? {
        switch value {
        case "dark": .dark
        case "light": .light
        default: nil
        }
    }
}
