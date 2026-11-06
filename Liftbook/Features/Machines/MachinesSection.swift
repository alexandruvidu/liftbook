import SwiftData
import SwiftUI

/// An exercise's machines on its detail page: add, rename, re-photograph, delete.
struct MachinesSection: View {
    let exerciseID: String
    @Query(sort: \Machine.createdAt) private var allMachines: [Machine]
    @State private var editing: Machine?
    @State private var isAdding = false

    var body: some View {
        let machines = allMachines.of(exerciseID)
        BlockSection("Machines", footer: "Doing this on more than one machine? Add each one, and last time's weights follow the machine you pick.") {
            ForEach(machines) { machine in
                Button {
                    editing = machine
                } label: {
                    HStack(spacing: 12) {
                        MachinePhoto(machine: machine)
                            .frame(width: 48, height: 48)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(machine.name)
                                .foregroundStyle(Color.primary)
                            if !machine.location.isEmpty {
                                Text(machine.location)
                                    .font(.caption)
                                    .foregroundStyle(Color.secondary)
                            }
                        }
                    }
                }
                .accessibilityIdentifier("exercise.machine.\(machine.name)")
            }
            Button("Add Machine", systemImage: "plus") { isAdding = true }
                .accessibilityIdentifier("exercise.machines.add")
        }
        .sheet(item: $editing) { machine in
            MachineEditorView(exerciseID: exerciseID, machine: machine)
        }
        .sheet(isPresented: $isAdding) {
            MachineEditorView(exerciseID: exerciseID)
        }
    }
}
