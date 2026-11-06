import Foundation
import SwiftData
import Testing
@testable import Liftbook

struct SetInputTests {
    @Test(arguments: [("62.5", 62.5), ("62,5", 62.5), (" 40 ", 40.0), ("0", 0.0)])
    func decimalParses(text: String, expected: Double) {
        #expect(SetInput.decimal(text) == expected)
    }

    @Test(arguments: ["", "abc", "-5", "1.2.3"])
    func decimalRejectsInvalid(text: String) {
        #expect(SetInput.decimal(text) == nil)
    }

    @Test func repsParsesWholeNumbers() {
        #expect(SetInput.reps("8") == 8)
        #expect(SetInput.reps("8.5") == nil)
        #expect(SetInput.reps("-1") == nil)
        #expect(SetInput.reps("") == nil)
    }

    @Test(arguments: [("90", 90.0), ("1:30", 90.0), ("1:02:03", 3723.0), ("0:45", 45.0)])
    func durationParses(text: String, expected: Double) {
        #expect(SetInput.duration(text) == expected)
    }

    @Test(arguments: ["", "1:75", "a:10", "1:2:3:4"])
    func durationRejectsInvalid(text: String) {
        #expect(SetInput.duration(text) == nil)
    }

    @Test func rpeOptionsRunFromSixToTenInHalfSteps() {
        #expect(SetInput.rpeOptions.first == 6)
        #expect(SetInput.rpeOptions.last == 10)
        #expect(SetInput.rpeOptions.count == 9)
    }
}

struct SetMeasurementInputTests {
    @Test func roundTripsEachField() {
        var m = SetMeasurement()
        m.setInput("62.5", for: .weight)
        m.setInput("8", for: .reps)
        m.setInput("1:30", for: .duration)
        m.setInput("5", for: .distance)
        #expect(m == SetMeasurement(weight: 62.5, reps: 8, duration: 90, distance: 5000))
        #expect(m.inputText(for: .weight) == "62.5")
        #expect(m.inputText(for: .reps) == "8")
        #expect(m.inputText(for: .duration) == "1:30")
        #expect(m.inputText(for: .distance) == "5")
    }

    @Test func poundsAreStoredAsKilograms() {
        var m = SetMeasurement()
        m.setInput("100", for: .weight, unit: .pounds)
        #expect(abs((m.weight ?? 0) - 45.359) < 0.001)
        #expect(m.inputText(for: .weight, unit: .pounds) == "100")
    }

    @Test func emptyTextClearsTheField() {
        var m = SetMeasurement(weight: 60, reps: 8)
        m.setInput("", for: .reps)
        #expect(m.reps == nil)
        #expect(m.weight == 60)
    }
}

@MainActor
struct WorkoutSetLoggingTests {
    private let container = Persistence.makeContainer(inMemory: true)

    private func exercise() -> WorkoutExercise {
        let session = WorkoutSession(name: "Test")
        container.mainContext.insert(session)
        session.addExercises(["barbell-bench-press"])
        return session.exercises[0]
    }

    @Test func addSetCopiesThePreviousSet() {
        let exercise = exercise()
        let first = exercise.orderedSets[0]
        first.measurement = SetMeasurement(weight: 60, reps: 8)
        first.kind = .warmUp
        first.toggleCompleted(for: .weightAndReps)

        let added = exercise.addSet()
        #expect(added.position == 1)
        #expect(added.measurement == SetMeasurement(weight: 60, reps: 8))
        #expect(added.kind == .warmUp)
        #expect(!added.isCompleted)
        #expect(exercise.orderedSets.count == 2)
    }

    @Test func addSetSkipsEmptySetsWhenCopying() {
        let exercise = exercise()
        exercise.orderedSets[0].measurement = SetMeasurement(weight: 80, reps: 5)
        exercise.addSet().measurement = SetMeasurement()
        let added = exercise.addSet()
        #expect(added.position == 2)
        #expect(added.measurement == SetMeasurement(weight: 80, reps: 5))
    }

