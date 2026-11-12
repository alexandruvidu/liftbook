import SwiftData
import SwiftUI

/// An exercise in the live workout (or in a past workout being edited): a
/// header with the name and menu, then its sets. Collapses to the header.
struct ExerciseBlock: View {
    @Environment(\.dynamicTypeSize) private var typeSize
    let exercise: WorkoutExercise
    let info: LibraryExercise?
    let fallbackName: String
    /// Prefix for accessibility identifiers, e.g. "live.exercise.0".
    let identifier: String
    /// What was done for this exercise last time.
    var previous: PreviousPerformance?
    /// The note written for this exercise last time, shown as a hint.
    var previousNote: String?
    /// False when editing a finished workout: checking a set starts no timer.
    var startsRest = true
    @Binding var isCollapsed: Bool
    /// This exercise's machines.
    var machines: [Machine] = []
    /// Finished workouts, for each machine's last sets in the picker.
    var history: [WorkoutSession] = []

    @AppStorage(RestTimer.defaultSecondsKey) private var defaultRest = RestTimer.fallbackSeconds
    @Environment(\.modelContext) private var modelContext
    @Environment(\.openExercisePage) private var openExercisePage
    @State private var isShowingPlates = false
    @State private var isSwapping = false
    @State private var isNoteOpen = false
    @State private var isPickingMachine = false
    @State private var isAddingMachine = false
    @Query private var customExercises: [CustomExercise]

    private var type: ExerciseType { info?.type ?? .weightAndReps }

    var body: some View {
        Block {
            header
            if !isCollapsed {
                pills
                if showsNote { ExerciseNoteField(exercise: exercise, previousNote: previousNote, identifier: identifier) }
                if startsRest, let info, let last = previous?.workingSets, !last.isEmpty {
                    ProgressionRow(exercise: exercise, info: info, lastWorkingSets: last, identifier: identifier)
                }
                ExerciseSetList(exercise: exercise, type: type, identifier: identifier, previous: previous,
                                startsRest: startsRest, defaultRest: defaultRest)
                Button {
                    exercise.addSet()
                    try? modelContext.save()
                } label: {
                    Label("Add Set", systemImage: "plus")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.glass)
                .accessibilityIdentifier("\(identifier).addSet")
            }
        }
        .sheet(isPresented: $isPickingMachine) {
            MachinePickerSheet(exerciseID: exercise.exerciseID, exerciseName: info?.name ?? fallbackName, type: type,
                               selected: exercise.machineID, history: history) { id in
                exercise.machineID = id
                exercise.machineConfirmed = true
                try? modelContext.save()
            }
        }
        .sheet(isPresented: $isAddingMachine) {
            MachineEditorView(exerciseID: exercise.exerciseID) { machine in
                exercise.machineID = machine.machineID
                exercise.machineConfirmed = true
            }
        }
        .sheet(isPresented: $isSwapping) {
            if let info {
                SwapExerciseView(current: info, catalog: ExerciseCatalog(custom: customExercises.map(\.asLibraryExercise))) {
                    exercise.swap(to: $0)
                    try? modelContext.save()
                }
            }
        }
        .sheet(isPresented: $isShowingPlates) {
            PlatesSheet(initialKilograms: exercise.orderedSets.last(where: { ($0.weight ?? 0) > 0 })?.weight)
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            Button {
                withAnimation(.snappy) { isCollapsed.toggle() }
            } label: {
                HStack(spacing: 12) {
                    ExerciseThumbnail(exerciseID: exercise.exerciseID, equipment: info?.equipment ?? .other,
                                      machinePhoto: machines.first { $0.machineID == exercise.machineID }?.photoFileName)
                    VStack(alignment: .leading, spacing: 2) {
                        if let letter = exercise.session?.supersetLetter(for: exercise) {
                            Label("Superset \(letter)", systemImage: "link")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(.tint)
                                .accessibilityIdentifier("\(identifier).superset")
                        }
                        Text(info?.name ?? fallbackName)
                            .font(.headline)
                            .foregroundStyle(.tint)
                            .multilineTextAlignment(.leading)
                        Text(exercise.setProgress)
                            .font(.subheadline)
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                            .accessibilityIdentifier("\(identifier).progress")
                    }
                    Spacer(minLength: 4)
                    Image(systemName: "chevron.down")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .rotationEffect(.degrees(isCollapsed ? -90 : 0))
                        .accessibilityHidden(true)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityHint(isCollapsed ? "Shows the sets" : "Hides the sets")
            .accessibilityIdentifier("\(identifier).collapse")

            if let session = exercise.session {
                ExerciseOptionsMenu(exercise: exercise, session: session,
                                    showsPlates: type == .weightAndReps,
                                    onSwap: info == nil ? nil : { isSwapping = true },
                                    onViewExercise: info == nil || openExercisePage == nil ? nil : { openExercisePage?(exercise.exerciseID) },
                                    onAddMachine: machines.isEmpty && startsRest ? { isAddingMachine = true } : nil) {
                    isShowingPlates = true
                }
                    .accessibilityIdentifier("\(identifier).options")
            }
        }
    }

    /// The machine, rest and note pills: on one row when they fit, else the
    /// machine (whose name may be long) on its own row above the other two.
    @ViewBuilder
    private var pills: some View {
        // Stacked at accessibility sizes: side by side, the pills squeezed
        // "Rest 1:30" to a letter per line and widened the whole workout.
        if typeSize.isAccessibilitySize {
            VStack(alignment: .leading, spacing: 8) {
                machinePill
                restAndNotePills
            }
        } else {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 8) {
                    machinePill.fixedSize(horizontal: true, vertical: false)
                    restAndNotePills
                }
                VStack(alignment: .leading, spacing: 8) {
                    machinePill
                    HStack(spacing: 8) { restAndNotePills }
                }
            }
        }
    }

    @ViewBuilder
    private var machinePill: some View {
        if !machines.isEmpty {
            MachineChip(name: machines.name(for: exercise.machineID), isConfirmed: exercise.machineConfirmed) {
                isPickingMachine = true
            }
            .accessibilityIdentifier("\(identifier).machine")
        }
    }

    @ViewBuilder
    private var restAndNotePills: some View {
        if startsRest {
            RestSecondsMenu(exercise: exercise, defaultSeconds: defaultRest)
                .accessibilityIdentifier("\(identifier).rest")
        }
        Button {
            isNoteOpen.toggle()
        } label: {
            Label("Note", systemImage: "square.and.pencil")
                .fixedSize(horizontal: true, vertical: false)
        }
        .buttonStyle(.glass)
        .accessibilityIdentifier("\(identifier).note")
    }

    /// Shown when the note pill is on, or there's a note (now or last time).
    private var showsNote: Bool {
        isNoteOpen || !exercise.notes.isEmpty || previousNote != nil
    }
}
