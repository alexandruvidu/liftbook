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

    @AppStorage(RestTimer.defaultSecondsKey) private var defaultRest = RestTimer.fallbackSeconds

    private var type: ExerciseType { info?.type ?? .weightAndReps }

    var body: some View {
        Section {
            SetHeaderRow(type: type)
            let labels = exercise.setLabels
            ForEach(Array(exercise.orderedSets.enumerated()), id: \.element.id) { index, set in
                SetRow(set: set, number: index + 1, label: labels[index], type: type,
                       identifier: "\(identifier).set.\(index)", previous: previous?.set(at: index)) {
                    guard let session = exercise.session else { return }
                    session.startRest(seconds: session.restSeconds(after: exercise, default: defaultRest),
                                      for: exercise.exerciseID)
                }
            }
            .onDelete { offsets in
                let sets = exercise.orderedSets
                for offset in offsets { exercise.removeSet(sets[offset]) }
            }

            HStack {
                Button("Add Set", systemImage: "plus") { exercise.addSet() }
                    .accessibilityIdentifier("\(identifier).addSet")
                Spacer()
                RestSecondsMenu(exercise: exercise, defaultSeconds: defaultRest)
                    .accessibilityIdentifier("\(identifier).rest")
                if let session = exercise.session {
                    ExerciseOptionsMenu(exercise: exercise, session: session)
                        .accessibilityIdentifier("\(identifier).options")
                }
            }
            .buttonStyle(.borderless)
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

/// Superset linking and removing an exercise from the workout.
private struct ExerciseOptionsMenu: View {
    let exercise: WorkoutExercise
    let session: WorkoutSession

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
