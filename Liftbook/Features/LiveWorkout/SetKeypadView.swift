import SwiftUI
import UIKit

/// A key of the set keypad.
enum SetKeypadKey: Equatable {
    case digit(Int)
    case separator(String)
    case delete
    /// Clears the field (a long press on delete).
    case clear
    case step(up: Bool)
    case next
    case done
}

/// Which set field the keypad is editing, on one screen. The fields are
/// plain SwiftUI views (`SetValueField`), so swiping a set row and tapping
/// around it work as anywhere else; there's no system keyboard.
@MainActor
@Observable
final class SetKeypadSession {
    /// What a field does with the keys.
    struct Field {
        let separator: String?
        let stepLabel: String
        let apply: (SetKeypadKey) -> Void
    }

    /// The focused field's place (exercise, set, field); nil when the keypad is down.
    private(set) var focused: [Int]?
    private(set) var separator: String?
    private(set) var stepLabel = ""
    private(set) var hasNext = false
    @ObservationIgnored private var fields: [[Int]: Field] = [:]

    func register(_ field: Field, at order: [Int]) {
        fields[order] = field
    }

    func unregister(_ order: [Int]) {
        fields[order] = nil
        if focused == order { focused = nil }
    }

    func focus(_ order: [Int]) {
        guard let field = fields[order] else { return }
        // A note being typed puts its system keyboard away.
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        separator = field.separator
        stepLabel = field.stepLabel
        hasNext = next(after: order) != nil
        focused = order
    }

    func dismiss() {
        focused = nil
    }

    func press(_ key: SetKeypadKey) {
        guard let focused else { return }
        switch key {
        case .next:
            if let next = next(after: focused) { focus(next) } else { dismiss() }
        case .done:
            dismiss()
        default:
            fields[focused]?.apply(key)
        }
    }

    /// The field after `order` in workout order: same set's next value, then the next set.
    private func next(after order: [Int]) -> [Int]? {
        fields.keys.filter { order.lexicographicallyPrecedes($0) }.min { $0.lexicographicallyPrecedes($1) }
    }
}

extension View {
    /// Shows the set keypad at the bottom while one of this screen's set
    /// fields is being edited.
    func setKeypad(_ session: SetKeypadSession) -> some View {
        environment(session)
            .safeAreaInset(edge: .bottom, spacing: 0) {
                if session.focused != nil {
                    SetKeypadView(session: session)
                        .transition(.move(edge: .bottom))
                }
            }
            .animation(.snappy(duration: 0.25), value: session.focused == nil)
            // A system keyboard (for a note) takes the keypad's place.
            .task {
                for await _ in NotificationCenter.default.notifications(named: UIResponder.keyboardWillShowNotification) {
                    session.dismiss()
                }
            }
    }
}

/// Digits, the separator, delete, − and + one step, Next and Done. Replaces
/// the system number pad, whose Done bar blocked taps across the screen.
struct SetKeypadView: View {
    let session: SetKeypadSession

    /// Keyboard grays: the panel, digit keys and function keys.
    private static let panel = UIColor { $0.userInterfaceStyle == .dark ? .systemGray6 : .systemGray5 }
    private static let digitKey = UIColor { $0.userInterfaceStyle == .dark ? .systemGray4 : .white }
    private static let functionKey = UIColor { $0.userInterfaceStyle == .dark ? .systemGray5 : .systemGray3 }

    var body: some View {
        Grid(horizontalSpacing: 6, verticalSpacing: 6) {
            GridRow {
                digits(1...3)
                key(.step(up: false), "−\u{2009}\(session.stepLabel)", id: "keypad.decrease",
                    label: "Decrease by \(session.stepLabel)", style: .function)
            }
            GridRow {
                digits(4...6)
                key(.step(up: true), "+\u{2009}\(session.stepLabel)", id: "keypad.increase",
                    label: "Increase by \(session.stepLabel)", style: .function)
            }
            GridRow {
                digits(7...9)
                if session.hasNext {
                    key(.next, "Next", systemImage: "arrow.right", id: "keypad.next", style: .accent)
                } else {
                    key(.done, "Done", id: "keypad.nextDone", style: .accent)
                }
            }
            GridRow {
                if let separator = session.separator {
                    key(.separator(separator), separator, id: "keypad.separator",
                        label: separator == ":" ? "Colon" : "Decimal point", style: .digit)
                } else {
                    // Reps have no separator. A key's height: unsized, the
                    // empty slot grew the keypad to the whole screen.
                    Color.clear
                        .frame(height: 50)
                        .accessibilityHidden(true)
                }
                digits(0...0)
                key(.delete, "Delete", systemImage: "delete.left", id: "keypad.delete", style: .function)
                    .simultaneousGesture(LongPressGesture(minimumDuration: 0.5).onEnded { _ in send(.clear) })
                // The same identifier as the old keyboard toolbar's Done.
                key(.done, "Done", systemImage: "keyboard.chevron.compact.down", id: "keyboard.done", style: .function)
            }
        }
        .padding(8)
        // Never taller than its keys.
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: .infinity)
        .background(Color(uiColor: Self.panel).ignoresSafeArea(edges: .bottom))
        .overlay(alignment: .top) { Divider() }
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
    }

    private enum Style { case digit, function, accent }

    private func digits(_ range: ClosedRange<Int>) -> some View {
        ForEach(Array(range), id: \.self) { digit in
            key(.digit(digit), "\(digit)", id: "keypad.key.\(digit)", style: .digit)
        }
    }

    private func key(_ key: SetKeypadKey, _ title: String, systemImage: String? = nil, id: String,
                     label: String? = nil, style: Style) -> some View {
        Button {
            send(key)
        } label: {
            Group {
                if let systemImage {
                    Image(systemName: systemImage)
                } else {
                    Text(title)
                        .monospacedDigit()
                }
            }
            .font(style == .digit ? .title2 : .body.weight(.semibold))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .foregroundStyle(style == .accent ? Color.accentForeground : Color.primary)
            .background(background(style), in: .rect(cornerRadius: 10))
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .frame(height: 50)
        .accessibilityLabel(label ?? title)
        .accessibilityIdentifier(id)
    }

    private func background(_ style: Style) -> Color {
        switch style {
        case .digit: Color(uiColor: Self.digitKey)
        case .function: Color(uiColor: Self.functionKey)
        case .accent: .accentColor
        }
    }

    private func send(_ key: SetKeypadKey) {
        session.press(key)
    }
}
