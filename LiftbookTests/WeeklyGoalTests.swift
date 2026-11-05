import Foundation
import Testing
@testable import Liftbook

struct WeeklyGoalTests {
    private let goal: WeeklyGoal = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        calendar.firstWeekday = 2
        return WeeklyGoal(calendar: calendar)
    }()

    /// Thursday 2026-11-05 noon.
    private let now = Date(timeIntervalSince1970: 1_793_880_000)

    private func finished(daysAgo: Int) -> WorkoutSession {
        let session = WorkoutSession(name: "W", startedAt: now.addingTimeInterval(TimeInterval(-daysAgo) * 86_400))
        session.endedAt = session.startedAt.addingTimeInterval(3600)
        return session
    }

    /// Two workouts in each listed week back from this one (0 = this week).
    private func sessions(weeksBack: [Int], perWeek: Int = 2) -> [WorkoutSession] {
        weeksBack.flatMap { week in (0..<perWeek).map { finished(daysAgo: week * 7 + $0) } }
    }

    @Test func nowIsAThursday() {
        #expect(goal.calendar.component(.weekday, from: now) == 5)
    }

    @Test func countsThisWeeksWorkouts() {
        let all = [finished(daysAgo: 0), finished(daysAgo: 3), finished(daysAgo: 4)] // Thu, Mon, last Sun
        #expect(goal.workouts(inWeekOf: now, sessions: all) == 2)
    }

    @Test func unfinishedCurrentWeekDoesNotBreakTheStreak() {
        let all = sessions(weeksBack: [1, 2, 3]) + [finished(daysAgo: 0)]
        #expect(goal.currentStreak(goal: 2, sessions: all, now: now) == 3)
    }

    @Test func metCurrentWeekCounts() {
        let all = sessions(weeksBack: [0, 1])
        #expect(goal.currentStreak(goal: 2, sessions: all, now: now) == 2)
    }

    @Test func aMissedWeekEndsTheStreak() {
        let all = sessions(weeksBack: [1, 3, 4, 5])
        #expect(goal.currentStreak(goal: 2, sessions: all, now: now) == 1)
        #expect(goal.bestStreak(goal: 2, sessions: all) == 3)
    }

    @Test func noWorkoutsNoStreak() {
        #expect(goal.currentStreak(goal: 3, sessions: [], now: now) == 0)
        #expect(goal.bestStreak(goal: 3, sessions: []) == 0)
    }

    @Test func unfinishedWorkoutsDontCount() {
        let running = WorkoutSession(name: "Now", startedAt: now)
        #expect(goal.workouts(inWeekOf: now, sessions: [running]) == 0)
    }
}
