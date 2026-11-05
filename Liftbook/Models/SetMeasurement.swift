import Foundation

/// Units used to display weights and distances. Values are always stored in
/// kilograms and metres; this only affects presentation.
enum WeightUnit: String, Codable, CaseIterable, Identifiable, Sendable {
    case kilograms, pounds

    static let poundsPerKilogram = 2.204_622_62
    /// Settings key for the unit chosen in Profile.
    static let storageKey = "units.weight"

    var id: String { rawValue }
    var symbol: String { self == .kilograms ? "kg" : "lb" }
    var distanceSymbol: String { self == .kilograms ? "km" : "mi" }

    func display(kilograms: Double) -> Double {
        self == .kilograms ? kilograms : kilograms * Self.poundsPerKilogram
    }

    func kilograms(fromDisplay value: Double) -> Double {
        self == .kilograms ? value : value / Self.poundsPerKilogram
    }

    func display(metres: Double) -> Double {
        self == .kilograms ? metres / 1000 : metres / 1609.344
    }
}

/// One of the values a set can record.
enum SetField: String, CaseIterable, Sendable {
    case weight, reps, duration, distance

    var systemImage: String {
        switch self {
        case .weight: "scalemass"
        case .reps: "number"
        case .duration: "timer"
        case .distance: "point.topleft.down.to.point.bottomright.curvepath"
        }
    }
}

/// What a single set recorded. Weight is in kilograms (for assisted exercises
/// it is the assistance), duration in seconds, distance in metres.
struct SetMeasurement: Equatable, Hashable, Codable, Sendable {
    var weight: Double?
    var reps: Int?
    var duration: TimeInterval?
    var distance: Double?

    init(weight: Double? = nil, reps: Int? = nil, duration: TimeInterval? = nil, distance: Double? = nil) {
        self.weight = weight
        self.reps = reps
        self.duration = duration
        self.distance = distance
    }

    /// Whether the set has every required value for the exercise type.
    func isComplete(for type: ExerciseType) -> Bool {
        switch type {
        case .weightAndReps: (weight ?? -1) >= 0 && (reps ?? 0) > 0
        case .bodyweight, .assisted: (reps ?? 0) > 0
        case .duration: (duration ?? 0) > 0
        case .distance: (distance ?? 0) > 0
        }
    }

    /// Human-readable summary, e.g. "60 kg × 8" or "5 km in 25:00".
    func formatted(for type: ExerciseType, unit: WeightUnit = .kilograms) -> String {
        let weightText = weight.map { "\(Self.number($0, unit: unit)) \(unit.symbol)" }
        let repsText = reps.map { $0 == 1 ? "1 rep" : "\($0) reps" }

        switch type {
        case .weightAndReps:
            switch (weightText, reps) {
            case let (w?, r?): return "\(w) × \(r)"
            case let (w?, nil): return w
            case (nil, _?): return repsText ?? ""
            default: return "—"
            }
        case .bodyweight:
            guard let repsText else { return "—" }
            guard let weight, weight > 0, let weightText else { return repsText }
            return "\(repsText) · +\(weightText)"
        case .assisted:
            guard let repsText else { return "—" }
            guard let weight, weight > 0, let weightText else { return repsText }
            return "\(repsText) · \(weightText) assist"
        case .duration:
            return duration.map(Self.clock) ?? "—"
        case .distance:
            guard let distance else { return "—" }
            let distanceText = "\(Self.decimal(unit.display(metres: distance))) \(unit.distanceSymbol)"
            guard let duration, duration > 0 else { return distanceText }
            return "\(distanceText) in \(Self.clock(duration))"
        }
    }

    /// "m:ss", or "h:mm:ss" from one hour.
    static func clock(_ seconds: TimeInterval) -> String {
        let total = Int(seconds.rounded())
        let h = total / 3600, m = (total % 3600) / 60, s = total % 60
        return h > 0
            ? String(format: "%d:%02d:%02d", h, m, s)
            : String(format: "%d:%02d", m, s)
    }

    /// Weight in the display unit, rounded to 0.1 and without a trailing ".0".
    static func number(_ kilograms: Double, unit: WeightUnit) -> String {
        decimal(unit.display(kilograms: kilograms))
    }

    static func decimal(_ value: Double) -> String {
        let rounded = (value * 10).rounded() / 10
        return rounded == rounded.rounded()
            ? String(Int(rounded))
            : String(format: "%.1f", rounded)
    }
}

extension ExerciseType {
    struct FieldSpec: Hashable, Sendable {
        let field: SetField
        let label: String
        let isOptional: Bool
    }

    /// The values recorded for each set of this type, in entry order.
    var fieldSpecs: [FieldSpec] {
        switch self {
        case .weightAndReps:
            [FieldSpec(field: .weight, label: "Weight", isOptional: false),
             FieldSpec(field: .reps, label: "Reps", isOptional: false)]
        case .bodyweight:
            [FieldSpec(field: .reps, label: "Reps", isOptional: false),
             FieldSpec(field: .weight, label: "Added weight", isOptional: true)]
        case .assisted:
            [FieldSpec(field: .weight, label: "Assistance", isOptional: true),
             FieldSpec(field: .reps, label: "Reps", isOptional: false)]
        case .duration:
            [FieldSpec(field: .duration, label: "Time", isOptional: false)]
        case .distance:
            [FieldSpec(field: .distance, label: "Distance", isOptional: false),
             FieldSpec(field: .duration, label: "Time", isOptional: true)]
        }
    }

    var explanation: String {
        switch self {
        case .weightAndReps: "Log the weight you lifted and how many reps you did."
        case .bodyweight: "Log your reps. Add extra weight if you wear a vest or belt."
        case .assisted: "Log reps and how much help the machine or band gave. Less assistance means a harder set."
        case .duration: "Log how long you held or performed the exercise."
        case .distance: "Log the distance you covered and, optionally, how long it took."
        }
    }

    /// A typical set, used to show what a logged set looks like.
    var example: SetMeasurement {
        switch self {
        case .weightAndReps: SetMeasurement(weight: 60, reps: 8)
        case .bodyweight: SetMeasurement(reps: 12)
        case .assisted: SetMeasurement(weight: 20, reps: 8)
        case .duration: SetMeasurement(duration: 60)
        case .distance: SetMeasurement(duration: 1500, distance: 5000)
        }
    }
}
