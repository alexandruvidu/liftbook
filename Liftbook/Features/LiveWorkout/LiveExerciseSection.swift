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

    private var type: ExerciseType { info?.type ?? .weightAndReps }

    var body: some View {
        Section {
            SetHeaderRow(type: type)
            let labels = exercise.setLabels
            ForEach(Array(exercise.orderedSets.enumerated()), id: \.element.id) { index, set in
                SetRow(set: set, number: index + 1, label: labels[index], type: type,
                       identifier: "\(identifier).set.\(index)", previous: previous?.set(at: index))
            }
            .onDelete { offsets in
                let sets = exercise.orderedSets
                for offset in offsets { exercise.removeSet(sets[offset]) }
            }

            Button("Add Set", systemImage: "plus") { exercise.addSet() }
                .accessibilityIdentifier("\(identifier).addSet")
        } header: {
            HStack {
                Text(info?.name ?? fallbackName)
                Spacer()
                Text(progressText)
                    .monospacedDigit()
                    .accessibilityIdentifier("\(identifier).progress")
            }
        }
    }

    private var progressText: String {
        let done = exercise.sets.filter(\.isCompleted).count
        return "\(done)/\(exercise.sets.count) done"
    }
}
