import Foundation

/// The top-level sections of the app, in tab bar order. Starting a workout
/// is the floating button beside the bar, not a tab.
enum AppTab: String, CaseIterable, Identifiable, Hashable {
    case home
    case exercises
    case activity
    case profile

    var id: String { rawValue }

    var title: String {
        switch self {
        case .home: "Home"
        case .exercises: "Exercises"
        case .activity: "Activity"
        case .profile: "Profile"
        }
    }

    var systemImage: String {
        switch self {
        case .home: "house.fill"
        case .exercises: "dumbbell.fill"
        case .activity: "chart.line.uptrend.xyaxis"
        case .profile: "person.crop.circle"
        }
    }
}
