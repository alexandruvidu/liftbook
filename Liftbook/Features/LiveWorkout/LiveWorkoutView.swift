import SwiftData
import SwiftUI

/// Full-screen view of the workout in progress.
struct LiveWorkoutView: View {
    let session: WorkoutSession
    /// Called when the user confirms discarding; the presenter deletes the session.
    let onDiscard: () -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var customExercises: [CustomExercise]
    @Query(filter: #Predicate<WorkoutSession> { $0.endedAt != nil }, sort: \WorkoutSession.startedAt, order: .reverse)
    private var finishedSessions: [WorkoutSession]
    @AppStorage(RestTimer.soundKey) private var restSound = true
    @State private var isPicking = false
    @State private var isConfirmingDiscard = false

    var body: some View {
        let catalog = ExerciseCatalog(custom: customExercises.map(\.asLibraryExercise))
        NavigationStack {
            List {
                if session.exercises.isEmpty {
                    Section {
                        Text("Add your first exercise to start logging sets.")
                            .foregroundStyle(.secondary)
                    }
                }

                ForEach(Array(session.orderedExercises.enumerated()), id: \.element.stableID) { index, exercise in
                    LiveExerciseSection(exercise: exercise,
                                        info: catalog.exercise(id: exercise.exerciseID),
                                        fallbackName: catalog.name(for: exercise.exerciseID),
                                        identifier: "live.exercise.\(index)",
                                        previous: PreviousPerformance.find(exerciseID: exercise.exerciseID,
                                                                           in: finishedSessions, excluding: session))
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
            .safeAreaInset(edge: .bottom) {
                if session.restEndsAt != nil {
                    RestTimerBar(session: session,
                                 exerciseName: session.restExerciseID.map { catalog.name(for: $0) })
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(.snappy, value: session.restEndsAt == nil)
            .task(id: session.restEndsAt) { await runRestTimer(catalog: catalog) }
            .navigationTitle(session.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    VStack(spacing: 0) {
                        Text(session.name)
                            .font(.headline)
                            .lineLimit(1)
                        // A timer-style Text ticks on its own without re-rendering
                        // views, so open menus and focused fields aren't disturbed.
                        Text(session.startedAt, style: .timer)
                            .font(.caption)
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                            .accessibilityIdentifier("live.elapsed")
                    }
                }
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
                        session.stopRest()
                        RestAlerts.cancel()
                        session.endedAt = .now
                        dismiss()
                    }
                    .accessibilityIdentifier("live.finish")
                }
            }
            .sheet(isPresented: $isPicking) {
                ExercisePickerView(catalog: catalog) {
                    session.addExercises($0)
                    try? modelContext.save()
                }
            }
            .confirmationDialog("Discard this workout?", isPresented: $isConfirmingDiscard, titleVisibility: .visible) {
                Button("Discard Workout", role: .destructive) {
                    RestAlerts.cancel()
                    onDiscard()
                }
                    .accessibilityIdentifier("live.confirmDiscard")
            } message: {
                Text("Nothing from this session will be saved.")
            }
        }
    }

    /// Schedules the end-of-rest notification, then waits for the rest to end
    /// to play the sound and hide the timer. Restarted whenever the end changes.
    private func runRestTimer(catalog: ExerciseCatalog) async {
        guard let end = session.restEndsAt else {
            RestAlerts.cancel()
            return
        }
        let name = session.restExerciseID.map { catalog.name(for: $0) } ?? "your workout"
        RestAlerts.schedule(at: end, exerciseName: name, sound: restSound)
        let delay = end.timeIntervalSinceNow
        if delay > 0 {
            try? await Task.sleep(for: .seconds(delay))
        }
        guard !Task.isCancelled, session.restEndsAt == end else { return }
        // Don't beep for a rest that ended while the app was closed.
        if restSound && delay > -2 { RestAlerts.playSound() }
        session.stopRest()
    }
}
