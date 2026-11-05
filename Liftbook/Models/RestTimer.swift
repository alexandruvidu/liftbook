import Foundation

/// Rest timer settings and the logic for the timer stored on a session.
enum RestTimer {
    /// UserDefaults key for the default rest in seconds.
    static let defaultSecondsKey = "restTimer.defaultSeconds"
    /// UserDefaults key for playing a sound when rest ends.
    static let soundKey = "restTimer.sound"
    static let fallbackSeconds = 90
    /// Rest lengths offered in pickers, in seconds (0 = off).
    static let options = [0, 30, 45, 60, 75, 90, 120, 150, 180, 240, 300]
    /// How much the -/+ buttons change a running timer.
    static let step: TimeInterval = 15

    /// "Off", "45s", "1:30", "2 min".
    static func label(seconds: Int) -> String {
        switch seconds {
        case 0: "Off"
        case ..<60: "\(seconds)s"
        case let s where s % 60 == 0: "\(s / 60) min"
        default: SetMeasurement.clock(TimeInterval(seconds))
        }
    }
}

extension WorkoutExercise {
    /// Rest after a set of this exercise, using `defaultSeconds` when unset.
    func effectiveRestSeconds(default defaultSeconds: Int) -> Int {
        restSeconds ?? defaultSeconds
    }
}

extension WorkoutSession {
    /// Seconds left on the rest timer, or nil when none is running.
    func restRemaining(at date: Date = .now) -> TimeInterval? {
        guard let restEndsAt else { return nil }
        let remaining = restEndsAt.timeIntervalSince(date)
        return remaining > 0 ? remaining : nil
    }

    /// Fraction of the rest that has passed, 0...1.
    func restProgress(at date: Date = .now) -> Double {
        guard let remaining = restRemaining(at: date), restDuration > 0 else { return 1 }
        return min(max(1 - remaining / restDuration, 0), 1)
    }

    /// Starts (or restarts) the rest timer. Zero or negative seconds stop it.
    func startRest(seconds: Int, for exerciseID: String, at date: Date = .now) {
        guard seconds > 0 else { return stopRest() }
        restDuration = TimeInterval(seconds)
        restEndsAt = date.addingTimeInterval(restDuration)
        restExerciseID = exerciseID
    }

    /// Adds (or with a negative value removes) time; stops when none is left.
    func adjustRest(by seconds: TimeInterval, at date: Date = .now) {
        guard let restEndsAt else { return }
        let newEnd = restEndsAt.addingTimeInterval(seconds)
        if newEnd <= date { return stopRest() }
        self.restEndsAt = newEnd
        restDuration = max(restDuration + seconds, newEnd.timeIntervalSince(date))
    }

    func stopRest() {
        restEndsAt = nil
        restDuration = 0
        restExerciseID = nil
    }
}
