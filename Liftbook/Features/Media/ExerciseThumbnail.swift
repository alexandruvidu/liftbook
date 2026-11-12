import AVFoundation
import SwiftData
import SwiftUI

/// A small square picture for an exercise: its machine's photo, else its
/// first photo or video frame, else its bundled picture, else a symbol for its equipment.
struct ExerciseThumbnail: View {
    let exerciseID: String
    let equipment: Equipment
    /// The photo of the machine in use, which wins over the exercise's own.
    var machinePhoto: String?
    var size: CGFloat = 48

    @Query private var media: [ExerciseMedia]

    init(exerciseID: String, equipment: Equipment, machinePhoto: String? = nil, size: CGFloat = 48) {
        self.exerciseID = exerciseID
        self.equipment = equipment
        self.machinePhoto = machinePhoto
        self.size = size
        _media = Query(filter: #Predicate<ExerciseMedia> { $0.exerciseID == exerciseID })
    }

    var body: some View {
        Color(.tertiarySystemFill)
            .overlay {
                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                } else {
                    Image(systemName: equipment.symbolName)
                        .font(size > 60 ? .largeTitle : .title3)
                        .foregroundStyle(.tint)
                }
            }
            .frame(width: size, height: size)
            .clipShape(RoundedRectangle(cornerRadius: size / 4))
            .accessibilityHidden(true)
    }

    private var image: UIImage? {
        if let machinePhoto, let photo = PhotoStore.machines.load(machinePhoto) { return photo }
        guard let first = media.display(for: exerciseID).first else {
            return ExerciseArt.of(exerciseID)?.still
        }
        switch first.kind {
        case .photo: return MediaStore.standard.loadImage(first.fileName)
        case .video: return Self.frame(of: MediaStore.standard.url(for: first.fileName))
        }
    }

    /// The first frame of a video, small; nil until it has loaded, then the
    /// view showing it redraws on its own.
    @MainActor
    static func frame(of url: URL) -> UIImage? {
        VideoFrames.shared.frame(of: url)
    }
}

/// First frames of videos, read in the background and kept for reuse.
@MainActor
@Observable
final class VideoFrames {
    static let shared = VideoFrames()

    private var frames: [URL: UIImage] = [:]
    @ObservationIgnored private var loading: Set<URL> = []

    /// The cached frame, or nil while it loads (reading it updates views).
    func frame(of url: URL) -> UIImage? {
        if let frame = frames[url] { return frame }
        guard !loading.contains(url) else { return nil }
        loading.insert(url)
        Task {
            let generator = AVAssetImageGenerator(asset: AVURLAsset(url: url))
            generator.appliesPreferredTrackTransform = true
            generator.maximumSize = CGSize(width: 300, height: 300)
            if let image = try? await generator.image(at: .zero).image {
                frames[url] = UIImage(cgImage: image)
            }
            loading.remove(url)
        }
        return nil
    }
}
