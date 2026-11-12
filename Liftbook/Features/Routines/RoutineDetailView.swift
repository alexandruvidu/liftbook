import SwiftData
import SwiftUI

/// Read-only view of a routine with Start Workout and Edit.
struct RoutineDetailView: View {
    let routine: Routine
    let catalog: ExerciseCatalog
    let onStart: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var isEditing = false
    @Query private var machines: [Machine]

    var body: some View {
        if routine.isDeleted || routine.modelContext == nil {
            ContentUnavailableView("Routine deleted", systemImage: "trash")
        } else {
            content
        }
    }

    private var content: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Button(action: onStart) {
                    Label("Start Workout", systemImage: "play.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                }
                .buttonStyle(.pillProminent)
                .accessibilityIdentifier("routine.start")

                BlockSection("Exercises") {
                    ForEach(Array(routine.orderedEntries.enumerated()), id: \.element.persistentModelID) { index, entry in
                        let sets = entry.setCount == 1 ? "1 set" : "\(entry.setCount) sets"
                        ExerciseHeaderLink(exerciseID: entry.exerciseID,
                                           name: catalog.name(for: entry.exerciseID),
                                           subtitle: [sets, machines.name(for: entry.machineID)]
                                               .compactMap { $0 }.joined(separator: " · "),
                                           equipment: catalog.exercise(id: entry.exerciseID)?.equipment ?? .other,
                                           thumbnailSize: 40,
                                           identifier: "routine.detail.exercise.\(index)")
                    }
                }

                if !routine.notes.isEmpty {
                    BlockSection("Notes") {
                        Text(routine.notes)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .padding(16)
        }
        .blockScreenBackground()
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
