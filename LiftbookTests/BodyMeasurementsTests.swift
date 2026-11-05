import Foundation
import SwiftData
import Testing
@testable import Liftbook

@MainActor
struct BodyMeasurementsTests {
    private let container = Persistence.makeContainer(inMemory: true)

    @Test func builtInsAreAddedOnce() throws {
        let context = container.mainContext
        BodyMetrics.ensureBuiltIns(in: context)
        BodyMetrics.ensureBuiltIns(in: context)
        let metrics = try context.fetch(FetchDescriptor<BodyMetric>(sortBy: [SortDescriptor(\.sortIndex)]))
        #expect(metrics.map(\.metricID) == [BodyMetric.bodyWeightID, BodyMetric.bodyFatID])
        #expect(metrics.map(\.kind) == [.weight, .percent])
        #expect(metrics.allSatisfy(\.isBuiltIn))
    }

    @Test(arguments: [
        (BodyMetricKind.weight, WeightUnit.pounds, 100.0, "220.5 lb"),
        (.weight, .kilograms, 82.5, "82.5 kg"),
        (.length, .pounds, 91.44, "36 in"),
        (.length, .kilograms, 91.44, "91.4 cm"),
        (.percent, .pounds, 18, "18 %"),
        (.number, .kilograms, 7, "7"),
    ])
    func formatsInTheChosenUnit(kind: BodyMetricKind, unit: WeightUnit, stored: Double, expected: String) {
        #expect(kind.formatted(stored, unit: unit) == expected)
    }

    @Test(arguments: BodyMetricKind.allCases)
    func displayAndStoredRoundTrip(kind: BodyMetricKind) {
        for unit in WeightUnit.allCases {
            let stored = kind.stored(fromDisplay: 36, unit: unit)
            #expect(abs(kind.display(stored, unit: unit) - 36) < 0.0001)
        }
    }

    @Test func newMetricNamesMustBeUniqueAndPresent() {
        let existing = [BodyMetric(name: "Waist", kind: .length, sortIndex: 2)]
        #expect(BodyMetrics.problem(withName: "  ", existing: existing) == .missingName)
        #expect(BodyMetrics.problem(withName: "waist ", existing: existing) == .duplicateName)
        #expect(BodyMetrics.problem(withName: "Chest", existing: existing) == nil)
    }

    @Test func historyIsOldestFirstAndChangeComparesTheLastTwo() {
        let day: TimeInterval = 86_400
        let measurements = [
            BodyMeasurement(metricID: "w", value: 80, date: Date(timeIntervalSince1970: 3 * day)),
            BodyMeasurement(metricID: "w", value: 82, date: Date(timeIntervalSince1970: 1 * day)),
            BodyMeasurement(metricID: "w", value: 81, date: Date(timeIntervalSince1970: 2 * day)),
            BodyMeasurement(metricID: "other", value: 5, date: Date(timeIntervalSince1970: 4 * day)),
        ]
        #expect(BodyMetrics.history(of: "w", in: measurements).map(\.value) == [82, 81, 80])
        #expect(BodyMetrics.lastChange(of: "w", in: measurements) == -1)
        #expect(BodyMetrics.lastChange(of: "other", in: measurements) == nil)
    }
}
