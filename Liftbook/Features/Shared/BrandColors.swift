import SwiftUI

extension Color {
    /// Text and icons drawn on top of the accent color: white in light mode,
    /// deep teal in dark mode (where the accent is a light mint).
    static let accentForeground = Color("OnAccent")
}

extension View {
    /// The tinted Liquid Glass button for a screen's main action. The system
    /// keeps its label white, which is unreadable on the dark-mode mint, so
    /// the label uses `accentForeground`.
    func prominentGlassButton() -> some View {
        buttonStyle(.glassProminent)
            .foregroundStyle(Color.accentForeground)
    }
}
