import Foundation

/// The top-level sections of the app, in tab bar order. `start` isn't a
/// screen: selecting it opens the quick-start sheet.
enum AppTab: String, CaseIterable, Identifiable, Hashable {
    case home
    case exercises
    case activity
    case profile
    case start

    var id: String { rawValue }

    var title: String {
        switch self {
        case .home: "Home"
        case .exercises: "Exercises"
        case .activity: "Activity"
        case .profile: "Profile"
        case .start: "Start"
        }
    }

    var systemImage: String {
        switch self {
        case .home: "house.fill"
        case .exercises: "dumbbell.fill"
        case .activity: "chart.line.uptrend.xyaxis"
        case .profile: "person.crop.circle"
        case .start: "plus"
        }
    }
}
