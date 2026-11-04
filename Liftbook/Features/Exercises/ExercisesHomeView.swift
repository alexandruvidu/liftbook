import SwiftUI

struct ExercisesHomeView: View {
    var library: ExerciseLibrary = .bundled
    @State private var filter = ExerciseFilter()

    private var results: [LibraryExercise] {
        filter.apply(to: library.exercises)
    }

    var body: some View {
        NavigationStack {
            let results = results
            List {
                Section {
                    ExerciseFilterBar(filter: $filter, resultCount: results.count)
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))

                ForEach(ExerciseLibrary.sections(for: results)) { section in
                    Section(section.letter) {
                        ForEach(section.exercises) { exercise in
                            NavigationLink(value: exercise) {
                                ExerciseRow(exercise: exercise)
                            }
                            .accessibilityIdentifier("exercise.row.\(exercise.id)")
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .overlay {
                if results.isEmpty {
                    NoMatchingExercisesView { filter = ExerciseFilter() }
                }
            }
            .searchable(
                text: $filter.query,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "Search by name, muscle or equipment"
            )
            .navigationTitle(AppTab.exercises.title)
            .navigationDestination(for: LibraryExercise.self) { exercise in
                ExerciseDetailView(exercise: exercise)
            }
        }
    }
}

struct ExerciseRow: View {
    let exercise: LibraryExercise

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(exercise.name)
                .font(.body)
            Text(exercise.summary)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
    }
}

private struct NoMatchingExercisesView: View {
    let clear: () -> Void

    var body: some View {
        ContentUnavailableView {
            Label("No matching exercises", systemImage: "magnifyingglass")
        } description: {
            Text("Try a shorter search or loosen the muscle and equipment filters.")
        } actions: {
            Button("Clear Filters", action: clear)
                .buttonStyle(.borderedProminent)
                .accessibilityIdentifier("exercises.clearFilters")
        }
        .accessibilityIdentifier("exercises.noResults")
    }
}

#Preview {
    ExercisesHomeView()
}
