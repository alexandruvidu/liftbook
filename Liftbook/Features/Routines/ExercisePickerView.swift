import SwiftData
import SwiftUI

/// Picks exercises from the same photo grid and filters as the Exercises
/// tab, with recently done ones first. Returns IDs in the order tapped.
struct ExercisePickerView: View {
    let catalog: ExerciseCatalog
    let onAdd: ([String]) -> Void

    @Environment(\.dismiss) private var dismiss
    @Query(filter: #Predicate<WorkoutSession> { $0.endedAt != nil }, sort: \WorkoutSession.startedAt, order: .reverse)
    private var finishedSessions: [WorkoutSession]
    @State private var filter = ExerciseFilter()
    @State private var selection: [String] = []

    var body: some View {
        NavigationStack {
            let browsing = filter.query.isEmpty
            let results = browsing
                ? ExerciseBrowsing.featuredFirst(filter.apply(to: catalog.exercises))
                : filter.apply(to: catalog.exercises)
            // Recent ones follow the muscle and equipment filters too.
            let recent = browsing
                ? ExerciseBrowsing.recentIDs(in: finishedSessions).compactMap(catalog.exercise(id:)).filter(filter.matches)
                : []
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    ExerciseFilterBar(filter: $filter, resultCount: results.count)
                    if !recent.isEmpty {
                        SectionTitle("Recent")
                        grid(recent, section: "recent")
                        SectionTitle("All Exercises")
                    }
                    grid(results, section: "all")
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
            .blockScreenBackground()
            .scrollDismissesKeyboard(.immediately)
            .overlay {
                if results.isEmpty {
                    ContentUnavailableView.search(text: filter.query)
                }
            }
            .safeAreaInset(edge: .bottom) {
                if !selection.isEmpty { addButton }
            }
            .searchable(text: $filter.query, placement: .navigationBarDrawer(displayMode: .always),
                        prompt: "Search by name, muscle or equipment")
            .navigationTitle("Add Exercises")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    /// Cards that toggle selection, numbered in the order picked. `section`
    /// keeps identifiers unique when an exercise shows under Recent too.
    private func grid(_ exercises: [LibraryExercise], section: String) -> some View {
        ExerciseCardGrid(exercises: exercises) { exercise, card in
            let order = selection.firstIndex(of: exercise.id)
            Button {
                toggle(exercise.id)
            } label: {
                card
                    .overlay {
                        RoundedRectangle(cornerRadius: 18)
                            .strokeBorder(Color.accentColor, lineWidth: order == nil ? 0 : 3)
                    }
                    .overlay(alignment: .topLeading) {
                        if let order { OrderBadge(number: order + 1) }
                    }
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier(section == "all" ? "picker.row.\(exercise.id)" : "picker.\(section).\(exercise.id)")
            .accessibilityAddTraits(order != nil ? .isSelected : [])
        }
    }

    private var addButton: some View {
        Button {
            onAdd(selection)
            dismiss()
        } label: {
            Text(selection.count == 1 ? "Add 1 Exercise" : "Add \(selection.count) Exercises")
                .font(.headline)
                .foregroundStyle(Color.accentForeground)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
        }
        .buttonStyle(.borderedProminent)
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
        .accessibilityIdentifier("picker.add")
    }

    private func toggle(_ id: String) {
        if let index = selection.firstIndex(of: id) {
            selection.remove(at: index)
        } else {
            selection.append(id)
        }
    }
}

/// The pick order shown on a selected card.
private struct OrderBadge: View {
    let number: Int

    var body: some View {
        Text("\(number)")
            .font(.subheadline.weight(.bold))
            .monospacedDigit()
            .foregroundStyle(Color.accentForeground)
            // Grows with the text; a fixed circle clipped at large sizes.
            .padding(.horizontal, 8)
            .frame(minWidth: 28, minHeight: 28)
            .background(Capsule().fill(Color.accentColor))
            .fixedSize()
            .padding(8)
            .accessibilityHidden(true)
    }
}
