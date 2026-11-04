import SwiftUI

/// Read-only view of a routine with Start Workout and Edit.
struct RoutineDetailView: View {
    let routine: Routine
    let catalog: ExerciseCatalog
    let onStart: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var isEditing = false

    var body: some View {
        if routine.isDeleted || routine.modelContext == nil {
            ContentUnavailableView("Routine deleted", systemImage: "trash")
        } else {
            content
        }
    }

    private var content: some View {
        List {
            Section {
                Button(action: onStart) {
                    Label("Start Workout", systemImage: "play.fill")
                        .font(.headline)
                        .foregroundStyle(Color.accentForeground)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                }
                .buttonStyle(.borderedProminent)
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
                .accessibilityIdentifier("routine.start")
            }

            Section("Exercises") {
                ForEach(routine.orderedEntries) { entry in
                    LabeledContent(catalog.name(for: entry.exerciseID)) {
                        Text(entry.setCount == 1 ? "1 set" : "\(entry.setCount) sets")
                    }
                }
            }

            if !routine.notes.isEmpty {
                Section("Notes") {
                    Text(routine.notes)
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(routine.name)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Edit") { isEditing = true }
                    .accessibilityIdentifier("routine.edit")
            }
        }
        .sheet(isPresented: $isEditing, onDismiss: {
            if routine.isDeleted || routine.modelContext == nil { dismiss() }
        }) {
            RoutineEditorView(routine: routine)
        }
    }
}
