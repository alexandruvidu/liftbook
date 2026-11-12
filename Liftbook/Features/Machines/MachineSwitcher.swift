import SwiftUI

/// Chooses whose charts and records to show: all machines combined, one
/// machine, or the sets logged without a machine. A segmented control when
/// the options fit, otherwise a row of buttons that scrolls.
struct MachineSwitcher: View {
    let machines: [Machine]
    /// Whether any sets were logged without a machine.
    let hasUnassigned: Bool
    @Binding var selection: MachineFilter

    private var options: [(title: String, filter: MachineFilter)] {
        [("All machines", .all)]
            + machines.map { ($0.name, .machine($0.machineID)) }
            + (hasUnassigned ? [("No machine", .none)] : [])
    }

    var body: some View {
        if options.count <= 4 {
            Picker("Machine", selection: $selection) {
                ForEach(options, id: \.filter) { option in
                    Text(option.title).tag(option.filter)
                }
            }
            .pickerStyle(.segmented)
            .accessibilityIdentifier("machineSwitcher")
        } else {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(options, id: \.filter) { option in
                        button(option.title, filter: option.filter)
                    }
                }
            }
            .scrollClipDisabled()
        }
    }

    @ViewBuilder
    private func button(_ title: String, filter: MachineFilter) -> some View {
        let isSelected = selection == filter
        let button = Button(title) { selection = filter }
            .controlSize(.small)
            .accessibilityAddTraits(isSelected ? .isSelected : [])
            .accessibilityIdentifier("machineSwitcher.\(title)")
        if isSelected {
            button.prominentGlassButton()
        } else {
            button.buttonStyle(.glass)
        }
    }
}
