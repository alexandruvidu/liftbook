import Testing
@testable import Liftbook

struct PlateCalculatorTests {
    private let kg = PlateCalculator.standardPlates(for: .kilograms)
    private let lb = PlateCalculator.standardPlates(for: .pounds)

    @Test func exactKilogramLoad() {
        let result = PlateCalculator.plates(for: 102.5, bar: 20, available: kg)
        #expect(result.perSide == [25, 15, 1.25])
        #expect(result.loaded == 102.5)
        #expect(result.shortBy == 0)
    }

    @Test func exactPoundLoad() {
        let result = PlateCalculator.plates(for: 225, bar: 45, available: lb)
        #expect(result.perSide == [45, 45])
        #expect(PlateCalculator.plates(for: 185, bar: 45, available: lb).perSide == [45, 25])
    }

    @Test func emptyBarNeedsNoPlates() {
        let result = PlateCalculator.plates(for: 20, bar: 20, available: kg)
        #expect(result.perSide.isEmpty)
        #expect(!result.belowBar)
    }

    @Test func belowTheBar() {
        #expect(PlateCalculator.plates(for: 15, bar: 20, available: kg).belowBar)
    }

    @Test func unreachableTargetsRoundDown() {
        let result = PlateCalculator.plates(for: 101, bar: 20, available: kg)
        #expect(result.loaded == 100)
        #expect(result.shortBy == 1)
    }

    @Test func respectsTheChosenPlates() {
        // Without 25s and 15s, 100 kg is 20 + 20 per side
        let result = PlateCalculator.plates(for: 100, bar: 20, available: [20, 10, 5])
        #expect(result.perSide == [20, 20])
    }

    @Test func encodingRoundTrips() {
        let text = PlateCalculator.encode([2.5, 25, 1.25, 10])
        #expect(text == "25,10,2.5,1.25")
        #expect(PlateCalculator.decode("25,10,2.5,1.25") == [25, 10, 2.5, 1.25])
    }

    @Test func absurdTargetsStopAtThePlateLimit() {
        let result = PlateCalculator.plates(for: 9_999_999_999, bar: 20, available: [25, 20, 1.25])
        #expect(result.perSide.count == PlateCalculator.maxPlatesPerSide)
        #expect(result.shortBy > 0)
    }
}
