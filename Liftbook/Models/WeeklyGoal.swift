import Foundation

/// Workouts per week against a goal, and streaks of weeks that met it.
struct WeeklyGoal {
    /// Settings key for the goal (workouts per week).
    static let storageKey = "goal.workoutsPerWeek"
    static let defaultGoal = 3
    static let range = 1...7

    var calendar: Calendar = .current

    func week(containing date: Date) -> DateInterval {
        calendar.dateInterval(of: .weekOfYear, for: date) ?? DateInterval(start: date, duration: 7 * 86_400)
    }

    /// Finished workouts that started in the week containing `date`.
    func workouts(inWeekOf date: Date, sessions: [WorkoutSession]) -> Int {
        let week = week(containing: date)
        return sessions.filter { $0.endedAt != nil && $0.startedAt >= week.start && $0.startedAt < week.end }.count
    }

    /// Consecutive weeks meeting the goal, up to now. The current week only
    /// counts once it's met; until then it doesn't break the streak.
    func currentStreak(goal: Int, sessions: [WorkoutSession], now: Date = .now) -> Int {
        let counts = weeklyCounts(sessions)
        var weekStart = week(containing: now).start
        var streak = 0
        if (counts[weekStart] ?? 0) >= goal { streak += 1 }
        while true {
            guard let previous = calendar.date(byAdding: .weekOfYear, value: -1, to: weekStart) else { break }
            weekStart = previous
            guard (counts[weekStart] ?? 0) >= goal else { break }
            streak += 1
        }
        return streak
    }

    /// "2 of 3 workouts this week · 4-week streak", for Siri and Shortcuts.
    func summary(goal: Int, sessions: [WorkoutSession], now: Date = .now) -> String {
        let done = workouts(inWeekOf: now, sessions: sessions)
        let streak = currentStreak(goal: goal, sessions: sessions, now: now)
        let week = "\(done) of \(goal) workout\(goal == 1 ? "" : "s") this week"
        return streak > 0 ? "\(week) · \(streak)-week streak" : week
    }

    /// Finished workouts per week, keyed by week start.
    private func weeklyCounts(_ sessions: [WorkoutSession]) -> [Date: Int] {
        var counts: [Date: Int] = [:]
        for session in sessions where session.endedAt != nil {
            counts[week(containing: session.startedAt).start, default: 0] += 1
        }
        return counts
    }
}
