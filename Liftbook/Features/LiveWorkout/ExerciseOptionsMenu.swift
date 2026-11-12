import SwiftData
import SwiftUI

extension Equipment {
    /// A symbol standing in for the exercise until it has a picture.
    var symbolName: String {
        switch self {
        case .none: "figure.strengthtraining.functional"
        case .barbell, .ezBar, .trapBar, .smithMachine: "figure.strengthtraining.traditional"
        case .dumbbell, .kettlebell, .plate: "dumbbell.fill"
        case .machine, .cable: "gearshape.2.fill"
        case .band: "figure.flexibility"
        case .medicineBall: "basketball.fill"
        case .cardioMachine: "figure.run"
        case .other: "figure.mixed.cardio"
        }
    }
}

/// Superset linking, the plate calculator, and removing an exercise.
struct ExerciseOptionsMenu: View {
    let exercise: WorkoutExercise
    let session: WorkoutSession
    let showsPlates: Bool
    let onSwap: (() -> Void)?
    /// Opens the exercise's page; nil for exercises no longer in the library.
    var onViewExercise: (() -> Void)?
    /// Offered for exercises that have no machines yet.
    var onAddMachine: (() -> Void)?
    let onShowPlates: () -> Void
    @AppStorage(WeightUnit.storageKey) private var unit: WeightUnit = .kilograms
    @Environment(\.modelContext) private var modelContext
    @State private var isConfirmingRemove = false

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
            if let onViewExercise {
                Button("View Exercise", systemImage: "info.circle", action: onViewExercise)
            }
            if session.isLinkedToNext(exercise) {
                Button("Unlink from Next Exercise", systemImage: "scissors") {
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
            if let onAddMachine {
                Button("Add Machine", systemImage: "gearshape.2", action: onAddMachine)
            }
            if showsPlates {
                Button("Add Warm-up Sets", systemImage: "flame") { addWarmUps() }
                    .disabled(exercise.workingWeight == nil)
                Button("Plate Calculator", systemImage: "scalemass", action: onShowPlates)
            }
            Button("Remove Exercise", systemImage: "trash", role: .destructive) {
                // Sets already done are lost with it: ask first.
                if exercise.sets.contains(where: \.isCompleted) {
                    isConfirmingRemove = true
                } else {
                    session.removeExercise(exercise)
                }
            }
        } label: {
            Image(systemName: "ellipsis")
                .font(.headline)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .accessibilityLabel("Exercise options")
        .confirmationDialog("Remove this exercise?", isPresented: $isConfirmingRemove, titleVisibility: .visible) {
            Button("Remove Exercise", role: .destructive) { session.removeExercise(exercise) }
                .accessibilityIdentifier("options.confirmRemove")
        } message: {
            Text("The sets you've checked off for it will be deleted.")
        }
    }
}
