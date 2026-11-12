import SwiftUI

/// An exercise in the library grid: its picture, name, muscle and equipment.
struct ExerciseCard: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dynamicTypeSize) private var typeSize
    let exercise: LibraryExercise
    /// The first photo or video to show, if any.
    let cover: ExerciseMedia?
    let machineCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Color(.tertiarySystemFill)
                .frame(height: 132)
                .overlay { picture }
                .clipped()
                .overlay(alignment: .bottomLeading) {
                    if machineCount > 1 {
                        Text("\(machineCount) machines")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(.black.opacity(0.6), in: Capsule())
                            .padding(8)
                    }
                }
                .overlay(alignment: .topTrailing) {
                    if exercise.isCustom {
                        Text("Custom")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(Color.accentForeground)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.accentColor, in: Capsule())
                            .padding(8)
                    }
                }
            VStack(alignment: .leading, spacing: 2) {
                Text(exercise.name)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Color.primary)
                    .lineLimit(typeSize.isAccessibilitySize ? 5 : 2, reservesSpace: !typeSize.isAccessibilitySize)
                    .multilineTextAlignment(.leading)
                Text("\(exercise.primaryMuscles.first?.displayName ?? "Full body") · \(exercise.equipment.displayName)")
                    .font(.caption)
                    .foregroundStyle(Color.secondary)
                    .lineLimit(typeSize.isAccessibilitySize ? 3 : 1)
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(.card)
        .contentShape(.card)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(exercise.name), \(exercise.summary)")
    }

    @ViewBuilder
    private var picture: some View {
        if let cover, let image = cover.kind == .photo
            ? MediaStore.standard.loadImage(cover.fileName)
            : ExerciseThumbnail.frame(of: MediaStore.standard.url(for: cover.fileName)) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
        } else if let frame = ExerciseArt.of(exercise.id)?.still {
            // Bundled pictures are square with a plain background; show them whole.
            Color.white.overlay {
                Image(uiImage: frame)
                    .resizable()
                    .scaledToFit()
            }
            // Dimmed in dark mode so the white tile doesn't glare.
            .brightness(colorScheme == .dark ? -0.14 : 0)
        } else {
            Image(systemName: exercise.equipment.symbolName)
                .font(.largeTitle)
                .foregroundStyle(.tint)
        }
    }
}
