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
    /// An exercise just added that has machines; asked about once the
    /// exercise picker has closed.
    @State private var pendingMachinePick: WorkoutExercise?
    @State private var machinePick: MachinePickTarget?
    @Query(filter: #Predicate<WorkoutSession> { $0.endedAt != nil }, sort: \WorkoutSession.startedAt, order: .reverse)
    private var finishedSessions: [WorkoutSession]
    @AppStorage(RestTimer.soundKey) private var restSound = true
    @AppStorage(RestTimer.keepScreenOnKey) private var keepScreenOn = false
    @State private var isPicking = false
    @State private var isConfirmingDiscard = false
    @State private var isEditingNote = false
    /// Exercises the user folded down to their header.
    @State private var collapsed: Set<ObjectIdentifier> = []
    /// Set when the workout is finished; shows the summary instead of the list.
    @State private var summary: WorkoutSummary?
    /// Exercise pages opened from a block's menu.
    @State private var path = NavigationPath()

    var body: some View {
        let catalog = ExerciseCatalog(custom: customExercises.map(\.asLibraryExercise))
        NavigationStack(path: $path) {
            if let summary {
                FinishSummaryView(session: session, summary: summary, catalog: catalog) { dismiss() }
            } else {
                liveList(catalog: catalog)
                    .exercisePageDestination()
                    .opensExercisePages(on: $path)
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

                let ordered = session.orderedExercises
                VStack(spacing: 12) {
                    ForEach(ordered, id: \.stableID) { exercise in
                        let index = ordered.firstIndex { $0 === exercise } ?? 0
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
                                      history: finishedSessions)
                    }
                    .reorderableIfAvailable()
                }
                .reordersExercises(of: session) { try? modelContext.save() }

                Button {
                    isPicking = true
                } label: {
                    Label("Add Exercises", systemImage: "plus")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                }
                .buttonStyle(.glass)
                .accessibilityIdentifier("live.addExercises")

                Button("Discard Workout", role: .destructive) { isConfirmingDiscard = true }
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .accessibilityIdentifier("live.discard")
            }
            .padding(16)
        }
        .swipeActionsContainerIfAvailable()
        .blockScreenBackground()
        .scrollDismissesKeyboard(.interactively)
        .keyboardDoneButton()
        .revealsFocusedFields()
        .safeAreaInset(edge: .bottom) {
            if session.restEndsAt != nil {
                RestTimerBar(session: session,
                             exerciseName: session.restExerciseID.map { catalog.name(for: $0) })
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.snappy, value: session.restEndsAt == nil)
        .keepsScreenOn(keepScreenOn)
        // Sets checked, rest started or skipped here show in the Live Activity.
        .onChange(of: WorkoutActivitySnapshot(session)) {
            WorkoutLiveActivity.sync(session, in: modelContext)
        }
        .task(id: session.restEndsAt) {
            await RestAlerts.run(for: session, exerciseName: session.restExerciseID.map { catalog.name(for: $0) },
                                 sound: restSound)
        }
        .navigationTitle(session.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            // A view, not `navigationSubtitle`, so the timer keeps ticking. A
            // timer-style Text updates on its own without re-rendering views,
            // so open menus and focused fields aren't disturbed.
            ToolbarItem(placement: .subtitle) {
                Text(session.startedAt, style: .timer)
                    .monospacedDigit()
                    .accessibilityIdentifier("live.elapsed")
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
            ToolbarSpacer(.fixed, placement: .topBarTrailing)
            ToolbarItem(placement: .confirmationAction) {
                Button { finish(catalog: catalog) } label: {
                    // Set on the text: toolbars ignore the button's own label color.
                    Text("Finish").foregroundStyle(Color.accentForeground)
                }
                .prominentGlassButton()
                .accessibilityIdentifier("live.finish")
            }
            // Finish never moves into the overflow menu when space is tight.
            .keepsVisibleIfAvailable()
        }
        .sheet(isPresented: $isEditingNote) {
            WorkoutNoteSheet(session: session)
        }
        .sheet(item: $machinePick) { target in
            let exercise = target.exercise
            MachinePickerSheet(exerciseID: exercise.exerciseID, exerciseName: catalog.name(for: exercise.exerciseID),
                               type: catalog.exercise(id: exercise.exerciseID)?.type ?? .weightAndReps,
                               selected: exercise.machineID, history: finishedSessions) { id in
                exercise.machineID = id
                exercise.machineConfirmed = true
                try? modelContext.save()
            }
        }
        .sheet(isPresented: $isPicking, onDismiss: {
            // Ask which machine only after the exercise picker has closed.
            machinePick = pendingMachinePick.map(MachinePickTarget.init)
            pendingMachinePick = nil
        }) {
            ExercisePickerView(catalog: catalog) { ids in
                // Exercises with machines start on the one used last; the
                // first of them asks which machine it is.
                pendingMachinePick = session.addExercises(ids, machines: allMachines, history: finishedSessions)
                try? modelContext.save()
            }
        }
        .alert("Discard this workout?", isPresented: $isConfirmingDiscard) {
            Button("Discard Workout", role: .destructive) {
                RestAlerts.cancel()
                onDiscard()
            }
                .accessibilityIdentifier("live.confirmDiscard")
            Button("Cancel", role: .cancel) {}
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
}
