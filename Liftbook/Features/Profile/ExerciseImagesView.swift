import SwiftData
import SwiftUI

/// Downloads exercise photos from the open free-exercise-db project onto the
/// phone, or removes them again.
struct ExerciseImagesView: View {
    var library: ExerciseLibrary = .bundled
    @Environment(\.modelContext) private var modelContext
    @Query private var customExercises: [CustomExercise]
    @Query(filter: #Predicate<ExerciseMedia> { $0.sourceID == "downloaded" }) private var downloaded: [ExerciseMedia]
    @State private var downloader = ImageDownloader()
    @State private var isConfirmingRemove = false

    var body: some View {
        let withImages = Set(downloaded.map(\.exerciseID)).count
        ScrollView {
            VStack(spacing: 12) {
                Block {
                    BlockHeader("Exercise photos", subtitle: "\(withImages) exercises have photos",
                                image: Image(systemName: "photo.stack"))
                    Text("Photos come from free-exercise-db, an open exercise dataset on GitHub. They're downloaded straight to this phone and kept for offline use; nothing is uploaded. Photos you add yourself always show first.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    if downloader.isRunning {
                        ProgressView(value: downloader.progress)
                            .accessibilityIdentifier("images.progress")
                    }
                    if let error = downloader.error {
                        Label(error, systemImage: "exclamationmark.triangle")
                            .font(.subheadline)
                            .foregroundStyle(.orange)
                            .accessibilityIdentifier("images.error")
                    }
                    Button {
                        Task {
                            await downloader.run(context: modelContext,
                                                 catalog: library.exercises + customExercises.map(\.asLibraryExercise))
                        }
                    } label: {
                        Label(withImages == 0 ? "Download Photos" : "Download Missing Photos", systemImage: "arrow.down.circle")
                            .frame(maxWidth: .infinity, minHeight: 36)
                    }
                    .buttonStyle(.pillProminent)
                    .disabled(downloader.isRunning)
                    .accessibilityIdentifier("images.download")
                }

                if withImages > 0 {
                    Button("Remove Downloaded Photos", role: .destructive) { isConfirmingRemove = true }
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .accessibilityIdentifier("images.remove")
                }
            }
            .padding(16)
        }
        .blockScreenBackground()
        .navigationTitle("Exercise Images")
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog("Remove downloaded photos?", isPresented: $isConfirmingRemove, titleVisibility: .visible) {
            Button("Remove Photos", role: .destructive) { downloader.removeAll(context: modelContext) }
        } message: {
            Text("Your own photos and videos stay.")
        }
    }
}
