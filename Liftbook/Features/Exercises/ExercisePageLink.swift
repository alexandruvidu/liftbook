import SwiftUI

/// A navigation value that opens an exercise's page. Stacks that show
/// exercises register it with `exercisePageDestination()`.
struct ExercisePageLink: Hashable {
    let exerciseID: String
}

extension View {
    func exercisePageDestination() -> some View {
        navigationDestination(for: ExercisePageLink.self) { ExerciseDetailView(exerciseID: $0.exerciseID) }
    }

    /// Lets views inside open exercise pages from code (e.g. a menu item) by
    /// appending to the stack's `path`; pair with `exercisePageDestination()`.
    func opensExercisePages(on path: Binding<NavigationPath>) -> some View {
        environment(\.openExercisePage, OpenExercisePage { path.wrappedValue.append(ExercisePageLink(exerciseID: $0)) })
    }
}

/// Pushes an exercise's page onto the enclosing stack (see `opensExercisePages(on:)`).
struct OpenExercisePage {
    let action: (String) -> Void

    func callAsFunction(_ exerciseID: String) {
        action(exerciseID)
    }
}

extension EnvironmentValues {
    @Entry var openExercisePage: OpenExercisePage?
}

/// An exercise's picture and name that open its page, with a line below.
struct ExerciseHeaderLink: View {
    let exerciseID: String
    let name: String
    var subtitle: String?
    var equipment: Equipment = .other
    var machinePhoto: String?
    var thumbnailSize: CGFloat = 44
    /// A `List` row draws its own disclosure chevron.
    var inList = false
    let identifier: String

    var body: some View {
        NavigationLink(value: ExercisePageLink(exerciseID: exerciseID)) {
            HStack(spacing: 12) {
                ExerciseThumbnail(exerciseID: exerciseID, equipment: equipment,
                                  machinePhoto: machinePhoto, size: thumbnailSize)
                VStack(alignment: .leading, spacing: 2) {
                    Text(name)
                        .font(.headline)
                        .foregroundStyle(.tint)
                        .multilineTextAlignment(.leading)
                    if let subtitle {
                        Text(subtitle)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.leading)
                    }
                }
                Spacer(minLength: 4)
                if !inList {
                    Image(systemName: "chevron.right")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.tertiary)
                        .accessibilityHidden(true)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityHint("Opens the exercise page")
        .accessibilityIdentifier(identifier)
    }
}
