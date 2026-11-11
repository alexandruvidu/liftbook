import SwiftData
import SwiftUI

/// Read-only view of a routine with Start Workout and Edit.
struct RoutineDetailView: View {
    @Environment(\.dynamicTypeSize) private var typeSize
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
                    ForEach(routine.orderedEntries) { entry in
                        HStack(spacing: 12) {
                            ExerciseThumbnail(exerciseID: entry.exerciseID,
                                              equipment: catalog.exercise(id: entry.exerciseID)?.equipment ?? .other,
                                              size: 40)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(catalog.name(for: entry.exerciseID))
                                if typeSize.isAccessibilitySize {
                                    Text(entry.setCount == 1 ? "1 set" : "\(entry.setCount) sets")
                                        .foregroundStyle(.secondary)
                                }
                                if let machine = machines.name(for: entry.machineID) {
                                    Text(machine)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            Spacer()
                            // Under the name at accessibility sizes, where beside it
                            // the name broke a word per line.
                            if !typeSize.isAccessibilitySize {
                                Text(entry.setCount == 1 ? "1 set" : "\(entry.setCount) sets")
                                    .foregroundStyle(.secondary)
                            }
                        }
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
