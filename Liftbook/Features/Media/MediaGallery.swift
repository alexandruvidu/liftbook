import SwiftUI

/// An exercise's own photos and videos, one page each, then its bundled
/// picture (if it has one) on the last page.
struct MediaGallery: View {
    let media: [ExerciseMedia]
    /// The bundled picture, if any.
    var art: ExerciseArt?
    var store: MediaStore = .standard

    var body: some View {
        let pages = Self.pages(for: media)
        let count = pages.count + (art == nil ? 0 : 1)
        TabView {
            ForEach(pages, id: \.mediaID) { item in
                pageView(item)
            }
            if let art {
                ExerciseArtView(art: art)
                    .background(Color.white)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: count > 1 ? .always : .never))
        .aspectRatio(4 / 3, contentMode: .fit)
        .background(Color(.tertiarySystemFill))
        .clipShape(.card)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("media.gallery")
    }

    /// Own media first, then downloaded photos, one per page. Swiped by hand
    /// rather than cycled on a timer: a periodic re-render closes open menus.
    static func pages(for media: [ExerciseMedia]) -> [ExerciseMedia] {
        let own = media.filter { $0.source == .own }
        let downloaded = media.filter { $0.source == .downloaded && $0.kind == .photo }
        return own + downloaded
    }

    @ViewBuilder
    private func pageView(_ item: ExerciseMedia) -> some View {
        switch item.kind {
        case .photo: photo(item)
        case .video: LoopingVideoPlayer(url: store.url(for: item.fileName))
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
