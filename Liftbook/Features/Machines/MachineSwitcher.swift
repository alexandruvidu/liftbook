import SwiftUI

/// Pills to choose whose charts and records to show: all machines combined,
/// one machine, or the sets logged without a machine.
struct MachineSwitcher: View {
    let machines: [Machine]
    /// Whether any sets were logged without a machine.
    let hasUnassigned: Bool
    @Binding var selection: MachineFilter

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                pill("All machines", filter: .all)
                ForEach(machines) { machine in
                    pill(machine.name, filter: .machine(machine.machineID))
                }
                if hasUnassigned {
                    pill("No machine", filter: .none)
                }
            }
            .padding(.horizontal, 20)
        }
    }

    private func pill(_ title: String, filter: MachineFilter) -> some View {
        let isSelected = selection == filter
        return Button(title) { selection = filter }
            .buttonStyle(PillButtonStyle(prominent: isSelected))
            .accessibilityAddTraits(isSelected ? .isSelected : [])
            .accessibilityIdentifier("machineSwitcher.\(title)")
    }
}
