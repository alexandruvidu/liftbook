import SwiftUI

/// The "Start" button floating beside the tab bar that starts a workout.
/// Labelled, not a bare "+", so it isn't confused with the create buttons.
/// Liquid Glass on iOS 26, a material capsule before that.
struct StartButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label("Start", systemImage: "play.fill")
                .font(.headline)
                .foregroundStyle(.tint)
                .padding(.horizontal, 20)
                .frame(height: 56)
                .contentShape(Capsule())
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
            content.glassEffect(.regular.interactive(), in: Capsule())
        } else {
            content
                .background(.regularMaterial, in: Capsule())
                .shadow(color: .black.opacity(0.18), radius: 10, y: 4)
        }
    }
}
