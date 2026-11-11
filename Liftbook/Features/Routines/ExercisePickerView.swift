import SwiftUI

/// Searchable multi-select list of exercises. Returns IDs in the order tapped.
struct ExercisePickerView: View {
    let catalog: ExerciseCatalog
    let onAdd: ([String]) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var filter = ExerciseFilter()
    @State private var selection: [String] = []

    var body: some View {
        NavigationStack {
            let results = filter.apply(to: catalog.exercises)
            List(results) { exercise in
                let order = selection.firstIndex(of: exercise.id)
                Button {
                    toggle(exercise.id)
                } label: {
                    HStack {
                        ExerciseRow(exercise: exercise)
                        Spacer()
                        if let order {
                            Text("\(order + 1)")
                                .font(.footnote.weight(.bold))
                                .foregroundStyle(Color.accentForeground)
                                // Grows with the text; a fixed 24 pt circle clipped at large sizes.
                                .padding(.horizontal, 6)
                                .frame(minWidth: 24, minHeight: 24)
                                .background(Capsule().fill(Color.accentColor))
                                .fixedSize()
                        }
                    }
                    .contentShape(Rectangle())
                }
                .foregroundStyle(.primary)
                .accessibilityIdentifier("picker.row.\(exercise.id)")
                .accessibilityAddTraits(order != nil ? .isSelected : [])
            }
            .listStyle(.plain)
            .overlay {
                if results.isEmpty {
                    ContentUnavailableView.search(text: filter.query)
                }
            }
            .safeAreaInset(edge: .bottom) {
                if !selection.isEmpty {
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
            }
            .searchable(text: $filter.query, placement: .navigationBarDrawer(displayMode: .always))
            .navigationTitle("Add Exercises")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func toggle(_ id: String) {
        if let index = selection.firstIndex(of: id) {
            selection.remove(at: index)
        } else {
            selection.append(id)
        }
    }
}
