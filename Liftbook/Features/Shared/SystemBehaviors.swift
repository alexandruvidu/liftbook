import SwiftUI

/// Newer system behaviors, applied where the OS has them and skipped before.
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

    /// Shrinks the tab bar while scrolling down, so it covers less (iOS 26).
    @ViewBuilder
    func minimizesTabBarOnScroll() -> some View {
        if #available(iOS 26, *) {
            tabBarMinimizeBehavior(.onScrollDown)
        } else {
            self
        }
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
