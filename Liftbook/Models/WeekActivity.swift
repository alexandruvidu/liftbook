import Foundation

/// One week at a glance: lifted volume per day, workouts against the goal,
/// and the current streak of weeks that met it.
struct WeekActivity: Equatable {
    struct Day: Equatable {
        let date: Date
        /// Kilograms lifted in completed working sets that day.
        let volume: Double
        let isToday: Bool
    }

    /// The seven days of the week, starting on the calendar's first weekday.
    let days: [Day]
    /// Finished workouts this week.
    let workouts: Int
    let goal: Int
    let streak: Int

    static func week(containing now: Date, sessions: [WorkoutSession], goal: Int,
                     calendar: Calendar = .current, type: (String) -> ExerciseType) -> WeekActivity {
        let weeklyGoal = WeeklyGoal(calendar: calendar)
        let start = weeklyGoal.week(containing: now).start
        let finished = sessions.filter { $0.endedAt != nil }
        let days = (0..<7).map { offset -> Day in
            let date = calendar.date(byAdding: .day, value: offset, to: start)!
            let volume = finished
                .filter { calendar.isDate($0.startedAt, inSameDayAs: date) }
                .map { WorkoutSummary(session: $0, history: [], type: type).volume }
                .reduce(0, +)
            return Day(date: date, volume: volume, isToday: calendar.isDate(date, inSameDayAs: now))
        }
        return WeekActivity(days: days,
                            workouts: weeklyGoal.workouts(inWeekOf: now, sessions: finished),
                            goal: goal,
                            streak: weeklyGoal.currentStreak(goal: goal, sessions: finished, now: now))
    }
}
