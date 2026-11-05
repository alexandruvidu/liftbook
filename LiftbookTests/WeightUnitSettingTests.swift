import Foundation
import Testing
@testable import Liftbook

struct WeightUnitSettingTests {
    @Test func storedValuesRoundTrip() {
        let defaults = UserDefaults(suiteName: "WeightUnitSettingTests")!
        defaults.removePersistentDomain(forName: "WeightUnitSettingTests")
        #expect(defaults.string(forKey: WeightUnit.storageKey) == nil)
        defaults.set(WeightUnit.pounds.rawValue, forKey: WeightUnit.storageKey)
        #expect(WeightUnit(rawValue: defaults.string(forKey: WeightUnit.storageKey) ?? "") == .pounds)
    }

    @Test func poundsShowConvertedValues() {
        let set = SetMeasurement(weight: 100, reps: 5)
        #expect(set.formatted(for: .weightAndReps, unit: .pounds) == "220.5 lb × 5")
        #expect(set.inputText(for: .weight, unit: .pounds) == "220.5")
        #expect(SetMeasurement(distance: 1609.344).formatted(for: .distance, unit: .pounds) == "1 mi")
    }

    @Test func typingPoundsKeepsTheValueStable() {
        // 135 lb stored as kg and shown again as 135 lb
        var set = SetMeasurement()
        set.setInput("135", for: .weight, unit: .pounds)
        #expect(set.inputText(for: .weight, unit: .pounds) == "135")
        #expect(SetMeasurement.number(set.weight ?? 0, unit: .kilograms) == "61.2")
    }
}