    @Test func removeSetRenumbersTheRest() {
        let exercise = exercise()
        exercise.addSet()
        exercise.addSet()
        let middle = exercise.orderedSets[1]
        exercise.removeSet(middle)
        #expect(exercise.orderedSets.map(\.position) == [0, 1])
    }

    @Test func incompleteSetCannotBeCheckedOff() {
        let set = exercise().orderedSets[0]
        set.weight = 60
        #expect(!set.toggleCompleted(for: .weightAndReps))
        #expect(set.completedAt == nil)
    }

    @Test func completeSetTogglesOnAndOff() {
        let set = exercise().orderedSets[0]
        set.measurement = SetMeasurement(weight: 60, reps: 8)
        let date = Date(timeIntervalSince1970: 1_000)
        #expect(set.toggleCompleted(for: .weightAndReps, at: date))
        #expect(set.completedAt == date)
        #expect(!set.toggleCompleted(for: .weightAndReps))
        #expect(set.completedAt == nil)
    }
}

/// Checking off a set whose empty fields show last time's values.
struct PlaceholderCompletionTests {
    private let last = SetMeasurement(weight: 40, reps: 10)

    @Test func placeholderFillsEmptyFields() {
        let set = WorkoutSet(position: 0)
        #expect(set.toggleCompleted(for: .weightAndReps, placeholder: last))
        #expect(set.measurement == SetMeasurement(weight: 40, reps: 10))
    }

    @Test func typedValueWinsOverPlaceholder() {
        let set = WorkoutSet(position: 0, measurement: SetMeasurement(reps: 8))
        #expect(set.toggleCompleted(for: .weightAndReps, placeholder: last))
        #expect(set.measurement == SetMeasurement(weight: 40, reps: 8))
    }

    @Test func noPlaceholderStillNeedsCompleteInput() {
        let set = WorkoutSet(position: 0, measurement: SetMeasurement(reps: 8))
        #expect(!set.toggleCompleted(for: .weightAndReps, placeholder: nil))
        #expect(set.measurement == SetMeasurement(reps: 8))
    }

    @Test func uncheckKeepsValues() {
        let set = WorkoutSet(position: 0)
        set.toggleCompleted(for: .weightAndReps, placeholder: last)
        #expect(!set.toggleCompleted(for: .weightAndReps, placeholder: SetMeasurement(weight: 99, reps: 1)))
        #expect(set.measurement == SetMeasurement(weight: 40, reps: 10))
    }

    @Test func placeholderOnlyFillsTheTypesFields() {
        // A timed exercise doesn't pick up weight or reps.
        let set = WorkoutSet(position: 0)
        #expect(!set.toggleCompleted(for: .duration, placeholder: last))
        #expect(set.measurement == SetMeasurement())
    }
}

struct CompactTextTests {
    @Test func weightAndReps() {
        #expect(SetMeasurement(weight: 62.5, reps: 8).compactText(for: .weightAndReps) == "62.5 × 8")
    }

    @Test func poundsConverted() {
        #expect(SetMeasurement(weight: 100, reps: 5).compactText(for: .weightAndReps, unit: .pounds) == "220.5 × 5")
    }

    @Test func bodyweightShowsAddedWeight() {
        #expect(SetMeasurement(reps: 12).compactText(for: .bodyweight) == "12")
        #expect(SetMeasurement(weight: 10, reps: 12).compactText(for: .bodyweight) == "+10 × 12")
    }

    @Test func durationAndDistance() {
        #expect(SetMeasurement(duration: 90).compactText(for: .duration) == "1:30")
        #expect(SetMeasurement(duration: 1500, distance: 5000).compactText(for: .distance) == "5 · 25:00")
    }

    @Test func emptyIsDash() {
        #expect(SetMeasurement().compactText(for: .weightAndReps) == "–")
    }
}
