import ActivityKit
import Foundation

/// The rest timer shown as a Live Activity on the Lock Screen and in the
/// Dynamic Island. Compiled into both the app and the widget extension.
struct RestActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable, Sendable {
        /// When this rest began (start of the progress bar).
        var startedAt: Date
        /// When the rest is over.
        var endsAt: Date
        /// The exercise being rested after.
        var exerciseName: String
    }

    /// Name of the workout in progress, e.g. "Upper Body".
    var workoutName: String
}
