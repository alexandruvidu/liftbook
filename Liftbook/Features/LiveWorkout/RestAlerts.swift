import AudioToolbox
import UserNotifications

/// Sound and local notification for the end of a rest.
@MainActor
enum RestAlerts {
    private static let notificationID = "liftbook.rest-timer"

    /// Plays a short system sound when rest ends with the app open.
    static func playSound() {
        AudioServicesPlaySystemSound(1005)
    }

    /// Schedules a notification for when rest ends, replacing any earlier one.
    /// Skipped in UI tests so the permission prompt never appears.
    static func schedule(at end: Date, exerciseName: String, sound: Bool) {
        guard !UITestOverrides.isUITesting else { return }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [notificationID])
        Task {
            let center = UNUserNotificationCenter.current()
            guard (try? await center.requestAuthorization(options: [.alert, .sound])) == true else { return }
            let interval = end.timeIntervalSinceNow
            guard interval > 1 else { return }
            let content = UNMutableNotificationContent()
            content.title = "Rest is over"
            content.body = "Time for your next set of \(exerciseName)."
            if sound { content.sound = .default }
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
            try? await center.add(UNNotificationRequest(identifier: notificationID, content: content, trigger: trigger))
        }
    }

    static func cancel() {
        guard !UITestOverrides.isUITesting else { return }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [notificationID])
    }
}
