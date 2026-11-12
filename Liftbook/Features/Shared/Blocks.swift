import SwiftUI

/// A raised rounded surface for rich content that a list row can't hold,
/// like an exercise's sets in the live workout. List-like screens use
/// `List` sections instead.
struct Block<Content: View>: View {
    @ViewBuilder var content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            content
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground), in: .card)
        // Controls inside round their corners concentric with the block.
        .containerShape(.rect(cornerRadius: 18))
    }
}

extension Shape where Self == ConcentricRectangle {
    /// A card's corners: concentric with its container, never tighter than
    /// `minimum` (the radius a card had before concentric corners).
    static func card(minimum: CGFloat) -> ConcentricRectangle {
        ConcentricRectangle(corners: .concentric(minimum: .fixed(minimum)), isUniform: true)
    }

    static var card: ConcentricRectangle { card(minimum: 18) }
}

/// A bold section title between blocks, e.g. "History".
struct SectionTitle: View {
    let text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        Text(text)
            .font(.title3.weight(.bold))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 8)
            .accessibilityAddTraits(.isHeader)
    }
}

/// The page background behind blocks.
extension View {
    func blockScreenBackground() -> some View {
        background(Color(.systemGroupedBackground).ignoresSafeArea())
    }
}

extension Binding where Value == Set<ObjectIdentifier> {
    /// Whether `id` is in the set, as a toggle: true inserts it, false removes it.
    func member(_ id: ObjectIdentifier) -> Binding<Bool> {
        Binding<Bool>(get: { wrappedValue.contains(id) },
                      set: { isMember in
                          if isMember { wrappedValue.insert(id) } else { wrappedValue.remove(id) }
                      })
    }
}
