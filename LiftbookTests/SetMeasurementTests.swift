import Foundation
import Testing
@testable import Liftbook

struct SetMeasurementTests {
    // MARK: Formatting

    @Test func weightAndReps() {
        #expect(SetMeasurement(weight: 60, reps: 8).formatted(for: .weightAndReps) == "60 kg × 8")
        #expect(SetMeasurement(weight: 62.5, reps: 5).formatted(for: .weightAndReps) == "62.5 kg × 5")
        #expect(SetMeasurement(weight: 60).formatted(for: .weightAndReps) == "60 kg")
        #expect(SetMeasurement(reps: 1).formatted(for: .weightAndReps) == "1 rep")
        #expect(SetMeasurement().formatted(for: .weightAndReps) == "—")
    }

    @Test func weightInPounds() {
        #expect(SetMeasurement(weight: 100, reps: 3).formatted(for: .weightAndReps, unit: .pounds) == "220.5 lb × 3")
        #expect(SetMeasurement(weight: 20.411_656_6, reps: 10).formatted(for: .weightAndReps, unit: .pounds) == "45 lb × 10")
    }

    @Test func bodyweight() {
        #expect(SetMeasurement(reps: 12).formatted(for: .bodyweight) == "12 reps")
        #expect(SetMeasurement(weight: 0, reps: 12).formatted(for: .bodyweight) == "12 reps")
        #expect(SetMeasurement(weight: 10, reps: 6).formatted(for: .bodyweight) == "6 reps · +10 kg")
    }

    @Test func assisted() {
        #expect(SetMeasurement(weight: 20, reps: 8).formatted(for: .assisted) == "8 reps · 20 kg assist")
        #expect(SetMeasurement(reps: 8).formatted(for: .assisted) == "8 reps")
    }

    @Test func duration() {
        #expect(SetMeasurement(duration: 45).formatted(for: .duration) == "0:45")
        #expect(SetMeasurement(duration: 90).formatted(for: .duration) == "1:30")
        #expect(SetMeasurement(duration: 3723).formatted(for: .duration) == "1:02:03")
        #expect(SetMeasurement().formatted(for: .duration) == "—")
    }

    @Test func distance() {
        #expect(SetMeasurement(duration: 1500, distance: 5000).formatted(for: .distance) == "5 km in 25:00")
        #expect(SetMeasurement(distance: 2500).formatted(for: .distance) == "2.5 km")
        #expect(SetMeasurement(distance: 1609.344).formatted(for: .distance, unit: .pounds) == "1 mi")
    }

    // MARK: Completeness

    @Test func completenessFollowsRequiredFields() {
        #expect(SetMeasurement(weight: 0, reps: 5).isComplete(for: .weightAndReps))
        #expect(!SetMeasurement(reps: 5).isComplete(for: .weightAndReps))
        #expect(!SetMeasurement(weight: 60, reps: 0).isComplete(for: .weightAndReps))
        #expect(SetMeasurement(reps: 10).isComplete(for: .bodyweight))
        #expect(SetMeasurement(reps: 10).isComplete(for: .assisted))
        #expect(!SetMeasurement(weight: 20).isComplete(for: .assisted))
        #expect(SetMeasurement(duration: 30).isComplete(for: .duration))
        #expect(!SetMeasurement(duration: 0).isComplete(for: .duration))
        #expect(SetMeasurement(distance: 400).isComplete(for: .distance))
        #expect(!SetMeasurement(duration: 120).isComplete(for: .distance))
    }

    // MARK: Type metadata

    @Test func everyTypeHasFieldsExampleAndExplanation() {
        for type in ExerciseType.allCases {
            #expect(!type.fieldSpecs.isEmpty)
            #expect(type.fieldSpecs.contains { !$0.isOptional }, "\(type) needs a required field")
            #expect(type.example.isComplete(for: type), "\(type) example should be complete")
            #expect(!type.explanation.isEmpty)
        }
    }

    @Test func requiredFieldsMatchCompleteness() {
        #expect(ExerciseType.weightAndReps.fieldSpecs.map(\.field) == [.weight, .reps])
        #expect(ExerciseType.duration.fieldSpecs.map(\.field) == [.duration])
        #expect(ExerciseType.distance.fieldSpecs.filter { !$0.isOptional }.map(\.field) == [.distance])
    }

    // MARK: Units

    @Test func unitConversionRoundTrips() {
        let pounds = WeightUnit.pounds
        #expect(abs(pounds.kilograms(fromDisplay: pounds.display(kilograms: 80)) - 80) < 0.000_1)
        #expect(WeightUnit.kilograms.display(kilograms: 80) == 80)
        #expect(SetMeasurement.decimal(2.25) == "2.3" || SetMeasurement.decimal(2.25) == "2.2")
        #expect(SetMeasurement.decimal(100) == "100")
    }

    @Test func measurementIsCodable() throws {
        let original = SetMeasurement(weight: 42.5, reps: 7, duration: 30, distance: 100)
        let decoded = try JSONDecoder().decode(SetMeasurement.self, from: JSONEncoder().encode(original))
        #expect(decoded == original)
    }
}
