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
                if showsNote { noteField }
                if startsRest, let info, let last = previous?.workingSets, !last.isEmpty {
                    ProgressionRow(exercise: exercise, info: info, lastWorkingSets: last, identifier: identifier)
                }
                sets
                Button {
                    exercise.addSet()
                    try? modelContext.save()
                } label: {
                    Label("Add Set", systemImage: "plus")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.pill)
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
            NavigationStack {
                PlateCalculatorView(initialKilograms: exercise.orderedSets.last(where: { ($0.weight ?? 0) > 0 })?.weight)
                    .toolbar {
                        Button("Done") { isShowingPlates = false }
                            .accessibilityIdentifier("plates.done")
                    }
            }
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
                        Text(progressText)
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
                                    onAddMachine: machines.isEmpty && startsRest ? { isAddingMachine = true } : nil) {
                    isShowingPlates = true
                }
                    .accessibilityIdentifier("\(identifier).options")
            }
        }
    }

    private var pills: some View {
        // Stacked at accessibility sizes: side by side, the pills squeezed
        // "Rest 1:30" to a letter per line and widened the whole workout.
        let layout = typeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 8))
            : AnyLayout(HStackLayout(spacing: 8))
        return layout {
            if !machines.isEmpty {
                MachineChip(name: machines.name(for: exercise.machineID), isConfirmed: exercise.machineConfirmed) {
                    isPickingMachine = true
                }
                .accessibilityIdentifier("\(identifier).machine")
            }
            if startsRest {
                RestSecondsMenu(exercise: exercise, defaultSeconds: defaultRest)
                    .accessibilityIdentifier("\(identifier).rest")
            }
            Button {
                isNoteOpen.toggle()
            } label: {
                Label("Note", systemImage: "square.and.pencil")
            }
            .buttonStyle(.pill)
            .accessibilityIdentifier("\(identifier).note")
        }
    }

    /// Shown when the note pill is on, or there's a note (now or last time).
    private var showsNote: Bool {
        isNoteOpen || !exercise.notes.isEmpty || previousNote != nil
    }

    private var noteField: some View {
        TextField(previousNote.map { "Last note: \($0)" } ?? "Exercise note",
                  text: Bindable(exercise).notes, axis: .vertical)
            .font(.subheadline)
            .lineLimit(1...4)
            .padding(10)
            .background(.fill.tertiary, in: RoundedRectangle(cornerRadius: 10))
            .accessibilityIdentifier("\(identifier).notes")
    }

    private var sets: some View {
        VStack(spacing: 6) {
            SetHeaderRow(type: type)
            let labels = exercise.setLabels
            let kinds = exercise.orderedSets.map(\.kind)
            ForEach(Array(exercise.orderedSets.enumerated()), id: \.element.stableID) { index, set in
                SetRow(set: set, number: index + 1, label: labels[index], type: type,
                       identifier: "\(identifier).set.\(index)", previous: previous?.set(at: index, kinds: kinds),
                       onRemove: exercise.sets.count > 1 ? { exercise.removeSet(set) } : nil) {
                    // Checking off a set confirms a guessed machine.
                    exercise.machineConfirmed = true
                    guard startsRest, let session = exercise.session else { return }
                    session.startRest(seconds: session.restSeconds(after: exercise, default: defaultRest),
                                      for: exercise.exerciseID)
                }
            }
        }
    }

    private var progressText: String {
        let done = exercise.sets.filter(\.isCompleted).count
        let total = exercise.sets.count
        return "\(done) / \(total) \(total == 1 ? "set" : "sets")"
    }
}
