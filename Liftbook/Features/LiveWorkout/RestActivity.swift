import ActivityKit
import Foundation

/// Mirrors the rest timer as a Live Activity. Quietly does nothing where Live
/// Activities aren't available, such as inside LiveContainer.
@MainActor
enum RestActivity {
    /// Shows, updates or (with a nil state) ends the rest Live Activity.
    static func sync(workoutName: String, state: RestActivityAttributes.ContentState?) {
        guard let state else { return end() }
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        // Stale once the rest is over, so the widget can say so even if the
        // app is suspended and can't end it right away.
        let content = ActivityContent(state: state, staleDate: state.endsAt)
        if let current = Activity<RestActivityAttributes>.activities.first {
            Task { await current.update(content) }
        } else {
            _ = try? Activity<RestActivityAttributes>.request(
                attributes: RestActivityAttributes(workoutName: workoutName),
                content: content)
        }
    }

    /// Removes the rest Live Activity, if any.
    static func end() {
        for activity in Activity<RestActivityAttributes>.activities {
            Task { await activity.end(nil, dismissalPolicy: .immediate) }
        }
    }
}
