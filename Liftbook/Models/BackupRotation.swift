import Foundation

extension AutoBackup {
    /// Every backup from this many recent days is kept…
    static let dailyDays = 7
    /// …then the newest of each week for this many weeks before that.
    static let weeklyWeeks = 8

    /// Backup files to delete: older than `dailyDays`, and either older than
    /// `weeklyWeeks` more weeks or not the newest of their week. Names that
    /// aren't dated backups (safety copies, other files) are never listed.
    static func outdated(_ names: [String], now: Date, calendar: Calendar = .current) -> [String] {
        let today = calendar.startOfDay(for: now)
        var older: [(name: String, day: Date)] = []
        var outdated: [String] = []
        for name in names {
            guard let day = day(of: name, calendar: calendar) else { continue }
            let age = calendar.dateComponents([.day], from: day, to: today).day ?? 0
            if age < dailyDays { continue }
            if age < dailyDays + 7 * weeklyWeeks { older.append((name, day)) } else { outdated.append(name) }
        }
        // Newest first, so the first of each week is the one kept.
        var weeks: Set<DateComponents> = []
        for backup in older.sorted(by: { $0.day > $1.day }) {
            let week = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: backup.day)
            if !weeks.insert(week).inserted { outdated.append(backup.name) }
        }
        return outdated.sorted()
    }

    /// The day in "liftbook-backup-2026-11-13.json", in the calendar's time zone.
    static func day(of name: String, calendar: Calendar = .current) -> Date? {
        let prefix = "liftbook-backup-", suffix = ".json"
        guard name.hasPrefix(prefix), name.hasSuffix(suffix) else { return nil }
        let parts = name.dropFirst(prefix.count).dropLast(suffix.count).split(separator: "-").compactMap { Int($0) }
        guard parts.count == 3 else { return nil }
        return calendar.date(from: DateComponents(year: parts[0], month: parts[1], day: parts[2]))
    }
}
