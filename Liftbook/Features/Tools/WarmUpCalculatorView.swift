import SwiftUI

/// Type a working weight and get warm-up sets that ramp up to it.
struct WarmUpCalculatorView: View {
    @AppStorage(WeightUnit.storageKey) private var unit: WeightUnit = .kilograms
    @State private var workingText = ""

    var body: some View {
        let plates = PlateCalculator.savedPlates(for: unit, in: AppSettings.store)
        let bar = PlateCalculator.savedBar(for: unit, in: AppSettings.store)
        Form {
            Section {
                HStack {
                    TextField("Working weight", text: $workingText)
                        .keyboardType(.decimalPad)
                        .font(.title2.weight(.semibold))
                        .monospacedDigit()
                        .accessibilityIdentifier("warmup.working")
                    Text(unit.symbol).foregroundStyle(.secondary)
                }
            } footer: {
                Text("Uses the \(format(bar)) \(unit.symbol) bar and the plates set in the plate calculator.")
            }

            if let working = SetInput.decimal(workingText) {
                let steps = WarmUpCalculator.steps(working: working, bar: bar, smallestPlate: plates.min() ?? 1.25)
                Section("Warm-up Sets") {
                    if steps.isEmpty {
                        Text("No warm-up needed at or below the empty bar.")
                            .foregroundStyle(.secondary)
                    }
                    ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                        LabeledContent {
                            Text(step.percent == 0 ? "Empty bar" : "\(Int((step.percent * 100).rounded()))%")
                        } label: {
                            Text("\(format(step.weight)) \(unit.symbol) × \(step.reps)")
                                .monospacedDigit()
                        }
                        .accessibilityElement(children: .combine)
                        .accessibilityIdentifier("warmup.step.\(index)")
                    }
                    if !steps.isEmpty {
                        LabeledContent("Then \(format(working)) \(unit.symbol)", value: "Working sets")
                            .fontWeight(.semibold)
                    }
                }
            }
        }
        .navigationTitle("Warm-up Calculator")
        .navigationBarTitleDisplayMode(.inline)
        .scrollDismissesKeyboard(.interactively)
        .keyboardDoneButton()
    }

    private func format(_ value: Double) -> String {
        value.formatted(.number.precision(.fractionLength(0...2)).grouping(.never))
    }
}
