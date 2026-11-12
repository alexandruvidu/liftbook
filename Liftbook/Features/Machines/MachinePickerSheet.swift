import SwiftData
import SwiftUI

/// Which machine an exercise is being done on: photo cards with what was
/// lifted on each last time, plus adding a new one.
struct MachinePickerSheet: View {
    let exerciseID: String
    let exerciseName: String
    let type: ExerciseType
    let selected: UUID?
    /// Finished workouts, for each machine's last sets.
    let history: [WorkoutSession]
    let onPick: (UUID?) -> Void

    @Query(sort: \Machine.createdAt) private var allMachines: [Machine]
    @AppStorage(WeightUnit.storageKey) private var unit: WeightUnit = .kilograms
    @Environment(\.dismiss) private var dismiss
    @State private var isAdding = false

    var body: some View {
        let machines = allMachines.of(exerciseID)
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                        ForEach(machines) { machine in
                            card(machine)
                        }
                        addCard
                    }
                    Button {
                        pick(nil)
                    } label: {
                        Text("No specific machine")
                            .frame(maxWidth: .infinity, minHeight: 44)
                    }
                    .buttonStyle(.glass)
                    .accessibilityIdentifier("machine.none")
                }
                .padding(16)
            }
            .blockScreenBackground()
            .navigationTitle("Which Machine?")
            .navigationSubtitle(exerciseName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close", systemImage: "xmark") { dismiss() }
                }
            }
            .sheet(isPresented: $isAdding) {
                MachineEditorView(exerciseID: exerciseID) { pick($0.machineID) }
            }
        }
    }

    private func pick(_ id: UUID?) {
        onPick(id)
        dismiss()
    }

    private func card(_ machine: Machine) -> some View {
        let isSelected = machine.machineID == selected
        let last = PreviousPerformance.find(exerciseID: exerciseID, machine: .machine(machine.machineID), in: history)
        return Button {
            pick(machine.machineID)
        } label: {
            VStack(alignment: .leading, spacing: 0) {
                MachinePhoto(machine: machine)
                    .frame(height: 110)
                    .overlay(alignment: .topTrailing) {
                        if isSelected {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.title2)
                                .symbolRenderingMode(.palette)
                                .foregroundStyle(Color.accentForeground, Color.accentColor)
                                .padding(8)
                        }
                    }
                VStack(alignment: .leading, spacing: 3) {
                    Text(machine.name)
                        .font(.subheadline.weight(.bold))
                        // Room to wrap: two lines made "Flat bench A" and "B" identical at large sizes.
                        .lineLimit(4)
                    if !machine.location.isEmpty {
                        Text(machine.location)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    if let set = last?.sets.last {
                        Text("Last \(set.formatted(for: type, unit: unit))")
                            .font(.caption.weight(.semibold))
                            .monospacedDigit()
                            .foregroundStyle(.tint)
                        Text(last!.date.formatted(.relative(presentation: .named)))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("Not used yet")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .foregroundStyle(Color.primary)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(.card(minimum: 16))
            .overlay(ConcentricRectangle.card(minimum: 16).stroke(isSelected ? Color.accentColor : .clear, lineWidth: 2))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityIdentifier("machine.card.\(machine.name)")
    }

    private var addCard: some View {
        Button {
            isAdding = true
        } label: {
            VStack(spacing: 8) {
                Image(systemName: "camera")
                    .font(.title2)
                Text("Add machine")
                    .font(.subheadline.weight(.semibold))
                Text("Name and photo")
                    .font(.caption)
                    // Plain gray: `.secondary` inside a button is a dim shade of the tint.
                    .foregroundStyle(Color.secondary)
            }
            .frame(maxWidth: .infinity, minHeight: 190)
            .foregroundStyle(.tint)
            .overlay(ConcentricRectangle.card(minimum: 16).stroke(.tertiary, style: StrokeStyle(lineWidth: 2, dash: [6, 5])))
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("machine.add")
    }
}

/// A machine's photo, or a placeholder symbol.
struct MachinePhoto: View {
    let machine: Machine

    var body: some View {
        Color(.tertiarySystemFill)
            .overlay {
                if let file = machine.photoFileName, let image = PhotoStore.machines.load(file) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                } else {
                    Image(systemName: "gearshape.2.fill")
                        .font(.title)
                        .foregroundStyle(.secondary)
                }
            }
            .clipped()
            .accessibilityHidden(true)
    }
}

/// An exercise whose machine is being chosen, keyed by the object itself (its
/// SwiftData ID can change on the first save).
struct MachinePickTarget: Identifiable {
    let exercise: WorkoutExercise
    var id: ObjectIdentifier { exercise.stableID }
}
