import SwiftData
import SwiftUI

/// Sheet for creating (`routine == nil`) or editing a routine.
struct RoutineEditorView: View {
    let routine: Routine?

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \RoutineFolder.sortIndex) private var folders: [RoutineFolder]
    @Query private var customExercises: [CustomExercise]
    @Query(sort: \Machine.createdAt) private var machines: [Machine]
    @State private var draft: RoutineDraft
    @State private var isPicking = false
    @State private var isConfirmingDelete = false
    @State private var isConfirmingDiscard = false
    /// The routine as it was when the sheet opened, to spot unsaved changes.
    private let original: RoutineDraft

    init(routine: Routine?) {
        self.routine = routine
        original = routine.map(RoutineDraft.init(routine:)) ?? RoutineDraft()
        _draft = State(initialValue: original)
    }

    private var hasChanges: Bool { draft != original }

    var body: some View {
        let catalog = ExerciseCatalog(custom: customExercises.map(\.asLibraryExercise))
        NavigationStack {
            Form {
                Section {
                    TextField("Routine name", text: $draft.name)
                        .textInputAutocapitalization(.words)
                        .accessibilityIdentifier("routine.name")
                    Picker("Folder", selection: $draft.folderID) {
                        Text("None").tag(UUID?.none)
                        ForEach(folders) { Text($0.name).tag(Optional($0.folderID)) }
                    }
                    .accessibilityIdentifier("routine.folder")
                }

                Section {
                    ForEach($draft.entries) { $entry in
                        let index = draft.entries.firstIndex { $0.id == entry.id } ?? 0
                        RoutineEntryRow(name: catalog.name(for: entry.exerciseID), setCount: $entry.setCount,
                                        machines: machines.of(entry.exerciseID), machineID: $entry.machineID,
                                        identifier: "routine.entry.\(index)")
                    }
                    .onMove { draft.move(from: $0, to: $1) }
                    .onDelete { draft.remove(at: $0) }

                    Button("Add Exercises", systemImage: "plus.circle.fill") { isPicking = true }
                        .accessibilityIdentifier("routine.addExercises")
                } header: {
                    Text("Exercises")
                } footer: {
                    if !draft.entries.isEmpty {
                        Text("Drag the handles to reorder. Swipe or tap the minus to remove.")
                    }
                }

                Section("Notes") {
                    TextField("Optional", text: $draft.notes, axis: .vertical)
                        .lineLimit(2...6)
                }

                if routine != nil {
                    Section {
                        Button("Delete Routine", role: .destructive) { isConfirmingDelete = true }
                            .accessibilityIdentifier("routine.delete")
                            .confirmationDialog("Delete \(draft.trimmedName)?", isPresented: $isConfirmingDelete,
                                                titleVisibility: .visible) {
                                Button("Delete Routine", role: .destructive, action: delete)
                                Button("Cancel", role: .cancel) {}
                            } message: {
                                Text("Past workouts started from it are not affected.")
                            }
                    }
                }
            }
            .environment(\.editMode, .constant(.active))
            .navigationTitle(routine == nil ? "New Routine" : "Edit Routine")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        if hasChanges { isConfirmingDiscard = true } else { dismiss() }
                    }
                    .accessibilityIdentifier("routine.cancel")
                    // An alert, not a dialog: anchored to a toolbar button, a dialog
                    // shows as a bare popover without its title or cancel button.
                    .alert("Discard your changes?", isPresented: $isConfirmingDiscard) {
                        Button("Discard Changes", role: .destructive) { dismiss() }
                            .accessibilityIdentifier("routine.discardChanges")
                        Button("Keep Editing", role: .cancel) {}
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                        .disabled(!draft.problems.isEmpty)
                        .accessibilityIdentifier("routine.save")
                }
            }
            .sheet(isPresented: $isPicking) {
                ExercisePickerView(catalog: catalog) { draft.add($0) }
            }
        }
        // Swiping the sheet away would silently lose a half-made routine.
        .interactiveDismissDisabled(hasChanges)
    }

    private func save() {
        guard draft.problems.isEmpty else { return }
        let target = routine ?? Routine()
        if routine == nil {
            modelContext.insert(target)
        }
        let folder = folders.first { $0.folderID == draft.folderID }
        target.apply(draft, folder: folder, in: modelContext)
        dismiss()
    }

    private func delete() {
        if let routine {
            modelContext.delete(routine)
        }
        dismiss()
    }
}

private struct RoutineEntryRow: View {
    let name: String
    @Binding var setCount: Int
    let machines: [Machine]
    @Binding var machineID: UUID?
    let identifier: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(name)
            Stepper(value: $setCount, in: RoutineDraft.setCountRange) {
                Text(setCount == 1 ? "1 set" : "\(setCount) sets")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            if !machines.isEmpty {
                Picker("Machine", selection: $machineID) {
                    Text("Last used").tag(UUID?.none)
                    ForEach(machines) { Text($0.name).tag(Optional($0.machineID)) }
                }
                .font(.subheadline)
                .accessibilityIdentifier("\(identifier).machine")
            }
        }
    }
}
