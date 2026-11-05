import Foundation
import SwiftData

/// What a body metric measures, which decides its unit.
enum BodyMetricKind: String, Codable, CaseIterable, Identifiable, Sendable {
    /// Stored in kilograms.
    case weight
    /// Stored in centimetres.
    case length
    case percent
    /// A plain number with no unit.
    case number

    static let centimetresPerInch = 2.54

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .weight: "Weight"
        case .length: "Length"
        case .percent: "Percentage"
        case .number: "Number"
        }
    }

    /// "kg"/"lb", "cm"/"in", "%" or "" — inches go with pounds.
    func symbol(unit: WeightUnit) -> String {
        switch self {
        case .weight: unit.symbol
        case .length: unit == .kilograms ? "cm" : "in"
        case .percent: "%"
        case .number: ""
        }
    }

    func display(_ stored: Double, unit: WeightUnit) -> Double {
        switch self {
        case .weight: unit.display(kilograms: stored)
        case .length: unit == .kilograms ? stored : stored / Self.centimetresPerInch
        case .percent, .number: stored
        }
    }

    func stored(fromDisplay value: Double, unit: WeightUnit) -> Double {
        switch self {
        case .weight: unit.kilograms(fromDisplay: value)
        case .length: unit == .kilograms ? value : value * Self.centimetresPerInch
        case .percent, .number: value
        }
    }

    /// "82.5 kg", "18 %", "36 in".
    func formatted(_ stored: Double, unit: WeightUnit) -> String {
        let number = SetMeasurement.decimal(display(stored, unit: unit))
        let symbol = symbol(unit: unit)
        return symbol.isEmpty ? number : "\(number) \(symbol)"
    }
}

/// Something you track about your body, e.g. body weight or waist.
@Model
final class BodyMetric {
    @Attribute(.unique) var metricID: String
    var name: String
    var kindID: String
    var sortIndex: Int
    var isBuiltIn: Bool

    init(metricID: String = "metric-\(UUID().uuidString)", name: String, kind: BodyMetricKind,
         sortIndex: Int, isBuiltIn: Bool = false) {
        self.metricID = metricID
        self.name = name
        kindID = kind.rawValue
        self.sortIndex = sortIndex
        self.isBuiltIn = isBuiltIn
    }

    var kind: BodyMetricKind { BodyMetricKind(rawValue: kindID) ?? .number }

    static let bodyWeightID = "body-weight"
    static let bodyFatID = "body-fat"
}

/// One logged value of a body metric.
@Model
final class BodyMeasurement {
    var metricID: String
    /// In the metric's stored unit (kg, cm, % or a plain number).
    var value: Double
    var date: Date

    init(metricID: String, value: Double, date: Date = .now) {
        self.metricID = metricID
        self.value = value
        self.date = date
    }
}

enum BodyMetrics {
    enum Problem: Equatable {
        case missingName, duplicateName
    }

    /// Adds Body Weight and Body Fat if they aren't there yet.
    @MainActor
    static func ensureBuiltIns(in context: ModelContext) {
        let existing = Set(((try? context.fetch(FetchDescriptor<BodyMetric>())) ?? []).map(\.metricID))
        if !existing.contains(BodyMetric.bodyWeightID) {
            context.insert(BodyMetric(metricID: BodyMetric.bodyWeightID, name: "Body Weight", kind: .weight, sortIndex: 0, isBuiltIn: true))
        }
        if !existing.contains(BodyMetric.bodyFatID) {
            context.insert(BodyMetric(metricID: BodyMetric.bodyFatID, name: "Body Fat", kind: .percent, sortIndex: 1, isBuiltIn: true))
        }
        try? context.save()
    }

    /// Why a new metric name can't be used, if it can't.
    static func problem(withName name: String, existing: [BodyMetric]) -> Problem? {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return .missingName }
        if existing.contains(where: { $0.name.compare(trimmed, options: [.caseInsensitive, .diacriticInsensitive]) == .orderedSame }) {
            return .duplicateName
        }
        return nil
    }

    /// Measurements of a metric, oldest first.
    static func history(of metricID: String, in measurements: [BodyMeasurement]) -> [BodyMeasurement] {
        measurements.filter { $0.metricID == metricID }.sorted { $0.date < $1.date }
    }

    /// Latest value minus the one before, or nil with fewer than two.
    static func lastChange(of metricID: String, in measurements: [BodyMeasurement]) -> Double? {
        let history = history(of: metricID, in: measurements)
        guard history.count > 1 else { return nil }
        return history[history.count - 1].value - history[history.count - 2].value
    }
}
