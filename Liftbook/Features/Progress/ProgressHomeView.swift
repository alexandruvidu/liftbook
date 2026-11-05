import SwiftData
import SwiftUI

struct ProgressHomeView: View {
    @Query(filter: #Predicate<WorkoutSession> { $0.endedAt != nil }, sort: \WorkoutSession.startedAt, order: .reverse)
    private var sessions: [WorkoutSession]
    @Query private var customExercises: [CustomExercise]

    var body: some View {
        let catalog = ExerciseCatalog(custom: customExercises.map(\.asLibraryExercise))
        NavigationStack {
            Group {
                if sessions.isEmpty {
                    ContentUnavailableView {
                        Label("Nothing to chart yet", systemImage: AppTab.progress.systemImage)
                    } description: {
                        Text("Log a few workouts and your strength trends, records and weekly volume will show up here.")
                    }
                    .accessibilityIdentifier("progress.empty")
                } else {
                    List {
                        WeeklyMuscleChart(sessions: sessions, catalog: catalog)

                        Section {
                            ForEach(loggedExercises, id: \.exerciseID) { item in
                                NavigationLink(value: item.exerciseID) {
                                    LabeledContent {
                                        Text(item.lastDone.formatted(.relative(presentation: .named)))
                                    } label: {
                                        Text(catalog.name(for: item.exerciseID))
                                        Text("\(item.workouts) workout\(item.workouts == 1 ? "" : "s")")
                                    }
                                }
                                .accessibilityIdentifier("progress.exercise.\(item.exerciseID)")
                            }
                        } header: {
                            Text("Exercises")
                        } footer: {
                            Text("Open an exercise to see its charts and personal records.")
                        }
                    }
                    .listStyle(.insetGrouped)
                    .navigationDestination(for: String.self) { ExerciseDetailView(exerciseID: $0) }
                }
            }
            .navigationTitle(AppTab.progress.title)
        }
    }

    /// Exercises done in finished workouts, most recently done first.
    private var loggedExercises: [(exerciseID: String, lastDone: Date, workouts: Int)] {
        var last: [String: Date] = [:]
        var counts: [String: Int] = [:]
        for session in sessions {
            for id in Set(session.exercises.map(\.exerciseID)) {
                last[id] = max(last[id] ?? .distantPast, session.startedAt)
                counts[id, default: 0] += 1
            }
        }
        return last.map { ($0.key, $0.value, counts[$0.key] ?? 0) }.sorted { $0.1 > $1.1 }
    }
}

#Preview {
    ProgressHomeView()
        .modelContainer(Persistence.makeContainer(inMemory: true))
}
