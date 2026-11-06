import SwiftUI

/// Suggests exercises for the same muscles; picking one swaps it in.
struct SwapExerciseView: View {
    let current: LibraryExercise
    let catalog: ExerciseCatalog
    let onPick: (String) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(Substitutions.suggestions(for: current, among: catalog.exercises, limit: 10)) { exercise in
                        Button {
                            onPick(exercise.id)
                            dismiss()
                        } label: {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(exercise.name)
                                    .foregroundStyle(.primary)
                                Text(exercise.summary)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .accessibilityIdentifier("swap.option.\(exercise.id)")
                    }
                } header: {
                    Text("Trains the same muscles as \(current.name)")
                } footer: {
                    Text("Sets you've checked off keep their numbers; the others are cleared.")
                }
            }
            .navigationTitle("Swap Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}
