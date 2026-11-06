import SwiftUI

/// Shows the set's number or kind tag; tapping it changes the kind.
struct SetKindMenu: View {
    let set: WorkoutSet
    let label: String
    /// Removes the set; nil hides the option.
    var onRemove: (() -> Void)?

    var body: some View {
        Menu {
            Section("Set Type") {
                ForEach(SetKind.allCases) { kind in
                    Button {
                        set.kind = kind
                    } label: {
                        if set.kind == kind {
                            Label(kind.displayName, systemImage: "checkmark")
                        } else {
                            Text(kind.displayName)
                        }
                    }
                }
            }
            if let onRemove {
                Button("Remove Set", systemImage: "trash", role: .destructive, action: onRemove)
            }
        } label: {
            Text(label)
                .font(.subheadline.weight(.bold))
                .monospacedDigit()
                .foregroundStyle(set.kind == .normal ? AnyShapeStyle(.secondary) : AnyShapeStyle(.primary))
                .frame(width: 28, height: 32)
                .background(set.kind.tint.opacity(set.kind == .normal ? 0 : 0.28),
                            in: RoundedRectangle(cornerRadius: 7))
        }
        // Menus tint their label with the accent color; keep the tag readable.
        .tint(set.kind == .normal ? Color.secondary : Color.primary)
        .accessibilityLabel("\(set.kind.displayName): \(label)")
    }
}

extension SetKind {
    /// Background tint for the set's tag.
    var tint: Color {
        switch self {
        case .normal: .clear
        case .warmUp: .orange
        case .drop: .indigo
        case .failure: .red
        }
    }
}

/// Picks the set's rate of perceived exertion.
struct RPEMenu: View {
    let set: WorkoutSet

    var body: some View {
        Menu {
            Button("No RPE") { set.rpe = nil }
            ForEach(SetInput.rpeOptions.reversed(), id: \.self) { value in
                Button("RPE \(SetMeasurement.decimal(value))") { set.rpe = value }
            }
        } label: {
            Text(set.rpe.map(SetMeasurement.decimal) ?? "–")
                .monospacedDigit()
                .frame(maxWidth: .infinity, minHeight: 34)
                .background(.fill.tertiary, in: RoundedRectangle(cornerRadius: 8))
        }
        .accessibilityLabel(set.rpe.map { "RPE \(SetMeasurement.decimal($0))" } ?? "RPE not set")
    }
}
