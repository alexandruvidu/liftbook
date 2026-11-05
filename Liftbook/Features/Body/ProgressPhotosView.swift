import PhotosUI
import SwiftData
import SwiftUI

/// A grid of progress photos by month. Photos stay on this iPhone.
struct ProgressPhotosView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ProgressPhoto.date, order: .reverse) private var photos: [ProgressPhoto]
    @State private var pickedItems: [PhotosPickerItem] = []
    @State private var isImporting = false

    private let store = PhotoStore.standard
    private let columns = [GridItem(.adaptive(minimum: 104), spacing: 4)]

    var body: some View {
        ScrollView {
            if photos.isEmpty {
                ContentUnavailableView {
                    Label("No progress photos", systemImage: "photo.on.rectangle")
                } description: {
                    Text("Add photos from your library to see how you change over time. They're stored only in Liftbook on this iPhone.")
                }
                .padding(.top, 60)
                .accessibilityIdentifier("photos.empty")
            }
            LazyVStack(alignment: .leading, spacing: 16) {
                ForEach(PhotoStore.months(of: photos), id: \.month) { group in
                    Text(group.month.formatted(.dateTime.month(.wide).year()))
                        .font(.headline)
                        .padding(.horizontal, 16)
                    LazyVGrid(columns: columns, spacing: 4) {
                        ForEach(group.photos) { photo in
                            NavigationLink {
                                ProgressPhotoDetailView(photo: photo)
                            } label: {
                                PhotoThumbnail(fileName: photo.fileName)
                            }
                            .accessibilityLabel("Photo from \(photo.date.formatted(date: .abbreviated, time: .omitted))")
                            .accessibilityIdentifier("photos.item")
                        }
                    }
                    .padding(.horizontal, 4)
                }
            }
            .padding(.vertical, 8)
        }
        .navigationTitle("Progress Photos")
        .overlay {
            if isImporting { ProgressView().controlSize(.large) }
        }
        .toolbar {
            PhotosPicker(selection: $pickedItems, maxSelectionCount: 10, matching: .images) {
                Label("Add Photos", systemImage: "plus")
            }
            .accessibilityIdentifier("photos.add")
        }
        .onChange(of: pickedItems) { _, items in
            guard !items.isEmpty else { return }
            Task { await importPhotos(items) }
        }
    }

    private func importPhotos(_ items: [PhotosPickerItem]) async {
        isImporting = true
        defer { isImporting = false; pickedItems = [] }
        for item in items {
            guard let data = try? await item.loadTransferable(type: Data.self),
                  let image = UIImage(data: data),
                  let fileName = try? store.save(image) else { continue }
            modelContext.insert(ProgressPhoto(date: .now, fileName: fileName))
        }
        try? modelContext.save()
    }
}

/// A square, cropped thumbnail loaded from the photo's file.
private struct PhotoThumbnail: View {
    let fileName: String
    @State private var image: UIImage?

    var body: some View {
        Color(.secondarySystemFill)
            .aspectRatio(1, contentMode: .fit)
            .overlay {
                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .task(id: fileName) {
                image = PhotoStore.standard.load(fileName)?.preparingThumbnail(of: CGSize(width: 300, height: 300))
            }
    }
}

/// One photo, full size, with its date and a delete button.
struct ProgressPhotoDetailView: View {
    @Bindable var photo: ProgressPhoto
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var isConfirmingDelete = false

    var body: some View {
        VStack(spacing: 16) {
            if let image = PhotoStore.standard.load(photo.fileName) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .accessibilityLabel("Progress photo")
                    .accessibilityIdentifier("photo.image")
            } else {
                ContentUnavailableView("Photo missing", systemImage: "photo")
            }
            DatePicker("Taken", selection: $photo.date, in: ...Date.now, displayedComponents: .date)
                .accessibilityIdentifier("photo.date")
            Spacer(minLength: 0)
        }
        .padding()
        .navigationTitle(photo.date.formatted(date: .abbreviated, time: .omitted))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            Button("Delete Photo", systemImage: "trash", role: .destructive) { isConfirmingDelete = true }
                .accessibilityIdentifier("photo.delete")
        }
        .confirmationDialog("Delete this photo?", isPresented: $isConfirmingDelete, titleVisibility: .visible) {
            Button("Delete Photo", role: .destructive) {
                let fileName = photo.fileName
                dismiss()
                let context = modelContext, photo = photo
                Task { @MainActor in
                    try? await Task.sleep(for: WorkoutStartController.transitionDelay)
                    PhotoStore.standard.delete(fileName)
                    context.delete(photo)
                    try? context.save()
                }
            }
            .accessibilityIdentifier("photo.confirmDelete")
        }
    }
}
