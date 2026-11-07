import ImageIO
import SwiftUI
import UIKit

/// The animations bundled with the app (Resources/ExerciseGIFs, added by CI),
/// one GIF per catalog exercise that has one.
enum ExerciseAnimation {
    static func url(for exerciseID: String, in bundle: Bundle = .main) -> URL? {
        bundle.url(forResource: exerciseID, withExtension: "gif", subdirectory: "ExerciseGIFs")
    }

    private nonisolated(unsafe) static let cache = NSCache<NSURL, UIImage>()
    private nonisolated(unsafe) static let firstFrames = NSCache<NSURL, UIImage>()

    /// The whole animation as one animated image.
    static func animated(_ url: URL) -> UIImage? {
        if let cached = cache.object(forKey: url as NSURL) { return cached }
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else { return nil }
        var frames: [UIImage] = []
        var duration = 0.0
        for index in 0..<CGImageSourceGetCount(source) {
            guard let frame = CGImageSourceCreateImageAtIndex(source, index, nil) else { continue }
            frames.append(UIImage(cgImage: frame))
            duration += frameDuration(source, index)
        }
        guard !frames.isEmpty else { return nil }
        let image = frames.count == 1 ? frames[0] : UIImage.animatedImage(with: frames, duration: duration)
        if let image { cache.setObject(image, forKey: url as NSURL) }
        return image
    }

    /// The first frame, for small pictures that don't animate.
    static func firstFrame(_ url: URL) -> UIImage? {
        if let cached = firstFrames.object(forKey: url as NSURL) { return cached }
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
              let frame = CGImageSourceCreateImageAtIndex(source, 0, nil) else { return nil }
        let image = UIImage(cgImage: frame)
        firstFrames.setObject(image, forKey: url as NSURL)
        return image
    }

    private static func frameDuration(_ source: CGImageSource, _ index: Int) -> Double {
        let properties = CGImageSourceCopyPropertiesAtIndex(source, index, nil) as? [CFString: Any]
        let gif = properties?[kCGImagePropertyGIFDictionary] as? [CFString: Any]
        let delay = (gif?[kCGImagePropertyGIFUnclampedDelayTime] as? Double)
            ?? (gif?[kCGImagePropertyGIFDelayTime] as? Double) ?? 0.1
        return delay < 0.02 ? 0.1 : delay
    }
}

/// A looping exercise animation.
struct AnimatedExerciseView: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> UIImageView {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        view.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        view.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        view.isAccessibilityElement = true
        view.accessibilityLabel = "Exercise animation"
        view.accessibilityTraits = .image
        view.image = ExerciseAnimation.animated(url)
        return view
    }

    func updateUIView(_ view: UIImageView, context: Context) {}
}
