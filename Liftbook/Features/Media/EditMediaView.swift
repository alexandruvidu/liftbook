import SwiftData
import SwiftUI

/// Reorders and deletes the user's own photos and videos for an exercise.
struct EditMediaView: View {
    let exerciseID: String
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var media: [ExerciseMedia]

    init(exerciseID: String) {
        self.exerciseID = exerciseID
        _media = Query(filter: #Predicate<ExerciseMedia> { $0.exerciseID == exerciseID }, sort: \ExerciseMedia.position)
    }

    var body: some View {
        let own = media.filter { $0.source == .own }
        NavigationStack {
            List {
                ForEach(own) { item in
                    HStack(spacing: 12) {
                        thumbnail(item)
                        Text(item.kind == .video ? "Video" : "Photo")
                        Spacer()
                        Text(item.createdAt.formatted(date: .abbreviated, time: .omitted))
                            .foregroundStyle(.secondary)
                    }
                }
                .onMove { from, to in
                    var ordered = own
                    ordered.move(fromOffsets: from, toOffset: to)
                    for (index, item) in ordered.enumerated() { item.position = index }
                    try? modelContext.save()
                }
                .onDelete { offsets in
                    for index in offsets {
                        MediaStore.standard.delete(own[index].fileName)
                        modelContext.delete(own[index])
                    }
                    try? modelContext.save()
                }
            }
            .environment(\.editMode, .constant(.active))
            .navigationTitle("Your Photos and Videos")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .accessibilityIdentifier("media.editDone")
                }
            }
        }
    }

    private func thumbnail(_ item: ExerciseMedia) -> some View {
        let image = item.kind == .photo
            ? MediaStore.standard.loadImage(item.fileName)
            : ExerciseThumbnail.frame(of: MediaStore.standard.url(for: item.fileName))
        return Color(.tertiarySystemFill)
            .overlay {
                if let image {
                    Image(uiImage: image).resizable().scaledToFill()
                }
            }
            .frame(width: 56, height: 56)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .accessibilityHidden(true)
    }
}
