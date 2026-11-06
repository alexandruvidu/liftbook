import Foundation
import SwiftData
import Testing
@testable import Liftbook

@MainActor
struct WarmUpCalculatorTests {
    @Test func rampsToTheWorkingWeight() {
        let steps = WarmUpCalculator.steps(working: 100, bar: 20, smallestPlate: 1.25)
        #expect(steps.map(\.weight) == [20, 40, 60, 80])
        #expect(steps.map(\.reps) == [10, 5, 3, 2])
    }

    @Test func roundsDownToLoadableWeights() {
        // 5 kg steps with 2.5 kg plates: 55 → 55, 82.5 → 80, 110 → 110
        #expect(WarmUpCalculator.steps(working: 137.5, bar: 20, smallestPlate: 2.5).map(\.weight) == [20, 55, 80, 110])
        // Pounds with 2.5 lb plates: steps of 5 lb
        #expect(WarmUpCalculator.steps(working: 225, bar: 45, smallestPlate: 2.5).map(\.weight) == [45, 90, 135, 180])
    }

    @Test func lightWorkingWeightsSkipStepsBelowTheBar() {
        // 40% of 40 = 16 is under the bar; 60% = 24 → 22.5; 80% = 32 → 30
        let steps = WarmUpCalculator.steps(working: 40, bar: 20, smallestPlate: 1.25)
        #expect(steps.map(\.weight) == [20, 22.5, 30])
    }

    @Test func nothingAtOrBelowTheBar() {
        #expect(WarmUpCalculator.steps(working: 20, bar: 20, smallestPlate: 1.25).isEmpty)
    }

    @Test func warmUpsGoBeforeWorkingSetsAndReplaceOldOnes() {
        let container = Persistence.makeContainer(inMemory: true)
        let session = WorkoutSession(name: "W")
        container.mainContext.insert(session)
        session.addExercises(["bench"], setCount: 2)
        let exercise = session.exercises[0]
        exercise.orderedSets.forEach { $0.measurement = SetMeasurement(weight: 100, reps: 5) }
        #expect(exercise.workingWeight == 100)

        exercise.setWarmUps([(20, 10), (60, 3)])
        #expect(exercise.orderedSets.map(\.kind) == [.warmUp, .warmUp, .normal, .normal])
        #expect(exercise.orderedSets.map(\.weight) == [20, 60, 100, 100])

        exercise.setWarmUps([(50, 5)])
        #expect(exercise.orderedSets.map(\.kind) == [.warmUp, .normal, .normal])
        #expect(exercise.orderedSets.map(\.position) == [0, 1, 2])
        #expect(exercise.workingWeight == 100)
    }
}
