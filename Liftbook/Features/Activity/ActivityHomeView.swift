import SwiftData
import SwiftUI

/// History and progress in one place: this week, shortcuts into the charts,
/// then every finished workout.
struct ActivityHomeView: View {
    enum Destination: Hashable {
        case exercises, muscles, records, calendar
    }

    @Query(filter: #Predicate<WorkoutSession> { $0.endedAt != nil }, sort: \WorkoutSession.startedAt, order: .reverse)
    private var sessions: [WorkoutSession]
    @Query private var customExercises: [CustomExercise]
    @AppStorage(WeeklyGoal.storageKey) private var goal = WeeklyGoal.defaultGoal
    @Environment(WorkoutStartController.self) private var starter

    var body: some View {
        let catalog = ExerciseCatalog(custom: customExercises.map(\.asLibraryExercise))
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 12) {
                    let week = WeekActivity.week(containing: .now, sessions: sessions, goal: goal) {
                        catalog.exercise(id: $0)?.type ?? .weightAndReps
                    }
                    WeekStrip(week: week)
                    shortcuts
                    SectionTitle("History")
                    if sessions.isEmpty {
                        ContentUnavailableView {
                            Label("No sessions logged", systemImage: "clock.arrow.circlepath")
                        } description: {
                            Text("Finished workouts land here, newest first, with charts and records once you've logged a few.")
                        }
                        .accessibilityIdentifier("activity.empty")
                    } else {
                        ForEach(Array(sessions.enumerated()), id: \.element.sessionID) { index, session in
                            NavigationLink(value: session) {
                                WorkoutCard(session: session, catalog: catalog)
                            }
                            .buttonStyle(.plain)
                            .accessibilityIdentifier("history.row")
                            // Beside the link, not inside it, so it gets its own taps.
                            .overlay(alignment: .topTrailing) {
                                ShareWorkoutButton(session: session, catalog: catalog, compact: true)
                                    .padding(10)
                                    .accessibilityIdentifier("workoutCard.share.\(index)")
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
            .blockScreenBackground()
            .navigationTitle(AppTab.activity.title)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    NavigationLink(value: Destination.calendar) {
                        Label("Calendar", systemImage: "calendar")
                    }
                    .accessibilityIdentifier("activity.calendar")
                }
            }
            .navigationDestination(for: Destination.self) { destination in
                switch destination {
                case .exercises: ProgressExercisesView(sessions: sessions, catalog: catalog)
                case .muscles: MusclesView(sessions: sessions, catalog: catalog)
                case .records: RecordsOverviewView(sessions: sessions, catalog: catalog)
                case .calendar:
                    HistoryCalendarView(sessions: sessions, catalog: catalog)
                        .navigationTitle("Calendar")
                }
            }
            .navigationDestination(for: WorkoutSession.self) { session in
                WorkoutDetailView(session: session, catalog: catalog) { starter.start(.repeating(session)) }
            }
            .navigationDestination(for: String.self) { ExerciseDetailView(exerciseID: $0) }
        }
    }

    private var shortcuts: some View {
        HStack(spacing: 8) {
            shortcut("Exercises", systemImage: "chart.line.uptrend.xyaxis", destination: .exercises)
            shortcut("Muscles", systemImage: "chart.bar.fill", destination: .muscles)
            shortcut("Records", systemImage: "trophy.fill", destination: .records)
        }
    }

    private func shortcut(_ title: String, systemImage: String, destination: Destination) -> some View {
        NavigationLink(value: destination) {
            VStack(spacing: 6) {
                Image(systemName: systemImage)
                    .font(.title3)
                    .foregroundStyle(.tint)
                    .accessibilityHidden(true)
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .frame(maxWidth: .infinity, minHeight: 64)
            .padding(.vertical, 6)
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("activity.shortcut.\(title.lowercased())")
    }
}

#Preview {
    ActivityHomeView()
        .environment(WorkoutStartController())
        .modelContainer(Persistence.makeContainer(inMemory: true))
}
