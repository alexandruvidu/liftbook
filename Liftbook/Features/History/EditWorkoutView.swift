import SwiftData
import SwiftUI

/// Edits a finished workout in place: name, time, length, notes and sets.
struct EditWorkoutView: View {
    @Bindable var session: WorkoutSession
    let catalog: ExerciseCatalog

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var isPicking = false
    @State private var collapsed: Set<ObjectIdentifier> = []
    /// Exercise pages opened from a block's menu.
    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(spacing: 12) {
                    Block {
                        TextField("Name", text: $session.name)
                            .font(.headline)
                            .accessibilityIdentifier("edit.name")
                        Divider()
                        DatePicker("Started", selection: Binding(get: { session.startedAt }, set: { session.moveStart(to: $0) }))
                            .accessibilityIdentifier("edit.start")
                        Divider()
                        Stepper(value: Binding(get: { session.durationMinutes }, set: { session.setDuration(minutes: $0) }),
                                in: 1...(24 * 60), step: 5) {
                            LabeledContent("Duration", value: "\(session.durationMinutes) min")
                        }
                        .accessibilityIdentifier("edit.duration")
                        Divider()
                        TextField("Workout notes", text: $session.notes, axis: .vertical)
                            .lineLimit(1...6)
                            .accessibilityIdentifier("edit.notes")
                    }

                    let ordered = session.orderedExercises
                    VStack(spacing: 12) {
                        ForEach(ordered, id: \.stableID) { exercise in
                            ExerciseBlock(exercise: exercise,
                                          info: catalog.exercise(id: exercise.exerciseID),
                                          fallbackName: catalog.name(for: exercise.exerciseID),
                                          identifier: "edit.exercise.\(ordered.firstIndex { $0 === exercise } ?? 0)",
                                          startsRest: false,
                                          isCollapsed: $collapsed.member(exercise.stableID))
                        }
                        .reorderableIfAvailable()
                    }
                    .reordersExercises(of: session)

                    Button {
                        isPicking = true
                    } label: {
                        Label("Add Exercises", systemImage: "plus")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 6)
                    }
                    .buttonStyle(.glass)
                    .accessibilityIdentifier("edit.addExercises")
                }
                .padding(16)
            }
            .swipeActionsContainerIfAvailable()
            .blockScreenBackground()
            .scrollDismissesKeyboard(.interactively)
            .keyboardDoneButton()
            .revealsFocusedFields()
            .exercisePageDestination()
            .opensExercisePages(on: $path)
            // A workout always needs a name: cards and exports show it.
            .onDisappear {
                if session.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    session.name = WorkoutStarter.defaultName(at: session.startedAt)
                }
            }
            .navigationTitle("Edit Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        session.name = session.name.trimmedNote.isEmpty
                            ? WorkoutStarter.defaultName(at: session.startedAt)
                            : session.name.trimmedNote
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
