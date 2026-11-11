import SwiftUI

/// The machine an exercise is on, under its name; tap to change it. A machine
/// picked automatically is shown dashed with a "?" until it's confirmed.
struct MachineChip: View {
    let name: String?
    let isConfirmed: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Image(systemName: "gearshape.2")
                    .font(.caption)
                    .accessibilityHidden(true)
                Text(label)
                    .font(.footnote.weight(.semibold))
                    // Wraps rather than "Flat bench…", which hid which bench.
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
                Image(systemName: "chevron.down")
                    .font(.caption2.weight(.bold))
                    .accessibilityHidden(true)
            }
            .foregroundStyle(Color.primary)
            .padding(.horizontal, 10)
            .frame(minHeight: 30)
            .background(.fill.tertiary, in: Capsule())
            .overlay {
                if !isConfirmed {
                    Capsule().strokeBorder(Color.accentColor, style: StrokeStyle(lineWidth: 1.5, dash: [4, 3]))
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Machine: \(label)")
        .accessibilityHint("Changes the machine")
    }

    private var label: String {
        guard let name else { return "No specific machine" }
        return isConfirmed ? name : "\(name)?"
    }
}
