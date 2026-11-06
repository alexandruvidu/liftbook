import SwiftUI

/// A raised rounded surface that groups related content. The building block
/// of every screen, in place of grouped list sections.
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
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 18))
    }
}

/// A block's title row: optional image, title, subtitle, trailing action.
struct BlockHeader<Trailing: View>: View {
    let title: String
    var subtitle: String?
    var image: Image?
    @ViewBuilder var trailing: Trailing

    init(_ title: String, subtitle: String? = nil, image: Image? = nil, @ViewBuilder trailing: () -> Trailing) {
        self.title = title
        self.subtitle = subtitle
        self.image = image
        self.trailing = trailing()
    }

    var body: some View {
        HStack(spacing: 12) {
            if let image {
                image
                    .font(.title3)
                    .foregroundStyle(.tint)
                    .frame(width: 44, height: 44)
                    .background(.fill.tertiary, in: RoundedRectangle(cornerRadius: 12))
                    .accessibilityHidden(true)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                if let subtitle {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: 8)
            trailing
        }
    }
}

extension BlockHeader where Trailing == EmptyView {
    init(_ title: String, subtitle: String? = nil, image: Image? = nil) {
        self.init(title, subtitle: subtitle, image: image) { EmptyView() }
    }
}

/// A titled block for screens built from blocks instead of a list: a small
/// bold title, the block, then an optional note.
struct BlockSection<Content: View>: View {
    let title: String
    var footer: String?
    @ViewBuilder var content: Content

    init(_ title: String, footer: String? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.footer = footer
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .accessibilityAddTraits(.isHeader)
            Block { content }
            if let footer {
                Text(footer)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 4)
            }
        }
    }
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

/// A capsule button: quiet fill, or the accent when prominent.
struct PillButtonStyle: ButtonStyle {
    var prominent = false
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.semibold))
            .lineLimit(1)
            .padding(.horizontal, 14)
            .frame(minHeight: 34)
            .foregroundStyle(prominent ? Color.accentForeground : Color.primary)
            .background {
                Capsule().fill(prominent ? AnyShapeStyle(Color.accentColor) : AnyShapeStyle(.fill.tertiary))
            }
            .opacity(configuration.isPressed ? 0.7 : (isEnabled ? 1 : 0.4))
            .contentShape(Capsule())
    }
}

extension ButtonStyle where Self == PillButtonStyle {
    static var pill: PillButtonStyle { PillButtonStyle() }
    static var pillProminent: PillButtonStyle { PillButtonStyle(prominent: true) }
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
