import SwiftUI
import UIKit

extension View {
    /// A Done button above the keyboard. Number pads have no return key, so
    /// every screen with one needs this to put the keyboard away.
    func keyboardDoneButton() -> some View {
        toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
                .accessibilityIdentifier("keyboard.done")
            }
        }
    }

    /// Lets set fields in this scroll view scroll into view when focused, so
    /// the keypad doesn't hide them.
    func revealsFocusedFields() -> some View {
        ScrollViewReader { proxy in
            environment(\.revealField, RevealField(proxy: proxy))
        }
    }
}

/// Scrolls the enclosing scroll view to a focused field (see `revealsFocusedFields`).
struct RevealField {
    let proxy: ScrollViewProxy

    func callAsFunction(_ id: some Hashable) {
        // Only as far as needed: a field already in view stays put.
        withAnimation { proxy.scrollTo(id, anchor: nil) }
    }
}

extension EnvironmentValues {
    @Entry var revealField: RevealField?
}
