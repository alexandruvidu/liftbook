import Foundation
import Testing
@testable import Liftbook

struct SetKeypadTests {
    private let english = Locale(identifier: "en_US")

    @Test func eachFieldGetsItsOwnExtraKey() {
        #expect(SetKeypad.separator(for: .weight, locale: english) == ".")
        #expect(SetKeypad.separator(for: .weight, locale: Locale(identifier: "ro_RO")) == ",")
        #expect(SetKeypad.separator(for: .duration) == ":")
        #expect(SetKeypad.separator(for: .reps) == nil)
    }

    @Test func stepsMatchTheUnit() {
        #expect(SetKeypad.stepLabel(for: .weight, unit: .kilograms, locale: english) == "2.5")
        #expect(SetKeypad.stepLabel(for: .weight, unit: .pounds, locale: english) == "5")
        #expect(SetKeypad.stepLabel(for: .reps, unit: .kilograms, locale: english) == "1")
        #expect(SetKeypad.stepLabel(for: .duration, unit: .kilograms, locale: english) == "15s")
    }

    @Test func steppingMovesTheTypedValue() {
        func step(_ text: String, _ field: SetField, up: Bool = true, placeholder: String? = nil) -> String {
            SetKeypad.stepped(text, placeholder: placeholder, field: field, unit: .kilograms, up: up, locale: english)
        }
        #expect(step("60", .weight) == "62.5")
        #expect(step("62.5", .weight, up: false) == "60")
        #expect(step("8", .reps) == "9")
        #expect(step("1:00", .duration) == "1:15")
        #expect(step("2", .distance) == "2.5")
    }

    @Test func anEmptyFieldStepsFromLastTime() {
        let up = SetKeypad.stepped("", placeholder: "80", field: .weight, unit: .kilograms, up: true, locale: english)
        #expect(up == "82.5")
        let fresh = SetKeypad.stepped("", placeholder: nil, field: .reps, unit: .kilograms, up: true, locale: english)
        #expect(fresh == "1")
    }

    @Test func steppingStaysWithinLimits() {
        #expect(SetKeypad.stepped("1", placeholder: nil, field: .weight, unit: .kilograms, up: false, locale: english) == "0")
        #expect(SetKeypad.stepped("0", placeholder: nil, field: .reps, unit: .kilograms, up: false, locale: english) == "0")
        #expect(SetKeypad.stepped("2000", placeholder: nil, field: .weight, unit: .kilograms, up: true, locale: english) == "2000")
    }
}
