import Foundation

/// Works out which plates to load on each side of a bar. All values are in
/// the display unit (kg or lb), since plate sets differ between the two.
enum PlateCalculator {
    struct Result: Equatable, Sendable {
        /// Plates for one side, heaviest first.
        let perSide: [Double]
        /// The weight actually loaded (bar + both sides).
        let loaded: Double
        /// Target minus loaded; 0 when the target is reachable exactly.
        let shortBy: Double
        /// The target is lighter than the empty bar.
        let belowBar: Bool
    }

    static func defaultBar(for unit: WeightUnit) -> Double {
        unit == .kilograms ? 20 : 45
    }

    /// Plate sizes commonly found in gyms, heaviest first.
    static func standardPlates(for unit: WeightUnit) -> [Double] {
        unit == .kilograms ? [25, 20, 15, 10, 5, 2.5, 1.25] : [45, 35, 25, 10, 5, 2.5]
    }

    static let barOptionsKilograms: [Double] = [20, 15, 10, 7, 25]
    static let barOptionsPounds: [Double] = [45, 35, 25, 15, 55]

    /// Plates per side for `target`, greedily using the heaviest available
    /// plate first (exact for standard plate sets). Rounds down if the target
    /// can't be made exactly.
    static func plates(for target: Double, bar: Double, available: [Double]) -> Result {
        // Hundredths, so 1.25 and 2.5 add up without floating-point drift.
        let targetUnits = Int((target * 100).rounded())
        let barUnits = Int((bar * 100).rounded())
        guard targetUnits >= barUnits else {
            return Result(perSide: [], loaded: bar, shortBy: 0, belowBar: true)
        }
        var remainingPerSide = (targetUnits - barUnits) / 2
        var perSide: [Double] = []
        for plate in Set(available).sorted(by: >) where plate > 0 {
            let plateUnits = Int((plate * 100).rounded())
            while remainingPerSide >= plateUnits {
                perSide.append(plate)
                remainingPerSide -= plateUnits
            }
        }
        let loadedUnits = barUnits + 2 * perSide.reduce(0) { $0 + Int(($1 * 100).rounded()) }
        return Result(perSide: perSide,
                      loaded: Double(loadedUnits) / 100,
                      shortBy: Double(targetUnits - loadedUnits) / 100,
                      belowBar: false)
    }

    /// "20,10,1.25" ⇄ [20, 10, 1.25], for storing the chosen plates.
    static func encode(_ plates: [Double]) -> String {
        plates.sorted(by: >).map { String(format: "%g", $0) }.joined(separator: ",")
    }

    static func decode(_ text: String) -> [Double] {
        text.split(separator: ",").compactMap { Double($0) }.sorted(by: >)
    }

    /// Settings keys; plates and bar are kept per unit.
    static func barKey(_ unit: WeightUnit) -> String { "plates.bar.\(unit.rawValue)" }
    static func platesKey(_ unit: WeightUnit) -> String { "plates.available.\(unit.rawValue)" }
}
