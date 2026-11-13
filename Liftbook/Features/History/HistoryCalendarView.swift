import SwiftUI

/// The system calendar with a dot on each workout day; tap a day to list its workouts.
struct HistoryCalendarView: View {
    let sessions: [WorkoutSession]
    let catalog: ExerciseCatalog

    private let history = HistoryCalendar()
    @State private var selectedDay: Date?

    var body: some View {
        List {
            Section {
                WorkoutCalendar(calendar: history.calendar, workoutDays: history.workoutDays(in: sessions),
                                selectedDay: $selectedDay)
                    .accessibilityIdentifier("calendar")
            }

            if let selectedDay {
                let onDay = history.sessions(on: selectedDay, in: sessions)
                Section(selectedDay.formatted(.dateTime.weekday(.wide).day().month(.wide))) {
                    if onDay.isEmpty {
                        Text("No workout on this day.")
                            .foregroundStyle(.secondary)
                    }
                    ForEach(onDay) { session in
                        NavigationLink(value: session) {
                            CalendarDayRow(session: session, catalog: catalog)
                        }
                        .accessibilityIdentifier("history.row")
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .onAppear {
            // Start on the most recent workout's day.
            if selectedDay == nil, let latest = sessions.first {
                selectedDay = history.calendar.startOfDay(for: latest.startedAt)
            }
        }
    }
}

/// `UICalendarView`: month paging, today, Dynamic Type and VoiceOver come
/// with it. Workout days get a dot; up to today can be picked.
private struct WorkoutCalendar: UIViewRepresentable {
    let calendar: Calendar
    let workoutDays: Set<Date>
    @Binding var selectedDay: Date?

    func makeUIView(context: Context) -> UICalendarView {
        let view = UICalendarView()
        view.calendar = calendar
        view.fontDesign = .rounded
        view.availableDateRange = DateInterval(start: .distantPast, end: .now)
        view.delegate = context.coordinator
        let selection = UICalendarSelectionSingleDate(delegate: context.coordinator)
        view.selectionBehavior = selection
        context.coordinator.selection = selection
        // Fills the row's width instead of its own preferred width.
        view.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return view
    }

    func updateUIView(_ view: UICalendarView, context: Context) {
        let coordinator = context.coordinator
        coordinator.parent = self
        if coordinator.shownDays != workoutDays {
            coordinator.shownDays = workoutDays
            view.reloadDecorations(forDateComponents: workoutDays.map(components), animated: true)
        }
        let selected = selectedDay.map(components)
        if coordinator.selection?.selectedDate != selected {
            coordinator.selection?.setSelected(selected, animated: false)
            if let selected { view.visibleDateComponents = selected }
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator(parent: self) }

    private func components(_ day: Date) -> DateComponents {
        calendar.dateComponents([.calendar, .era, .year, .month, .day], from: day)
    }

    final class Coordinator: NSObject, UICalendarViewDelegate, UICalendarSelectionSingleDateDelegate {
        var parent: WorkoutCalendar
        var shownDays: Set<Date> = []
        weak var selection: UICalendarSelectionSingleDate?

        init(parent: WorkoutCalendar) {
            self.parent = parent
        }

        func calendarView(_ calendarView: UICalendarView,
                          decorationFor dateComponents: DateComponents) -> UICalendarView.Decoration? {
            guard let day = parent.calendar.date(from: dateComponents),
                  parent.workoutDays.contains(parent.calendar.startOfDay(for: day)) else { return nil }
            return .default(color: .tintColor, size: .medium)
        }

        func dateSelection(_ selection: UICalendarSelectionSingleDate, didSelectDate dateComponents: DateComponents?) {
            parent.selectedDay = dateComponents.flatMap { parent.calendar.date(from: $0) }.map(parent.calendar.startOfDay)
        }
    }
}

/// A workout on the selected calendar day.
private struct CalendarDayRow: View {
    let session: WorkoutSession
    let catalog: ExerciseCatalog

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(session.displayName)
                .font(.headline)
            Text(session.orderedExercises.map { catalog.name(for: $0.exerciseID) }.joined(separator: ", "))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
    }
}
