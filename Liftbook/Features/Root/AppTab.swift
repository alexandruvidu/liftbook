import Foundation

/// The five top-level sections of the app, in tab bar order.
enum AppTab: String, CaseIterable, Identifiable, Hashable {
    case workout
    case history
    case exercises
    case progress
    case profile

    var id: String { rawValue }

    var title: String {
        switch self {
        case .workout: "Workout"
        case .history: "History"
        case .exercises: "Exercises"
        case .progress: "Progress"
        case .profile: "Profile"
        }
    }

    var systemImage: String {
        switch self {
        case .workout: "dumbbell.fill"
        case .history: "clock.arrow.circlepath"
        case .exercises: "list.bullet.rectangle"
        case .progress: "chart.line.uptrend.xyaxis"
        case .profile: "person.crop.circle"
        }
    }
}
