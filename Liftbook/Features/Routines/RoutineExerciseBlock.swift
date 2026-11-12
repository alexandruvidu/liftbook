import SwiftUI

/// An exercise in the routine editor, shaped like its block in a workout:
/// the header and menu, the machine, then one row per planned set with
/// what was done last time, and Add Set.
struct RoutineExerciseBlock: View {
    @Binding var entry: RoutineDraft.Entry
    let info: LibraryExercise?
    let name: String
    /// This exercise's machines.
    let machines: [Machine]
    /// Finished workouts, for last time's sets.
    let history: [WorkoutSession]
    /// Prefix for accessibility identifiers, e.g. "routine.entry.0".
    let identifier: String
    let canMoveUp: Bool
    let canMoveDown: Bool
    /// Moves the block up (-1) or down (+1).
    let move: (Int) -> Void
    let remove: () -> Void

    @AppStorage(WeightUnit.storageKey) private var unit: WeightUnit = .kilograms

    private var type: ExerciseType { info?.type ?? .weightAndReps }

    var body: some View {
        // With machines, last time is that machine's (or any, for "last used").
        let previous = PreviousPerformance.find(exerciseID: entry.exerciseID,
                                                machine: entry.machineID.map { MachineFilter($0) } ?? .all,
                                                in: history)
        Block {
            HStack(spacing: 12) {
                ExerciseHeaderLink(exerciseID: entry.exerciseID, name: name,
                                   subtitle: entry.setCount == 1 ? "1 set" : "\(entry.setCount) sets",
                                   equipment: info?.equipment ?? .other,
                                   machinePhoto: machines.first { $0.machineID == entry.machineID }?.photoFileName,
                                   identifier: "\(identifier).page")
                optionsMenu
            }
            if !machines.isEmpty { machineMenu }
            setHeader
            ForEach(0..<entry.setCount, id: \.self) { index in
                setRow(index: index, last: previous?.workingSets[safe: index])
                    .swipeToDelete("Delete Set", isEnabled: entry.setCount > 1,
                                   identifier: "\(identifier).set.\(index).delete") {
                        entry.setCount -= 1
                    }
            }
            Button {
                withAnimation(.snappy) { entry.setCount += 1 }
            } label: {
                Label("Add Set", systemImage: "plus")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.glass)
            .disabled(entry.setCount >= RoutineDraft.setCountRange.upperBound)
            .accessibilityIdentifier("\(identifier).addSet")
        }
    }

    private var optionsMenu: some View {
        Menu {
            Button("Move Up", systemImage: "arrow.up") { move(-1) }
                .disabled(!canMoveUp)
            Button("Move Down", systemImage: "arrow.down") { move(1) }
                .disabled(!canMoveDown)
            Button("Remove Exercise", systemImage: "trash", role: .destructive, action: remove)
        } label: {
            Image(systemName: "ellipsis")
                .font(.headline)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .accessibilityLabel("Exercise options")
        .accessibilityIdentifier("\(identifier).options")
    }

    private var machineMenu: some View {
        Menu {
            Picker("Machine", selection: $entry.machineID) {
                Text("Last used").tag(UUID?.none)
                ForEach(machines) { Text($0.name).tag(Optional($0.machineID)) }
            }
        } label: {
            Label(machines.name(for: entry.machineID) ?? "Last used machine", systemImage: "gearshape.2")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Color.primary)
                .padding(.horizontal, 10)
                .frame(minHeight: 30)
                .background(.fill.tertiary, in: Capsule())
        }
        .accessibilityLabel("Machine: \(machines.name(for: entry.machineID) ?? "last used")")
        .accessibilityIdentifier("\(identifier).machine")
    }

    private var setHeader: some View {
        HStack(spacing: 8) {
            Text("Set").frame(width: 28)
            Text("Last time").frame(maxWidth: .infinity, alignment: .leading)
        }
        .font(.caption.weight(.semibold))
        .foregroundStyle(.secondary)
        .textCase(.uppercase)
        .accessibilityHidden(true)
    }

    private func setRow(index: Int, last: SetMeasurement?) -> some View {
        HStack(spacing: 8) {
            Text("\(index + 1)")
                .font(.subheadline.weight(.bold))
                .monospacedDigit()
                .foregroundStyle(.secondary)
                .frame(width: 28)
            Text(last.map { $0.formatted(for: type, unit: unit) } ?? "–")
                .monospacedDigit()
                .foregroundStyle(last == nil ? .tertiary : .secondary)
                .frame(maxWidth: .infinity, minHeight: 36, alignment: .leading)
                .padding(.horizontal, 10)
                .background(.fill.tertiary, in: .card(minimum: 8))
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(last.map { "Set \(index + 1). Last time: \($0.formatted(for: type, unit: unit))" }
                            ?? "Set \(index + 1)")
        .accessibilityIdentifier("\(identifier).set.\(index)")
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
