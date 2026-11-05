import Foundation
import Testing
@testable import Liftbook

struct HistoryCalendarTests {
    private let history: HistoryCalendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        calendar.firstWeekday = 2 // Monday
        calendar.locale = Locale(identifier: "en_US")
        return HistoryCalendar(calendar: calendar)
    }()

    private func date(_ y: Int, _ m: Int, _ d: Int, hour: Int = 18) -> Date {
        history.calendar.date(from: DateComponents(year: y, month: m, day: d, hour: hour))!
    }

    private func finished(_ y: Int, _ m: Int, _ d: Int, hour: Int = 18, name: String = "W") -> WorkoutSession {
        let session = WorkoutSession(name: name, startedAt: date(y, m, d, hour: hour))
        session.endedAt = session.startedAt.addingTimeInterval(3600)
        return session
    }

    @Test func groupsByMonthNewestFirst() {
        let sessions = [finished(2026, 10, 30), finished(2026, 11, 3), finished(2026, 11, 5), finished(2026, 9, 1)]
        let months = history.months(of: sessions)
        #expect(months.map(\.month) == [date(2026, 11, 1, hour: 0), date(2026, 10, 1, hour: 0), date(2026, 9, 1, hour: 0)])
        #expect(months[0].sessions.map(\.startedAt) == [date(2026, 11, 5), date(2026, 11, 3)])
    }

    @Test func unfinishedWorkoutsAreLeftOut() {
        let running = WorkoutSession(name: "Now", startedAt: date(2026, 11, 5))
        #expect(history.months(of: [running]).isEmpty)
        #expect(history.workoutDays(in: [running]).isEmpty)
    }

    @Test func gridStartsOnTheFirstWeekday() {
        // November 2026 starts on a Sunday: six blanks in a Monday-first grid
        let grid = history.grid(for: date(2026, 11, 17))
        #expect(grid.prefix(6).allSatisfy { $0 == nil })
        #expect(grid[6] == date(2026, 11, 1, hour: 0))
        #expect(grid.compactMap { $0 }.count == 30)
        #expect(history.weekdaySymbols.first == "M")
    }

    @Test func monthOffsetCrossesYears() {
        #expect(history.month(date(2026, 1, 15), offsetBy: -1) == date(2025, 12, 1, hour: 0))
        #expect(history.month(date(2026, 12, 15), offsetBy: 1) == date(2027, 1, 1, hour: 0))
    }

    @Test func sessionsOnADay() {
        let a = finished(2026, 11, 5, hour: 7, name: "Morning")
        let b = finished(2026, 11, 5, hour: 19, name: "Evening")
        let c = finished(2026, 11, 6)
        #expect(history.sessions(on: date(2026, 11, 5, hour: 12), in: [a, b, c]).map(\.name) == ["Evening", "Morning"])
        #expect(history.workoutDays(in: [a, b, c]).count == 2)
        #expect(history.dayID(date(2026, 11, 5)) == "2026-11-05")
    }
}
