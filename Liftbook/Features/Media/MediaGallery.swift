import SwiftUI

/// An exercise's photos and videos, one page each. Two downloaded photos
/// (start and end position) alternate on a single page like a short clip.
struct MediaGallery: View {
    let media: [ExerciseMedia]
    var store: MediaStore = .standard

    var body: some View {
        let pages = Self.pages(for: media)
        TabView {
            ForEach(pages, id: \.first!.mediaID) { page in
                pageView(page)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: pages.count > 1 ? .always : .never))
        .aspectRatio(4 / 3, contentMode: .fit)
        .background(Color(.tertiarySystemFill))
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("media.gallery")
    }

    /// Own media one per page; downloaded photos together on one page.
    static func pages(for media: [ExerciseMedia]) -> [[ExerciseMedia]] {
        let own = media.filter { $0.source == .own }.map { [$0] }
        let downloaded = media.filter { $0.source == .downloaded && $0.kind == .photo }
        return own + (downloaded.isEmpty ? [] : [downloaded])
    }

    @ViewBuilder
    private func pageView(_ page: [ExerciseMedia]) -> some View {
        if page.count > 1 {
            TimelineView(.periodic(from: .now, by: 1.2)) { context in
                let index = Int(context.date.timeIntervalSinceReferenceDate / 1.2) % page.count
                photo(page[index])
            }
        } else if let item = page.first {
            switch item.kind {
            case .photo: photo(item)
            case .video: LoopingVideoPlayer(url: store.url(for: item.fileName))
            }
        }
    }

    private func photo(_ item: ExerciseMedia) -> some View {
        Color.clear
            .overlay {
                if let image = store.loadImage(item.fileName) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                }
            }
            .clipped()
            .accessibilityElement()
            .accessibilityLabel("Exercise photo")
            .accessibilityAddTraits(.isImage)
    }
}
