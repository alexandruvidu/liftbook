import PhotosUI
import SwiftData
import SwiftUI
import UniformTypeIdentifiers

/// Adds the user's own photos or videos to an exercise, from the photo
/// library or (where the camera can be used) by taking one.
struct AddMediaButton: View {
    let exerciseID: String

    @Environment(\.modelContext) private var modelContext
    @Query private var media: [ExerciseMedia]
    @State private var items: [PhotosPickerItem] = []
    @State private var isPickingLibrary = false
    @State private var isUsingCamera = false
    @State private var failed = false

    init(exerciseID: String) {
        self.exerciseID = exerciseID
        _media = Query(filter: #Predicate<ExerciseMedia> { $0.exerciseID == exerciseID })
    }

    var body: some View {
        Menu {
            Button("Choose from Library", systemImage: "photo.on.rectangle") { isPickingLibrary = true }
            if CameraPicker.isAvailable {
                Button("Take Photo or Video", systemImage: "camera") { isUsingCamera = true }
            }
        } label: {
            // Icon only: adding your own media is occasional, not a main action.
            Label("Add Photo or Video", systemImage: "camera")
                .labelStyle(.iconOnly)
        }
        .accessibilityIdentifier("media.add")
        .photosPicker(isPresented: $isPickingLibrary, selection: $items, maxSelectionCount: 5,
                      matching: .any(of: [.images, .videos]))
        .fullScreenCover(isPresented: $isUsingCamera) {
            CameraPicker { result in
                isUsingCamera = false
                switch result {
                case .photo(let image): addPhoto(image)
                case .video(let url): addVideo(url)
                case nil: break
                }
            }
            .ignoresSafeArea()
        }
        .onChange(of: items) { _, picked in
            guard !picked.isEmpty else { return }
            items = []
            Task { await load(picked) }
        }
        .alert("Couldn't add that", isPresented: $failed) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("The photo or video couldn't be read. Try another one.")
        }
    }

    private func load(_ picked: [PhotosPickerItem]) async {
        for item in picked {
            if item.supportedContentTypes.contains(where: { $0.conforms(to: .movie) }),
               let video = try? await item.loadTransferable(type: PickedVideo.self) {
                addVideo(video.url)
            } else if let data = try? await item.loadTransferable(type: Data.self), let image = UIImage(data: data) {
                addPhoto(image)
            } else {
                failed = true
            }
        }
    }

    private var nextPosition: Int {
        (media.filter { $0.source == .own }.map(\.position).max() ?? -1) + 1
    }

    private func addPhoto(_ image: UIImage) {
        guard let name = try? MediaStore.standard.savePhoto(image) else { return failed = true }
        insert(.photo, name)
    }

    private func addVideo(_ url: URL) {
        guard let name = try? MediaStore.standard.saveVideo(from: url) else { return failed = true }
        insert(.video, name)
    }

    private func insert(_ kind: MediaKind, _ fileName: String) {
        modelContext.insert(ExerciseMedia(exerciseID: exerciseID, kind: kind, source: .own,
                                          fileName: fileName, position: nextPosition))
        try? modelContext.save()
    }
}

/// A video from the photo picker, copied to a temporary file we own.
struct PickedVideo: Transferable {
    let url: URL

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(contentType: .movie) { video in
            SentTransferredFile(video.url)
        } importing: { received in
            let copy = URL.temporaryDirectory.appending(path: "\(UUID().uuidString).\(received.file.pathExtension)")
            try FileManager.default.copyItem(at: received.file, to: copy)
            return PickedVideo(url: copy)
        }
    }
}

/// The system camera for one photo or video.
struct CameraPicker: UIViewControllerRepresentable {
    enum Result {
        case photo(UIImage)
        case video(URL)
    }

    let onFinish: (Result?) -> Void

    static var isAvailable: Bool { UIImagePickerController.isSourceTypeAvailable(.camera) }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.mediaTypes = [UTType.image.identifier, UTType.movie.identifier]
        picker.videoMaximumDuration = 60
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ controller: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(onFinish: onFinish) }

    @MainActor
    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let onFinish: (Result?) -> Void

        init(onFinish: @escaping (Result?) -> Void) {
            self.onFinish = onFinish
        }

        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let url = info[.mediaURL] as? URL {
                onFinish(.video(url))
            } else if let image = info[.originalImage] as? UIImage {
                onFinish(.photo(image))
            } else {
                onFinish(nil)
            }
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            onFinish(nil)
        }
    }
}
