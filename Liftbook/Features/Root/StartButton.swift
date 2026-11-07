import SwiftUI

/// The round + button floating beside the tab bar that starts a workout.
/// Liquid Glass on iOS 26, a material circle before that.
struct StartButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "plus")
                .font(.title2.weight(.bold))
                .foregroundStyle(.tint)
                .frame(width: 60, height: 60)
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .modifier(GlassCircle())
        .accessibilityLabel("Start a workout")
        .accessibilityIdentifier("startButton")
    }
}

private struct GlassCircle: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26, *) {
            content.glassEffect(.regular.interactive(), in: Circle())
        } else {
            content
                .background(.regularMaterial, in: Circle())
                .shadow(color: .black.opacity(0.18), radius: 10, y: 4)
        }
    }
}
