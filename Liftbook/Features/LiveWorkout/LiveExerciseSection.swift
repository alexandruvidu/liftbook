import SwiftData
import SwiftUI

/// An exercise in the live workout: its sets and an Add Set button.
struct LiveExerciseSection: View {
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

    @AppStorage(RestTimer.defaultSecondsKey) private var defaultRest = RestTimer.fallbackSeconds
    @Environment(\.modelContext) private var modelContext
    @State private var isShowingPlates = false
    @State private var isSwapping = false
    @Query private var customExercises: [CustomExercise]

    private var type: ExerciseType { info?.type ?? .weightAndReps }

    var body: some View {
        Section {
            TextField(previousNote.map { "Last note: \($0)" } ?? "Exercise note",
                      text: Bindable(exercise).notes, axis: .vertical)
                .font(.subheadline)
                .lineLimit(1...4)
                .accessibilityIdentifier("\(identifier).notes")
            if startsRest, let info, let last = previous?.workingSets, !last.isEmpty {
                ProgressionRow(exercise: exercise, info: info, lastWorkingSets: last, identifier: identifier)
            }
            SetHeaderRow(type: type)
            let labels = exercise.setLabels
            ForEach(Array(exercise.orderedSets.enumerated()), id: \.element.stableID) { index, set in
                SetRow(set: set, number: index + 1, label: labels[index], type: type,
                       identifier: "\(identifier).set.\(index)", previous: previous?.set(at: index)) {
                    guard startsRest, let session = exercise.session else { return }
                    session.startRest(seconds: session.restSeconds(after: exercise, default: defaultRest),
                                      for: exercise.exerciseID)
                }
            }
            .onDelete { offsets in
                let sets = exercise.orderedSets
                for offset in offsets { exercise.removeSet(sets[offset]) }
            }

            HStack {
                Button("Add Set", systemImage: "plus") {
                    exercise.addSet()
                    try? modelContext.save()
                }
                    .accessibilityIdentifier("\(identifier).addSet")
                Spacer()
                if startsRest {
                    RestSecondsMenu(exercise: exercise, defaultSeconds: defaultRest)
                        .accessibilityIdentifier("\(identifier).rest")
                }
                if let session = exercise.session {
                    ExerciseOptionsMenu(exercise: exercise, session: session,
                                        showsPlates: type == .weightAndReps,
                                        onSwap: info == nil ? nil : { isSwapping = true }) { isShowingPlates = true }
                        .accessibilityIdentifier("\(identifier).options")
                }
            }
            .buttonStyle(.borderless)
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
        } header: {
            VStack(alignment: .leading, spacing: 4) {
                if let letter = exercise.session?.supersetLetter(for: exercise) {
                    Label("Superset \(letter)", systemImage: "link")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color.accentColor)
                        .accessibilityIdentifier("\(identifier).superset")
                }
                HStack {
                    Text(info?.name ?? fallbackName)
                    Spacer()
                    Text(progressText)
                        .monospacedDigit()
                        .accessibilityIdentifier("\(identifier).progress")
                }
            }
        }
    }

    private var progressText: String {
        let done = exercise.sets.filter(\.isCompleted).count
        return "\(done)/\(exercise.sets.count) done"
    }
}

/// Superset linking, the plate calculator, and removing an exercise.
private struct ExerciseOptionsMenu: View {
    let exercise: WorkoutExercise
    let session: WorkoutSession
    let showsPlates: Bool
    let onSwap: (() -> Void)?
    let onShowPlates: () -> Void
    @AppStorage(WeightUnit.storageKey) private var unit: WeightUnit = .kilograms
    @Environment(\.modelContext) private var modelContext

    /// Ramps up to the first working set's weight, using the plate settings.
    private func addWarmUps() {
        guard let working = exercise.workingWeight else { return }
        let plates = PlateCalculator.savedPlates(for: unit, in: AppSettings.store)
        let steps = WarmUpCalculator.steps(working: unit.display(kilograms: working),
                                           bar: PlateCalculator.savedBar(for: unit, in: AppSettings.store),
                                           smallestPlate: plates.min() ?? 1.25)
        exercise.setWarmUps(steps.map { (kilograms: unit.kilograms(fromDisplay: $0.weight), reps: $0.reps) })
        try? modelContext.save()
    }

    var body: some View {
        Menu {
            if session.isLinkedToNext(exercise) {
                Button("Unlink from Next Exercise", systemImage: "link.badge.plus") {
                    session.unlinkFromNext(exercise)
                }
            } else if session.exercise(after: exercise) != nil {
                Button("Superset with Next Exercise", systemImage: "link") {
                    session.linkWithNext(exercise)
                }
            }
            if let onSwap {
                Button("Swap Exercise", systemImage: "arrow.triangle.swap", action: onSwap)
            }
            if showsPlates {
                Button("Add Warm-up Sets", systemImage: "flame") { addWarmUps() }
                    .disabled(exercise.workingWeight == nil)
                Button("Plate Calculator", systemImage: "scalemass", action: onShowPlates)
            }
            Button("Remove Exercise", systemImage: "trash", role: .destructive) {
                session.removeExercise(exercise)
            }
        } label: {
            Image(systemName: "ellipsis.circle")
                .font(.title3)
                .frame(minWidth: 32, minHeight: 32)
        }
        .accessibilityLabel("Exercise options")
    }
}
