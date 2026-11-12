import SwiftUI

/// Exercises done in finished workouts, most recently done first; each opens
/// its charts and records.
struct ProgressExercisesView: View {
    let sessions: [WorkoutSession]
    let catalog: ExerciseCatalog

    var body: some View {
        List {
            Section {
                ForEach(LoggedExercises.list(in: sessions), id: \.exerciseID) { item in
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
            } footer: {
                Text("Open an exercise to see its charts and personal records.")
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Exercise Progress")
    }
}

/// Weekly sets and volume per muscle group.
struct MusclesView: View {
    let sessions: [WorkoutSession]
    let catalog: ExerciseCatalog

    var body: some View {
        List {
            WeeklyMuscleChart(sessions: sessions, catalog: catalog)
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Muscles")
    }
}

/// The best records of every logged exercise.
struct RecordsOverviewView: View {
    let sessions: [WorkoutSession]
    let catalog: ExerciseCatalog
    @AppStorage(WeightUnit.storageKey) private var unit: WeightUnit = .kilograms

    var body: some View {
        List {
            ForEach(LoggedExercises.list(in: sessions), id: \.exerciseID) { item in
                let type = catalog.exercise(id: item.exerciseID)?.type ?? .weightAndReps
                let records = PersonalRecords.records(for: item.exerciseID, type: type, in: sessions)
                if !records.isEmpty {
                    Section {
                        NavigationLink(value: item.exerciseID) {
                            Text(catalog.name(for: item.exerciseID))
                                .font(.headline)
                        }
                        ForEach(records, id: \.kind) { record in
                            LabeledContent(record.kind.title, value: record.kind.formatted(record.value, unit: unit))
                                .monospacedDigit()
                                .accessibilityElement(children: .combine)
                                .accessibilityIdentifier("records.\(item.exerciseID).\(record.kind.rawValue)")
                        }
                    }
                }
            }
        }
        .navigationTitle("Records")
    }
}

/// Exercises that appear in finished workouts.
enum LoggedExercises {
    struct Item: Equatable {
        let exerciseID: String
        let lastDone: Date
        let workouts: Int
    }

    /// Most recently done first.
    static func list(in sessions: [WorkoutSession]) -> [Item] {
        var last: [String: Date] = [:]
        var counts: [String: Int] = [:]
        for session in sessions where session.endedAt != nil {
            for id in Set(session.exercises.map(\.exerciseID)) {
                last[id] = max(last[id] ?? .distantPast, session.startedAt)
                counts[id, default: 0] += 1
            }
        }
        return last.map { Item(exerciseID: $0.key, lastDone: $0.value, workouts: counts[$0.key] ?? 0) }
            .sorted { $0.lastDone > $1.lastDone }
    }
}
