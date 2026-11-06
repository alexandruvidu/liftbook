import Foundation
import Testing
@testable import Liftbook

struct WeekActivityTests {
    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        calendar.firstWeekday = 2
        return calendar
    }()

    /// Thursday 2026-11-05 noon UTC.
    private let now = Date(timeIntervalSince1970: 1_793_880_000)

    private func finished(daysAgo: Int, weight: Double = 50, reps: Int = 10, sets: Int = 1) -> WorkoutSession {
        let start = now.addingTimeInterval(TimeInterval(-daysAgo) * 86_400)
        let session = WorkoutSession(name: "W", startedAt: start)
        session.addExercises(["barbell-bench-press"], setCount: sets)
        for set in session.exercises[0].sets {
            set.measurement = SetMeasurement(weight: weight, reps: reps)
            _ = set.toggleCompleted(for: .weightAndReps, at: start)
        }
        session.finish(at: start.addingTimeInterval(3600))
        return session
    }

    private func week(_ sessions: [WorkoutSession], goal: Int = 3) -> WeekActivity {
        WeekActivity.week(containing: now, sessions: sessions, goal: goal, calendar: calendar) { _ in .weightAndReps }
    }

    @Test func sevenDaysMondayFirst() {
        let days = week([]).days
        #expect(days.count == 7)
        #expect(calendar.component(.weekday, from: days[0].date) == 2)
        #expect(calendar.component(.weekday, from: days[6].date) == 1)
    }

    @Test func volumePerDay() {
        // Two workouts on Tuesday (2 days before Thursday): 500 + 1000 kg.
        let activity = week([finished(daysAgo: 2), finished(daysAgo: 2, weight: 100)])
        #expect(activity.days[1].volume == 1500)
        #expect(activity.days[0].volume == 0)
        #expect(activity.workouts == 2)
    }

    @Test func todayFlagged() {
        let activity = week([])
        #expect(activity.days.filter(\.isToday).count == 1)
        #expect(activity.days[3].isToday)
    }

    @Test func goalAndStreakMatchWeeklyGoal() {
        let sessions = [finished(daysAgo: 0), finished(daysAgo: 1), finished(daysAgo: 7), finished(daysAgo: 8)]
        let activity = week(sessions, goal: 2)
        let goal = WeeklyGoal(calendar: calendar)
        #expect(activity.goal == 2)
        #expect(activity.workouts == goal.workouts(inWeekOf: now, sessions: sessions))
        #expect(activity.streak == goal.currentStreak(goal: 2, sessions: sessions, now: now))
        #expect(activity.streak == 2)
    }

    @Test func otherWeeksIgnored() {
        let activity = week([finished(daysAgo: 7)])
        #expect(activity.workouts == 0)
        #expect(activity.days.allSatisfy { $0.volume == 0 })
    }
}
