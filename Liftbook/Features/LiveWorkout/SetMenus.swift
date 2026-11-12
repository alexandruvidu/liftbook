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

/// The set's rate of perceived exertion; tapping it opens a slider.
struct RPEPicker: View {
    let set: WorkoutSet
    let number: Int
    @State private var isPicking = false

    var body: some View {
        Button {
            isPicking = true
        } label: {
            Text(set.rpe.map { SetMeasurement.decimal($0) } ?? "–")
                .monospacedDigit()
                .frame(maxWidth: .infinity, minHeight: 34)
                .background(.fill.tertiary, in: RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.borderless)
        .accessibilityLabel(set.rpe.map { "RPE \(SetMeasurement.decimal($0))" } ?? "RPE not set")
        .sheet(isPresented: $isPicking) {
            RPESheet(number: number, initial: set.rpe) { set.rpe = $0 }
        }
    }
}

/// A slider from 6 to 10 in half steps, each value explained as reps left.
private struct RPESheet: View {
    let number: Int
    let save: (Double?) -> Void
    @State private var value: Double
    @Environment(\.dismiss) private var dismiss

    init(number: Int, initial: Double?, save: @escaping (Double?) -> Void) {
        self.number = number
        self.save = save
        // Unset sets start in the middle, at a typical working effort.
        _value = State(initialValue: initial ?? 8)
    }

    private var range: ClosedRange<Double> {
        (SetInput.rpeOptions.first ?? 6)...(SetInput.rpeOptions.last ?? 10)
    }

    var body: some View {
        VStack(spacing: 16) {
            Text("How hard was set \(number)?")
                .font(.headline)
            VStack(spacing: 4) {
                Text("RPE \(SetMeasurement.decimal(value))")
                    .font(.system(.largeTitle, design: .rounded).weight(.bold))
                    .monospacedDigit()
                    .contentTransition(.numericText(value: value))
                Text(SetInput.rpeDescription(value))
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .animation(.snappy, value: value)
            .accessibilityElement(children: .combine)

            Slider(value: $value, in: range, step: 0.5) {
                Text("RPE")
            } minimumValueLabel: {
                Text("Easy").font(.caption).foregroundStyle(.secondary)
            } maximumValueLabel: {
                Text("Max").font(.caption).foregroundStyle(.secondary)
            }
            .accessibilityValue("RPE \(SetMeasurement.decimal(value)). \(SetInput.rpeDescription(value))")
            .accessibilityIdentifier("rpe.slider")
            .sensoryFeedback(.selection, trigger: value)

            HStack(spacing: 12) {
                Button {
                    save(nil)
                    dismiss()
                } label: {
                    Text("No RPE").frame(maxWidth: .infinity)
                }
                .buttonStyle(.pill)
                .accessibilityIdentifier("rpe.clear")
                Button {
                    save(value)
                    dismiss()
                } label: {
                    Text("Save").frame(maxWidth: .infinity)
                }
                .buttonStyle(.pillProminent)
                .accessibilityIdentifier("rpe.save")
            }
        }
        .padding(20)
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
}
