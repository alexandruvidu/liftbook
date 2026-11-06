import SwiftData
import SwiftUI

/// A finished workout: totals, notes and every set. Edit, repeat or delete it.
struct WorkoutDetailView: View {
    let session: WorkoutSession
    let catalog: ExerciseCatalog
    let onRepeat: () -> Void

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @AppStorage(WeightUnit.storageKey) private var unit: WeightUnit = .kilograms
    @Query private var machines: [Machine]
    @State private var isEditing = false
    @State private var isConfirmingDelete = false

    var body: some View {
        let summary = WorkoutSummary(session: session, history: []) { type(of: $0) }
        List {
            Section {
                HStack(spacing: 12) {
                    StatTile(title: "Duration", value: SetMeasurement.clock(summary.duration), identifier: "detail.duration")
                    StatTile(title: "Volume", value: unit.volumeText(kilograms: summary.volume), identifier: "detail.volume")
                    StatTile(title: "Sets", value: "\(summary.setCount)", identifier: "detail.sets")
                }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            } header: {
                Text(session.startedAt.formatted(date: .complete, time: .shortened))
            }

            if !session.notes.isEmpty {
                Section("Notes") {
                    Text(session.notes)
                        .accessibilityIdentifier("detail.notes")
                }
            }

            ForEach(Array(session.orderedExercises.enumerated()), id: \.element.stableID) { index, exercise in
                exerciseSection(exercise, index: index)
            }

            Section {
                Button("Repeat Workout", systemImage: "arrow.clockwise", action: onRepeat)
                    .accessibilityIdentifier("detail.repeat")
                Button("Delete Workout", systemImage: "trash", role: .destructive) { isConfirmingDelete = true }
                    .accessibilityIdentifier("detail.delete")
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(session.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            Button("Edit") { isEditing = true }
                .accessibilityIdentifier("detail.edit")
        }
        .sheet(isPresented: $isEditing) {
            EditWorkoutView(session: session, catalog: catalog)
        }
        .confirmationDialog("Delete this workout?", isPresented: $isConfirmingDelete, titleVisibility: .visible) {
            Button("Delete Workout", role: .destructive) {
                // Leave the page first; deleting the model while it's still
                // on screen would make the view read a deleted object.
                dismiss()
                let context = modelContext, session = session
                Task { @MainActor in
                    try? await Task.sleep(for: WorkoutStartController.transitionDelay)
                    context.delete(session)
                    try? context.save()
                }
            }
            .accessibilityIdentifier("detail.confirmDelete")
        } message: {
            Text("It will be removed from your history and records.")
        }
    }

    private func type(of exerciseID: String) -> ExerciseType {
        catalog.exercise(id: exerciseID)?.type ?? .weightAndReps
    }

    private func exerciseSection(_ exercise: WorkoutExercise, index: Int) -> some View {
        let type = type(of: exercise.exerciseID)
        let labels = exercise.setLabels
        return Section {
            if !exercise.notes.isEmpty {
                Text(exercise.notes)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            ForEach(Array(exercise.orderedSets.enumerated()), id: \.element.stableID) { setIndex, set in
                HStack {
                    Text(labels[setIndex])
                        .font(.subheadline.weight(.semibold))
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                        .frame(width: 26)
                    Text(set.measurement.formatted(for: type, unit: unit))
                        .monospacedDigit()
                    if let rpe = set.rpe {
                        Text("RPE \(SetMeasurement.decimal(rpe))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    if !set.isCompleted {
                        Text("Skipped")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .opacity(set.isCompleted ? 1 : 0.6)
                .accessibilityElement(children: .combine)
                .accessibilityIdentifier("detail.exercise.\(index).set.\(setIndex)")
            }
        } header: {
            HStack {
                Text(exercise.displayName(catalog: catalog, machines: machines))
                if let letter = session.supersetLetter(for: exercise) {
                    Text("· Superset \(letter)")
                }
            }
        }
    }
}
