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
    @Query(sort: \Machine.createdAt) private var allMachines: [Machine]
    /// An exercise just added that has machines: its block asks which one.
    @State private var askMachineFor: ObjectIdentifier?
    @Query(filter: #Predicate<WorkoutSession> { $0.endedAt != nil }, sort: \WorkoutSession.startedAt, order: .reverse)
    private var finishedSessions: [WorkoutSession]
    @AppStorage(RestTimer.soundKey) private var restSound = true
    @State private var isPicking = false
    @State private var isConfirmingDiscard = false
    @State private var isEditingNote = false
    /// Exercises the user folded down to their header.
    @State private var collapsed: Set<ObjectIdentifier> = []
    /// Set when the workout is finished; shows the summary instead of the list.
    @State private var summary: WorkoutSummary?

    var body: some View {
        let catalog = ExerciseCatalog(custom: customExercises.map(\.asLibraryExercise))
        NavigationStack {
            if let summary {
                FinishSummaryView(session: session, summary: summary, catalog: catalog) { dismiss() }
            } else {
                liveList(catalog: catalog)
            }
        }
    }

    /// The workout in progress: totals, then each exercise as a block.
    private func liveList(catalog: ExerciseCatalog) -> some View {
        ScrollView {
            VStack(spacing: 12) {
                WorkoutStatStrip(session: session, stats: WorkoutStats.of(session) {
                    catalog.exercise(id: $0)?.type ?? .weightAndReps
                })

                if session.exercises.isEmpty {
                    Text("Add your first exercise to start logging sets.")
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 24)
                }

                ForEach(Array(session.orderedExercises.enumerated()), id: \.element.stableID) { index, exercise in
                    let machines = allMachines.of(exercise.exerciseID)
                    ExerciseBlock(exercise: exercise,
                                  info: catalog.exercise(id: exercise.exerciseID),
                                  fallbackName: catalog.name(for: exercise.exerciseID),
                                  identifier: "live.exercise.\(index)",
                                  // With machines, last time is that machine's (or no machine's).
                                  previous: PreviousPerformance.find(exerciseID: exercise.exerciseID,
                                                                     machine: machines.isEmpty ? .all : MachineFilter(exercise.machineID),
                                                                     in: finishedSessions, excluding: session),
                                  previousNote: PreviousPerformance.note(exerciseID: exercise.exerciseID,
                                                                         in: finishedSessions, excluding: session),
                                  isCollapsed: $collapsed.member(exercise.stableID),
                                  machines: machines,
                                  history: finishedSessions,
                                  asksForMachine: askMachineFor == exercise.stableID,
                                  onMachineAsked: { askMachineFor = nil })
                }

                Button {
                    isPicking = true
                } label: {
                    Label("Add Exercises", systemImage: "plus")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                }
                .buttonStyle(.pillProminent)
                .accessibilityIdentifier("live.addExercises")

                Button("Discard Workout", role: .destructive) { isConfirmingDiscard = true }
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .accessibilityIdentifier("live.discard")
            }
            .padding(16)
        }
        .blockScreenBackground()
        .scrollDismissesKeyboard(.interactively)
        .keyboardDoneButton()
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
            ToolbarItem(placement: .topBarTrailing) {
                Button("Workout Note", systemImage: session.notes.isEmpty ? "note.text.badge.plus" : "note.text") {
                    isEditingNote = true
                }
                .accessibilityIdentifier("live.noteButton")
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Finish") { finish(catalog: catalog) }
                    .buttonStyle(.borderedProminent)
                    .foregroundStyle(Color.accentForeground)
                    .accessibilityIdentifier("live.finish")
            }
        }
        .sheet(isPresented: $isEditingNote) {
            WorkoutNoteSheet(session: session)
        }
        .sheet(isPresented: $isPicking) {
            ExercisePickerView(catalog: catalog) { ids in
                let before = Set(session.exercises.map(\.stableID))
                session.addExercises(ids)
                // Exercises with machines start on the one used last; the
                // first of them asks which machine it is.
                let added = session.orderedExercises.filter { !before.contains($0.stableID) }
                for exercise in added where !allMachines.of(exercise.exerciseID).isEmpty {
                    exercise.machineID = Machine.lastUsed(exerciseID: exercise.exerciseID, in: finishedSessions)
                        .flatMap { id in allMachines.contains { $0.machineID == id } ? id : nil }
                    exercise.machineConfirmed = false
                    if askMachineFor == nil { askMachineFor = exercise.stableID }
                }
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

    private func finish(catalog: ExerciseCatalog) {
        RestAlerts.cancel()
        session.finish()
        try? modelContext.save()
        summary = WorkoutSummary(session: session, history: finishedSessions) {
            catalog.exercise(id: $0)?.type ?? .weightAndReps
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

