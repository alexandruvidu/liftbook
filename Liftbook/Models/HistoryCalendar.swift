import Foundation

/// Grouping and calendar layout for finished workouts.
struct HistoryCalendar {
    var calendar: Calendar = .current

    /// A month of finished workouts, newest first.
    struct MonthGroup: Identifiable {
        /// First instant of the month.
        let month: Date
        let sessions: [WorkoutSession]
        var id: Date { month }
    }

    /// Finished sessions grouped by month, newest month and session first.
    func months(of sessions: [WorkoutSession]) -> [MonthGroup] {
        let finished = sessions.filter { $0.endedAt != nil }.sorted { $0.startedAt > $1.startedAt }
        let grouped = Dictionary(grouping: finished) { startOfMonth($0.startedAt) }
        return grouped.keys.sorted(by: >).map { MonthGroup(month: $0, sessions: grouped[$0] ?? []) }
    }

    func startOfMonth(_ date: Date) -> Date {
        calendar.dateInterval(of: .month, for: date)?.start ?? calendar.startOfDay(for: date)
    }

    func month(_ month: Date, offsetBy months: Int) -> Date {
        calendar.date(byAdding: .month, value: months, to: startOfMonth(month)) ?? month
    }

    /// Cells for a month grid starting on the calendar's first weekday:
    /// nil for the blanks before the 1st, then each day of the month.
    func grid(for month: Date) -> [Date?] {
        let start = startOfMonth(month)
        guard let days = calendar.range(of: .day, in: .month, for: start) else { return [] }
        let weekday = calendar.component(.weekday, from: start)
        let blanks = (weekday - calendar.firstWeekday + 7) % 7
        let dates = days.compactMap { calendar.date(byAdding: .day, value: $0 - 1, to: start) }
        return Array(repeating: nil, count: blanks) + dates
    }

    /// Short weekday titles in grid order, e.g. ["M", "T", …] for Monday-first.
    var weekdaySymbols: [String] {
        let symbols = calendar.veryShortStandaloneWeekdaySymbols
        let first = calendar.firstWeekday - 1
        return Array(symbols[first...] + symbols[..<first])
    }

    /// Finished sessions that started on the same day as `day`.
    func sessions(on day: Date, in sessions: [WorkoutSession]) -> [WorkoutSession] {
        sessions
            .filter { $0.endedAt != nil && calendar.isDate($0.startedAt, inSameDayAs: day) }
            .sorted { $0.startedAt > $1.startedAt }
    }

    /// Start-of-day dates that have at least one finished workout.
    func workoutDays(in sessions: [WorkoutSession]) -> Set<Date> {
        Set(sessions.filter { $0.endedAt != nil }.map { calendar.startOfDay(for: $0.startedAt) })
    }

    /// "2026-11-05", for accessibility identifiers.
    func dayID(_ date: Date) -> String {
        let c = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0)
    }
}
