import SwiftUI

/// Type a target weight and see which plates go on each side of the bar.
/// The bar and the plates you own are remembered per unit.
struct PlateCalculatorView: View {
    /// Prefilled target in kilograms (e.g. from the current set).
    var initialKilograms: Double?

    @AppStorage(WeightUnit.storageKey) private var unit: WeightUnit = .kilograms
    @State private var targetText = ""
    @State private var bar: Double = 20
    @State private var available: [Double] = []
    @State private var loaded = false

    var body: some View {
        let target = SetInput.decimal(targetText)
        Form {
            Section {
                HStack {
                    TextField("Target weight", text: $targetText)
                        .keyboardType(.decimalPad)
                        .font(.title2.weight(.semibold))
                        .monospacedDigit()
                        .accessibilityIdentifier("plates.target")
                    Text(unit.symbol).foregroundStyle(.secondary)
                }
                Picker("Bar", selection: $bar) {
                    ForEach(barOptions, id: \.self) { Text("\(format($0)) \(unit.symbol)").tag($0) }
                }
                .accessibilityIdentifier("plates.bar")
            }

            if let target {
                resultSection(PlateCalculator.plates(for: target, bar: bar, available: available))
            }

            Section {
                ForEach(PlateCalculator.standardPlates(for: unit), id: \.self) { plate in
                    Toggle("\(format(plate)) \(unit.symbol)", isOn: Binding(
                        get: { available.contains(plate) },
                        set: { isOn in
                            available = isOn ? (available + [plate]).sorted(by: >) : available.filter { $0 != plate }
                        }))
                    // Locale-independent ("1.25", not "1,25") so UI tests can find it.
                    .accessibilityIdentifier("plates.toggle.\(String(format: "%g", plate))")
                }
                .tint(Color.accentColor)
            } header: {
                Text("Your Plates")
            } footer: {
                Text("Turn off plates your gym doesn't have. You're assumed to have pairs of each.")
            }
        }
        .navigationTitle("Plate Calculator")
        .navigationBarTitleDisplayMode(.inline)
        .scrollDismissesKeyboard(.interactively)
        .keyboardDoneButton()
        .onAppear(perform: load)
        .onChange(of: bar) { save() }
        .onChange(of: available) { save() }
    }

    private var barOptions: [Double] {
        unit == .kilograms ? PlateCalculator.barOptionsKilograms : PlateCalculator.barOptionsPounds
    }

    @ViewBuilder private func resultSection(_ result: PlateCalculator.Result) -> some View {
        Section("Each Side") {
            if result.belowBar {
                Text("That's lighter than the \(format(bar)) \(unit.symbol) bar.")
                    .foregroundStyle(.secondary)
                    .accessibilityIdentifier("plates.belowBar")
            } else if result.perSide.isEmpty {
                Text("Just the empty bar.")
                    .accessibilityIdentifier("plates.perSide")
            } else {
                BarbellSideView(plates: result.perSide, heaviest: PlateCalculator.standardPlates(for: unit).first ?? 1,
                                format: format)
                    .frame(height: 120)
                    .accessibilityHidden(true)
                // "2 × 20 + 1.25 kg" rather than listing every plate.
                Text(PlateCalculator.grouped(result.perSide)
                    .map { $0.count == 1 ? format($0.plate) : "\($0.count) × \(format($0.plate))" }
                    .joined(separator: " + ") + " \(unit.symbol)")
                    .font(.headline)
                    .monospacedDigit()
                    .accessibilityLabel("Each side: " + result.perSide.map { "\(format($0)) \(unit.symbol)" }.joined(separator: ", "))
                    .accessibilityIdentifier("plates.perSide")
            }
            if result.shortBy > 0 {
                Text("Closest you can load is \(format(result.loaded)) \(unit.symbol), \(format(result.shortBy)) \(unit.symbol) short.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .accessibilityIdentifier("plates.short")
            }
        }
    }

    private func format(_ value: Double) -> String {
        value.formatted(.number.precision(.fractionLength(0...2)).grouping(.never))
    }

    private func load() {
        guard !loaded else { return }
        loaded = true
        bar = PlateCalculator.savedBar(for: unit, in: AppSettings.store)
        available = PlateCalculator.savedPlates(for: unit, in: AppSettings.store)
        if let initialKilograms, targetText.isEmpty {
            targetText = format((unit.display(kilograms: initialKilograms) * 100).rounded() / 100)
        }
    }

    private func save() {
        guard loaded else { return }
        AppSettings.store.set(bar, forKey: PlateCalculator.barKey(unit))
        AppSettings.store.set(PlateCalculator.encode(available), forKey: PlateCalculator.platesKey(unit))
    }
}

/// One side of a loaded bar: plates from the collar outwards, taller for
/// heavier plates, each labeled with its weight.
private struct BarbellSideView: View {
    let plates: [Double]
    let heaviest: Double
    let format: (Double) -> String

    private let sleeve: CGFloat = 28
    private let collar: CGFloat = 20

    var body: some View {
        GeometryReader { geometry in
            let plateArea = max(geometry.size.height - 26, 20)
            // Narrower columns once there are too many plates to fit.
            let fits = (geometry.size.width - sleeve - collar) / CGFloat(max(plates.count, 1))
            let column = max(min(34, fits), 6)
            let plateWidth = min(18, column - 2)
            VStack(alignment: .leading, spacing: 6) {
                // Plates centred on the sleeve, taller for heavier plates
                HStack(alignment: .center, spacing: 0) {
                    Capsule()
                        .fill(Color.secondary.opacity(0.5))
                        .frame(width: sleeve, height: 10)
                    ForEach(Array(plates.enumerated()), id: \.offset) { _, plate in
                        RoundedRectangle(cornerRadius: min(4, plateWidth / 3))
                            .fill(Color.accentColor)
                            .frame(width: plateWidth, height: plateArea * (0.35 + 0.65 * plate / heaviest))
                            .frame(width: column)
                    }
                    Capsule()
                        .fill(Color.secondary.opacity(0.5))
                        .frame(width: collar, height: 10)
                }
                .frame(height: plateArea)
                // One row of labels, each under its plate (too cramped past ~14 plates)
                if column >= 22 {
                    HStack(spacing: 0) {
                        Color.clear.frame(width: sleeve, height: 1)
                        ForEach(Array(plates.enumerated()), id: \.offset) { _, plate in
                            Text(format(plate))
                                .font(.caption2)
                                .monospacedDigit()
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                                .frame(width: column)
                        }
                    }
                }
            }
            .frame(maxHeight: .infinity)
        }
    }
}
