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

    /// Lets set fields in this scroll view move themselves to the middle of
    /// the screen when focused, so the keyboard and its toolbar don't hide them.
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
        withAnimation { proxy.scrollTo(id, anchor: .center) }
    }
}

extension EnvironmentValues {
    @Entry var revealField: RevealField?
}
