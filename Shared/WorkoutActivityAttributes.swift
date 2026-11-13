import ActivityKit
import SwiftUI

/// The workout in progress as a Live Activity: on the Lock Screen and in the
/// Dynamic Island, with buttons to log the next set and skip rest.
/// Shared by the app (which starts and updates it) and the widget extension
/// (which draws it).
struct WorkoutActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var workoutName: String
        var startedAt: Date
        /// The exercise of the next set to log; nil once every set is done.
        var exerciseName: String?
        /// "Set 2 of 4".
        var setLabel: String
        /// What the next set will log, e.g. "60 kg × 8"; empty when it has no values yet.
        var target: String
        /// Whether the next set has every value it needs to be checked off from here.
        var canLog: Bool
        var completedSets: Int
        var totalSets: Int
        var restEndsAt: Date?
        var restStartedAt: Date?
    }

    /// The workout's own UUID, to find its activity again.
    var sessionID: String
}

/// Liftbook's accent outside the app's asset catalog (the widget extension
/// has none): deep teal in light mode, mint in dark mode.
enum LiftbookBrand {
    static let accent = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0x5E / 255, green: 0xE0 / 255, blue: 0xB5 / 255, alpha: 1)
            : UIColor(red: 0x0B / 255, green: 0x7A / 255, blue: 0x6D / 255, alpha: 1)
    })

    /// Text drawn on the accent: white in light mode, deep teal in dark mode.
    static let onAccent = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0x04 / 255, green: 0x2F / 255, blue: 0x29 / 255, alpha: 1)
            : .white
    })

    /// Opens the workout in progress when the Live Activity is tapped.
    static let workoutURL = URL(string: "liftbook://workout")!
}
