import SwiftUI

/// iOS 27 behaviors, applied where the OS has them and skipped before.
extension View {
    /// Lets rows inside this scroll view use `swipeActions` (iOS 27). Before
    /// that, swipe actions only work in a `List`, so rows keep their menus.
    @ViewBuilder
    func swipeActionsContainerIfAvailable() -> some View {
        if #available(iOS 27, *) {
            swipeActionsContainer()
        } else {
            self
        }
    }

    /// Swipe left to delete, only while `isEnabled`: otherwise no swipe at
    /// all, so a row that can't be deleted doesn't slide. Rows outside a
    /// `List` need a `swipeActionsContainerIfAvailable()` around them.
    @ViewBuilder
    func swipeToDelete(_ title: String, isEnabled: Bool, identifier: String,
                       action: @escaping () -> Void) -> some View {
        if isEnabled {
            swipeActions(edge: .trailing) {
                Button(role: .destructive) {
                    withAnimation(.snappy) { action() }
                } label: {
                    Label(title, systemImage: "trash")
                }
                .accessibilityIdentifier(identifier)
            }
        } else {
            self
        }
    }
}

extension View {
    /// Stops the screen locking while this view is shown and `isOn`.
    func keepsScreenOn(_ isOn: Bool) -> some View {
        onAppear { UIApplication.shared.isIdleTimerDisabled = isOn }
            .onChange(of: isOn) { UIApplication.shared.isIdleTimerDisabled = isOn }
            .onDisappear { UIApplication.shared.isIdleTimerDisabled = false }
    }
}

extension ToolbarContent {
    /// Keeps this item in the bar ahead of others when space is tight (iOS 27).
    @ToolbarContentBuilder
    func keepsVisibleIfAvailable() -> some ToolbarContent {
        if #available(iOS 27, *) {
            visibilityPriority(.high)
        } else {
            self
        }
    }
}
