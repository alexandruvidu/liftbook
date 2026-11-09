import ImageIO
import SwiftUI
import UIKit

/// The picture bundled with the app for a catalog exercise (Resources/ExerciseArt,
/// added by CI): RepDB illustrations of the start and peak of the movement,
/// or, for the few exercises RepDB doesn't cover, an ExerciseDB animation.
enum ExerciseArt: Equatable {
    /// One or two illustrated poses. With a peak, the two cross-fade in a loop.
    case poses(start: URL, peak: URL?)
    /// A looping GIF.
    case animation(URL)

    /// The bundled folder of pictures, if the build has one.
    nonisolated static let bundledDirectory = Bundle.main.url(forResource: "ExerciseArt", withExtension: nil)

    static func of(_ exerciseID: String, in directory: URL? = bundledDirectory) -> ExerciseArt? {
        guard let directory else { return nil }
        func existing(_ name: String) -> URL? {
            let url = directory.appendingPathComponent(name)
            return FileManager.default.fileExists(atPath: url.path) ? url : nil
        }
        if let start = existing("\(exerciseID)-start.webp") {
            return .poses(start: start, peak: existing("\(exerciseID)-peak.webp"))
        }
        if let main = existing("\(exerciseID)-main.webp") {
            return .poses(start: main, peak: nil)
        }
        return existing("\(exerciseID).gif").map(ExerciseArt.animation)
    }

    /// A still picture for small places: the start pose, or the first frame.
    var still: UIImage? {
        switch self {
        case .poses(let start, _): ExerciseArtCache.image(start)
        case .animation(let url): ExerciseArtCache.firstFrame(url)
        }
    }
}

/// Decoded pictures, kept while memory allows.
enum ExerciseArtCache {
    private nonisolated(unsafe) static let images = NSCache<NSURL, UIImage>()
    private nonisolated(unsafe) static let animations = NSCache<NSURL, UIImage>()
    private nonisolated(unsafe) static let firstFrames = NSCache<NSURL, UIImage>()

    static func image(_ url: URL) -> UIImage? {
        cached(url, in: images) { UIImage(contentsOfFile: url.path) }
    }

    static func firstFrame(_ url: URL) -> UIImage? {
        cached(url, in: firstFrames) {
            guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
                  let frame = CGImageSourceCreateImageAtIndex(source, 0, nil) else { return nil }
            return UIImage(cgImage: frame)
        }
    }

    /// A GIF as one animated image.
    static func animated(_ url: URL) -> UIImage? {
        cached(url, in: animations) {
            guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else { return nil }
            var frames: [UIImage] = []
            var duration = 0.0
            for index in 0..<CGImageSourceGetCount(source) {
                guard let frame = CGImageSourceCreateImageAtIndex(source, index, nil) else { continue }
                frames.append(UIImage(cgImage: frame))
                duration += frameDuration(source, index)
            }
            guard !frames.isEmpty else { return nil }
            return frames.count == 1 ? frames[0] : UIImage.animatedImage(with: frames, duration: duration)
        }
    }

    private static func cached(_ url: URL, in cache: NSCache<NSURL, UIImage>, load: () -> UIImage?) -> UIImage? {
        if let image = cache.object(forKey: url as NSURL) { return image }
        let image = load()
        if let image { cache.setObject(image, forKey: url as NSURL) }
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

/// An exercise's bundled picture, moving: the two poses cross-fade back and
/// forth, or the GIF loops. Core Animation runs it, so SwiftUI never redraws.
struct ExerciseArtView: UIViewRepresentable {
    let art: ExerciseArt

    /// Seconds for one full start → peak → start cycle.
    static let cycle: CFTimeInterval = 2.6

    func makeUIView(context: Context) -> UIImageView {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        view.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        view.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        view.isAccessibilityElement = true
        view.accessibilityLabel = "Exercise animation"
        view.accessibilityTraits = .image
        switch art {
        case .animation(let url):
            view.image = ExerciseArtCache.animated(url)
        case .poses(let start, let peak):
            let first = ExerciseArtCache.image(start)
            view.image = first
            if let peak, let first = first?.cgImage, let second = ExerciseArtCache.image(peak)?.cgImage {
                // Hold each pose, then fade to the other.
                let fade = CAKeyframeAnimation(keyPath: "contents")
                fade.values = [first, first, second, second, first]
                fade.keyTimes = [0, 0.3, 0.5, 0.8, 1]
                fade.duration = Self.cycle
                fade.repeatCount = .infinity
                fade.isRemovedOnCompletion = false
                view.layer.add(fade, forKey: "poses")
            }
        }
        return view
    }

    func updateUIView(_ view: UIImageView, context: Context) {}
}
