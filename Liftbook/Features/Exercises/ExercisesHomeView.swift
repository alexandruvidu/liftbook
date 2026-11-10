import SwiftData
import SwiftUI

struct ExercisesHomeView: View {
    var library: ExerciseLibrary = .bundled
    @Query(sort: \CustomExercise.name) private var customExercises: [CustomExercise]
    @Query private var media: [ExerciseMedia]
    @Query private var machines: [Machine]
    @Environment(\.modelContext) private var modelContext
    @State private var filter = ExerciseFilter()
    @State private var isCreating = false

    private var allExercises: [LibraryExercise] {
        ExerciseLibrary(exercises: library.exercises + customExercises.map(\.asLibraryExercise)).exercises
    }

    var body: some View {
        NavigationStack {
            let results = filter.apply(to: allExercises)
            let cover = Dictionary(grouping: media, by: \.exerciseID).compactMapValues { $0.display(for: $0[0].exerciseID).first }
            let machineCounts = Dictionary(grouping: machines, by: \.exerciseID).mapValues(\.count)
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    ExerciseFilterBar(filter: $filter, resultCount: results.count)
                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                        ForEach(results) { exercise in
                            NavigationLink(value: exercise) {
                                ExerciseCard(exercise: exercise, cover: cover[exercise.id],
                                             machineCount: machineCounts[exercise.id] ?? 0)
                            }
                            .buttonStyle(.plain)
                            .accessibilityIdentifier("exercise.row.\(exercise.id)")
                            .contextMenu {
                                if exercise.isCustom {
                                    Button("Delete", systemImage: "trash", role: .destructive) { delete(exercise) }
                                }
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
            .searchable(
                text: $filter.query,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "Search by name, muscle or equipment"
            )
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

struct ExerciseRow: View {
    let exercise: LibraryExercise

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(exercise.name)
                    .font(.body)
                Text(exercise.summary)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            if exercise.isCustom {
                Spacer(minLength: 8)
                Text("Custom")
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .foregroundStyle(.tint)
                    .background(Capsule().fill(Color.accentColor.opacity(0.15)))
            }
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
            Text("Try a shorter or different search, or fewer muscle and equipment filters.")
        } actions: {
            Button(action: clear) {
                Text("Show All Exercises").foregroundStyle(Color.accentForeground)
            }
            .buttonStyle(.borderedProminent)
            .accessibilityIdentifier("exercises.clearFilters")
        }
    }
}

#Preview {
    ExercisesHomeView()
        .modelContainer(Persistence.makeContainer(inMemory: true))
}
