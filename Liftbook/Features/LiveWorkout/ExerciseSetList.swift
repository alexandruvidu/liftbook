import SwiftUI

/// An exercise's set rows in the live workout (or a past one being edited),
/// under a column header.
struct ExerciseSetList: View {
    let exercise: WorkoutExercise
    let type: ExerciseType
    /// Prefix for accessibility identifiers, e.g. "live.exercise.0".
    let identifier: String
    var previous: PreviousPerformance?
    /// False when editing a finished workout: checking a set starts no timer.
    var startsRest = true
    let defaultRest: Int

    var body: some View {
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
                // Swipe left to delete (iOS 27, in the screen's swipe container);
                // the set number's menu offers the same everywhere. A lone set stays.
                .swipeToDelete("Delete Set", isEnabled: exercise.sets.count > 1,
                               identifier: "\(identifier).set.\(index).delete") {
                    exercise.removeSet(set)
                }
            }
        }
    }
}

/// An exercise's note, hinting at last time's note while empty.
struct ExerciseNoteField: View {
    let exercise: WorkoutExercise
    let previousNote: String?
    let identifier: String

    var body: some View {
        TextField(previousNote.map { "Last note: \($0)" } ?? "Exercise note",
                  text: Bindable(exercise).notes, axis: .vertical)
            .font(.subheadline)
            .lineLimit(1...4)
            .padding(10)
            .background(.fill.tertiary, in: .card(minimum: 10))
            .accessibilityIdentifier("\(identifier).notes")
    }
}

extension WorkoutExercise {
    /// "2 / 4 sets": how many sets are checked off.
    var setProgress: String {
        let done = sets.filter(\.isCompleted).count
        let total = sets.count
        return "\(done) / \(total) \(total == 1 ? "set" : "sets")"
    }
}
