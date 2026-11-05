import SwiftData
import SwiftUI

struct HistoryHomeView: View {
    enum Mode: String, CaseIterable, Identifiable {
        case list = "List", calendar = "Calendar"
        var id: String { rawValue }
    }

    @Query(filter: #Predicate<WorkoutSession> { $0.endedAt != nil }, sort: \WorkoutSession.startedAt, order: .reverse)
    private var sessions: [WorkoutSession]
    @Query private var customExercises: [CustomExercise]
    @State private var mode: Mode = .list
    @State private var starter = WorkoutStartController()

    var body: some View {
        let catalog = ExerciseCatalog(custom: customExercises.map(\.asLibraryExercise))
        NavigationStack {
            Group {
                if sessions.isEmpty {
                    ContentUnavailableView {
                        Label("No sessions logged", systemImage: AppTab.history.systemImage)
                    } description: {
                        Text("Finished workouts land here, newest first, so you can look back at what you lifted.")
                    }
                    .accessibilityIdentifier("history.empty")
                } else {
                    switch mode {
                    case .list: HistoryListView(sessions: sessions, catalog: catalog)
                    case .calendar: HistoryCalendarView(sessions: sessions, catalog: catalog)
                    }
                }
            }
            .navigationTitle(AppTab.history.title)
            .navigationDestination(for: WorkoutSession.self) { session in
                WorkoutDetailView(session: session, catalog: catalog) { starter.start(.repeating(session)) }
            }
            .toolbar {
                if !sessions.isEmpty {
                    ToolbarItem(placement: .principal) {
                        Picker("View", selection: $mode) {
                            ForEach(Mode.allCases) { Text($0.rawValue).tag($0) }
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 220)
                        .accessibilityIdentifier("history.mode")
                    }
                }
            }
        }
        .workoutStarting(starter)
    }
}

/// Finished workouts grouped by month.
private struct HistoryListView: View {
    let sessions: [WorkoutSession]
    let catalog: ExerciseCatalog

    var body: some View {
        List {
            ForEach(HistoryCalendar().months(of: sessions)) { group in
                Section(group.month.formatted(.dateTime.month(.wide).year())) {
                    ForEach(group.sessions) { HistoryLink(session: $0, catalog: catalog) }
                }
            }
        }
        .listStyle(.insetGrouped)
    }
}

/// A history row that opens the workout's detail page.
struct HistoryLink: View {
    let session: WorkoutSession
    let catalog: ExerciseCatalog

    var body: some View {
        NavigationLink(value: session) {
            HistoryRow(session: session, catalog: catalog)
        }
        .accessibilityIdentifier("history.row")
    }
}

/// One finished workout: name, when, and its totals.
struct HistoryRow: View {
    let session: WorkoutSession
    let catalog: ExerciseCatalog
    @AppStorage(WeightUnit.storageKey) private var unit: WeightUnit = .kilograms

    var body: some View {
        let summary = WorkoutSummary(session: session, history: []) { catalog.exercise(id: $0)?.type ?? .weightAndReps }
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Text(session.name)
                    .font(.headline)
                Spacer()
                Text(session.startedAt.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated)))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            HStack(spacing: 16) {
                Label(SetMeasurement.clock(summary.duration), systemImage: "clock")
                Label("\(summary.setCount) sets", systemImage: "checkmark.circle")
                if summary.volume > 0 {
                    Label("\(unit.display(kilograms: summary.volume).formatted(.number.precision(.fractionLength(0)))) \(unit.symbol)",
                          systemImage: "scalemass")
                }
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .labelStyle(.titleAndIcon)
            Text(exerciseNames)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
        .padding(.vertical, 2)
    }

    private var exerciseNames: String {
        session.orderedExercises.map { catalog.name(for: $0.exerciseID) }.joined(separator: ", ")
    }
}

#Preview {
    HistoryHomeView()
        .modelContainer(Persistence.makeContainer(inMemory: true))
}
