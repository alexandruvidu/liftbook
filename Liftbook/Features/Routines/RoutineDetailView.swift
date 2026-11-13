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
        List {
            Section {
                Button(action: onStart) {
                    // One Text with the icon inline, so it wraps as a whole at
                    // accessibility sizes instead of clipping.
                    Text("\(Image(systemName: "play.fill")) Start Workout")
                        .font(.headline)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                }
                .prominentGlassButton()
                .accessibilityLabel("Start Workout")
                .accessibilityIdentifier("routine.start")
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            }

            Section("Exercises") {
                ForEach(Array(routine.orderedEntries.enumerated()), id: \.element.persistentModelID) { index, entry in
                    let sets = entry.setCount == 1 ? "1 set" : "\(entry.setCount) sets"
                    ExerciseHeaderLink(exerciseID: entry.exerciseID,
                                       name: catalog.name(for: entry.exerciseID),
                                       subtitle: [sets, machines.name(for: entry.machineID)]
                                           .compactMap { $0 }.joined(separator: " · "),
                                       equipment: catalog.exercise(id: entry.exerciseID)?.equipment ?? .other,
                                       thumbnailSize: 40,
                                       inList: true,
                                       identifier: "routine.detail.exercise.\(index)")
                }
            }

            if !routine.notes.isEmpty {
                Section("Notes") {
                    Text(routine.notes)
                }
            }
        }
        .navigationTitle(routine.name)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                // An icon: toolbar text stops growing with Dynamic Type, icons
                // show in the large content viewer.
                Button("Edit", systemImage: "pencil") { isEditing = true }
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
