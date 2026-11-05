import SwiftUI

/// A month grid with a dot on each workout day; tap a day to list its workouts.
struct HistoryCalendarView: View {
    let sessions: [WorkoutSession]
    let catalog: ExerciseCatalog

    private let history = HistoryCalendar()
    @State private var month = HistoryCalendar().startOfMonth(.now)
    @State private var selectedDay: Date?

    var body: some View {
        let workoutDays = history.workoutDays(in: sessions)
        List {
            Section {
                VStack(spacing: 12) {
                    header
                    grid(workoutDays: workoutDays)
                }
                .padding(.vertical, 4)
            }

            if let selectedDay {
                let onDay = history.sessions(on: selectedDay, in: sessions)
                Section(selectedDay.formatted(.dateTime.weekday(.wide).day().month(.wide))) {
                    if onDay.isEmpty {
                        Text("No workout on this day.")
                            .foregroundStyle(.secondary)
                    }
                    ForEach(onDay) { HistoryLink(session: $0, catalog: catalog) }
                }
            }
        }
        .listStyle(.insetGrouped)
        .onAppear {
            // Start on the most recent workout's day.
            if selectedDay == nil, let latest = sessions.first {
                selectedDay = history.calendar.startOfDay(for: latest.startedAt)
                month = history.startOfMonth(latest.startedAt)
            }
        }
    }

    private var header: some View {
        HStack {
            Button("Previous Month", systemImage: "chevron.left") { month = history.month(month, offsetBy: -1) }
                .labelStyle(.iconOnly)
                .accessibilityIdentifier("calendar.previous")
            Spacer()
            Text(month.formatted(.dateTime.month(.wide).year()))
                .font(.headline)
                .accessibilityIdentifier("calendar.month")
            Spacer()
            Button("Next Month", systemImage: "chevron.right") { month = history.month(month, offsetBy: 1) }
                .labelStyle(.iconOnly)
                .accessibilityIdentifier("calendar.next")
        }
        .buttonStyle(.borderless)
    }

    private func grid(workoutDays: Set<Date>) -> some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)
        return LazyVGrid(columns: columns, spacing: 6) {
            ForEach(Array(history.weekdaySymbols.enumerated()), id: \.offset) { _, symbol in
                Text(symbol)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
            }
            ForEach(Array(history.grid(for: month).enumerated()), id: \.offset) { _, day in
                if let day {
                    dayCell(day, hasWorkout: workoutDays.contains(day))
                } else {
                    Color.clear.frame(height: 40)
                }
            }
        }
    }

    private func dayCell(_ day: Date, hasWorkout: Bool) -> some View {
        let isSelected = selectedDay == day
        let isToday = history.calendar.isDateInToday(day)
        return Button {
            selectedDay = day
        } label: {
            VStack(spacing: 3) {
                Text(day.formatted(.dateTime.day()))
                    .font(.callout.weight(isToday ? .bold : .regular))
                    .monospacedDigit()
                    .foregroundStyle(isSelected ? Color.accentForeground : (isToday ? Color.accentColor : Color.primary))
                Circle()
                    .fill(hasWorkout ? (isSelected ? Color.accentForeground : Color.accentColor) : Color.clear)
                    .frame(width: 5, height: 5)
            }
            .frame(maxWidth: .infinity, minHeight: 40)
            .background(isSelected ? Color.accentColor : Color.clear, in: RoundedRectangle(cornerRadius: 10))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(day.formatted(date: .complete, time: .omitted) + (hasWorkout ? ", workout logged" : ""))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityIdentifier("calendar.day.\(history.dayID(day))")
    }
}
