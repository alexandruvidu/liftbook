import SwiftData
import SwiftUI

struct ExercisesHomeView: View {
    var library: ExerciseLibrary = .bundled
    @Query(sort: \CustomExercise.name) private var customExercises: [CustomExercise]
    @Environment(\.modelContext) private var modelContext
    @State private var filter = ExerciseFilter()
    @State private var isCreating = false

    private var allExercises: [LibraryExercise] {
        ExerciseLibrary(exercises: library.exercises + customExercises.map(\.asLibraryExercise)).exercises
    }

    var body: some View {
        NavigationStack {
            let results = filter.query.isEmpty
                ? ExerciseBrowsing.featuredFirst(filter.apply(to: allExercises))
                : filter.apply(to: allExercises)
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    ExerciseFilterBar(filter: $filter, resultCount: results.count)
                    ExerciseCardGrid(exercises: results) { exercise, card in
                        NavigationLink(value: exercise) { card }
                            .buttonStyle(.plain)
                            .accessibilityIdentifier("exercise.row.\(exercise.id)")
                            .contextMenu {
                                if exercise.isCustom {
                                    Button("Delete", systemImage: "trash", role: .destructive) { delete(exercise) }
                                }
                            }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
            .blockScreenBackground()
            .overlay {
                if results.isEmpty {
                    NoMatchingExercisesView { filter = ExerciseFilter() }
                }
            }
            // Kept under the title: in a tab the default placement hides the
            // field until you pull down, and search is how this screen is used.
            .searchable(text: $filter.query, placement: .navigationBarDrawer(displayMode: .always),
                        prompt: "Search by name, muscle or equipment")
            .navigationTitle(AppTab.exercises.title)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("New Exercise", systemImage: "plus") { isCreating = true }
                        .accessibilityIdentifier("exercises.add")
                }
            }
            .sheet(isPresented: $isCreating) {
                ExerciseEditorView(editing: nil)
            }
            .navigationDestination(for: LibraryExercise.self) { exercise in
                ExerciseDetailView(exerciseID: exercise.id)
            }
        }
    }

    private func delete(_ exercise: LibraryExercise) {
        guard let custom = customExercises.first(where: { $0.exerciseID == exercise.id }) else { return }
        modelContext.delete(custom)
    }
}

private struct NoMatchingExercisesView: View {
    let clear: () -> Void

    var body: some View {
        ContentUnavailableView {
            Label("No matching exercises", systemImage: "magnifyingglass")
        } description: {
            Text("Try a shorter or different search, or fewer muscle and equipment filters.")
        } actions: {
            Button(action: clear) {
                Text("Show All Exercises")
            }
            .prominentGlassButton()
            .accessibilityIdentifier("exercises.clearFilters")
        }
    }
}

#Preview {
    ExercisesHomeView()
        .modelContainer(Persistence.makeContainer(inMemory: true))
}
