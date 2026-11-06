import SwiftData
import SwiftUI

/// Edits a finished workout in place: name, time, length, notes and sets.
struct EditWorkoutView: View {
    @Bindable var session: WorkoutSession
    let catalog: ExerciseCatalog

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var isPicking = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    TextField("Name", text: $session.name)
                        .accessibilityIdentifier("edit.name")
                    DatePicker("Started", selection: Binding(get: { session.startedAt }, set: { session.moveStart(to: $0) }))
                        .accessibilityIdentifier("edit.start")
                    Stepper(value: Binding(get: { session.durationMinutes }, set: { session.setDuration(minutes: $0) }),
                            in: 1...(24 * 60), step: 5) {
                        LabeledContent("Duration", value: "\(session.durationMinutes) min")
                    }
                    .accessibilityIdentifier("edit.duration")
                    TextField("Workout notes", text: $session.notes, axis: .vertical)
                        .lineLimit(1...6)
                        .accessibilityIdentifier("edit.notes")
                }

                ForEach(Array(session.orderedExercises.enumerated()), id: \.element.stableID) { index, exercise in
                    LiveExerciseSection(exercise: exercise,
                                        info: catalog.exercise(id: exercise.exerciseID),
                                        fallbackName: catalog.name(for: exercise.exerciseID),
                                        identifier: "edit.exercise.\(index)",
                                        startsRest: false)
                }

                Section {
                    Button("Add Exercises", systemImage: "plus.circle.fill") { isPicking = true }
                        .accessibilityIdentifier("edit.addExercises")
                }
            }
            .listStyle(.insetGrouped)
            .scrollDismissesKeyboard(.interactively)
            .keyboardDoneButton()
            .navigationTitle("Edit Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        session.name = session.name.trimmedNote.isEmpty ? "Workout" : session.name.trimmedNote
                        session.notes = session.notes.trimmedNote
                        try? modelContext.save()
                        dismiss()
                    }
                    .accessibilityIdentifier("edit.done")
                }
            }
            .sheet(isPresented: $isPicking) {
                ExercisePickerView(catalog: catalog) {
                    session.addExercises($0)
                    try? modelContext.save()
                }
            }
        }
    }
}
