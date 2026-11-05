import SwiftData
import SwiftUI

/// Full-screen view of the workout in progress.
struct LiveWorkoutView: View {
    let session: WorkoutSession
    /// Called when the user confirms discarding; the presenter deletes the session.
    let onDiscard: () -> Void

    @Environment(\.dismiss) private var dismiss
    @Query private var customExercises: [CustomExercise]
    @State private var isPicking = false
    @State private var isConfirmingDiscard = false

    var body: some View {
        let catalog = ExerciseCatalog(custom: customExercises.map(\.asLibraryExercise))
        NavigationStack {
            List {
                Section {
                    TimelineView(.periodic(from: .now, by: 1)) { context in
                        LabeledContent("Elapsed", value: SetMeasurement.clock(context.date.timeIntervalSince(session.startedAt)))
                            .monospacedDigit()
                    }
                    .accessibilityIdentifier("live.elapsed")
                }

                if session.exercises.isEmpty {
                    Section {
                        Text("Add your first exercise to start logging sets.")
                            .foregroundStyle(.secondary)
                    }
                }

                ForEach(Array(session.orderedExercises.enumerated()), id: \.element.id) { index, exercise in
                    LiveExerciseSection(exercise: exercise,
                                        info: catalog.exercise(id: exercise.exerciseID),
                                        fallbackName: catalog.name(for: exercise.exerciseID),
                                        identifier: "live.exercise.\(index)")
                }

                Section {
                    Button("Add Exercises", systemImage: "plus.circle.fill") { isPicking = true }
                        .accessibilityIdentifier("live.addExercises")
                }

                Section {
                    Button("Discard Workout", role: .destructive) { isConfirmingDiscard = true }
                        .accessibilityIdentifier("live.discard")
                }
            }
            .listStyle(.insetGrouped)
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle(session.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Minimize", systemImage: "chevron.down") { dismiss() }
                        .accessibilityIdentifier("live.minimize")
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    }
                    .accessibilityIdentifier("live.keyboardDone")
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Finish") {
                        session.endedAt = .now
                        dismiss()
                    }
                    .accessibilityIdentifier("live.finish")
                }
            }
            .sheet(isPresented: $isPicking) {
                ExercisePickerView(catalog: catalog) { session.addExercises($0) }
            }
            .confirmationDialog("Discard this workout?", isPresented: $isConfirmingDiscard, titleVisibility: .visible) {
                Button("Discard Workout", role: .destructive, action: onDiscard)
                    .accessibilityIdentifier("live.confirmDiscard")
            } message: {
                Text("Nothing from this session will be saved.")
            }
        }
    }
}
