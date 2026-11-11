import SwiftData
import SwiftUI

/// Sheet for creating a custom exercise (`editing == nil`) or editing/deleting one.
struct ExerciseEditorView: View {
    @Environment(\.dynamicTypeSize) private var typeSize
    let editing: CustomExercise?
    var onDelete: () -> Void = {}
    var library: ExerciseLibrary = .bundled

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var customExercises: [CustomExercise]
    @State private var draft: ExerciseDraft
    @State private var isConfirmingDelete = false

    init(editing: CustomExercise?, onDelete: @escaping () -> Void = {}) {
        self.editing = editing
        self.onDelete = onDelete
        _draft = State(initialValue: editing.map { ExerciseDraft(exercise: $0.asLibraryExercise) } ?? ExerciseDraft())
    }

    private var existingNames: [String] {
        library.exercises.map(\.name)
            + customExercises.filter { $0.exerciseID != editing?.exerciseID }.map(\.name)
    }

    private var problems: [ExerciseDraft.Problem] {
        draft.problems(existingNames: existingNames)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Name", text: $draft.name)
                        .textInputAutocapitalization(.words)
                        .accessibilityIdentifier("editor.name")
                } footer: {
                    if problems.contains(.duplicateName) {
                        Text(ExerciseDraft.Problem.duplicateName.message)
                            .foregroundStyle(.red)
                    }
                }

                Section {
                    Picker("Logged as", selection: $draft.type) {
                        ForEach(ExerciseType.allCases) { Text($0.displayName).tag($0) }
                    }
                    .pickerStyleFitting(typeSize)
                    .accessibilityIdentifier("editor.type")
                    Picker("Equipment", selection: $draft.equipment) {
                        ForEach(Equipment.allCases) { Text($0.displayName).tag($0) }
                    }
                    .pickerStyleFitting(typeSize)
                    .accessibilityIdentifier("editor.equipment")
                } header: {
                    Text("Tracking")
                } footer: {
                    Text(draft.type.explanation)
                }

                Section {
                    NavigationLink {
                        MuscleSelectionView(title: "Primary Muscles", selection: $draft.primaryMuscles)
                    } label: {
                        LabeledContent("Primary", value: summary(draft.orderedPrimaryMuscles, empty: "Required"))
                    }
                    .accessibilityIdentifier("editor.primary")

                    NavigationLink {
                        MuscleSelectionView(
                            title: "Secondary Muscles",
                            selection: $draft.secondaryMuscles,
                            unavailable: draft.primaryMuscles
                        )
                    } label: {
                        LabeledContent("Secondary", value: summary(draft.orderedSecondaryMuscles, empty: "None"))
                    }
                    .accessibilityIdentifier("editor.secondary")
                } header: {
                    Text("Muscles")
                }

                Section("Notes") {
                    TextField("How to perform it (optional)", text: $draft.details, axis: .vertical)
                        .lineLimit(3...8)
                        .accessibilityIdentifier("editor.details")
                }

                if editing != nil {
                    Section {
                        Button("Delete Exercise", role: .destructive) { isConfirmingDelete = true }
                            .accessibilityIdentifier("editor.delete")
                    }
                }
            }
            .navigationTitle(editing == nil ? "New Exercise" : "Edit Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .accessibilityIdentifier("editor.cancel")
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                        .disabled(!problems.isEmpty)
                        .accessibilityIdentifier("editor.save")
                }
            }
            .confirmationDialog(
                "Delete \(draft.trimmedName)?",
                isPresented: $isConfirmingDelete,
                titleVisibility: .visible
            ) {
                Button("Delete Exercise", role: .destructive, action: delete)
                    .accessibilityIdentifier("editor.confirmDelete")
            } message: {
                Text("This removes the exercise from your library. It can't be undone.")
            }
        }
    }

    private func summary(_ muscles: [Muscle], empty: String) -> String {
        muscles.isEmpty ? empty : muscles.map(\.displayName).joined(separator: ", ")
    }

    private func save() {
        guard problems.isEmpty else { return }
        if let editing {
            editing.update(from: draft)
        } else {
            modelContext.insert(CustomExercise(draft: draft))
        }
        dismiss()
    }

    private func delete() {
        guard let editing else { return }
        modelContext.delete(editing)
        onDelete()
        dismiss()
    }
}

#Preview {
    ExerciseEditorView(editing: nil)
        .modelContainer(Persistence.makeContainer(inMemory: true))
}

private extension View {
    /// A menu normally; a list on its own screen at accessibility text sizes,
    /// where a menu's value is cut off mid-word ("Weig…Reps").
    @ViewBuilder
    func pickerStyleFitting(_ size: DynamicTypeSize) -> some View {
        if size.isAccessibilitySize {
            pickerStyle(.navigationLink)
        } else {
            pickerStyle(.menu)
        }
    }
}
