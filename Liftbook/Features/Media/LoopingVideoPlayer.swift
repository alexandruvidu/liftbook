import AVFoundation
import SwiftUI

/// A video that plays muted on a loop; tap to turn the sound on or off.
struct LoopingVideoPlayer: View {
    let url: URL
    @State private var player = AVQueuePlayer()
    @State private var looper: AVPlayerLooper?
    @State private var isMuted = true

    var body: some View {
        PlayerLayerView(player: player)
            .overlay(alignment: .bottomTrailing) {
                Image(systemName: isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(8)
                    .background(.black.opacity(0.45), in: Circle())
                    .padding(10)
                    .accessibilityHidden(true)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                isMuted.toggle()
                player.isMuted = isMuted
            }
            .accessibilityElement()
            .accessibilityLabel("Exercise video")
            .accessibilityHint(isMuted ? "Turns the sound on" : "Turns the sound off")
            .accessibilityAddTraits(.isButton)
            .onAppear {
                player.isMuted = isMuted
                looper = AVPlayerLooper(player: player, templateItem: AVPlayerItem(url: url))
                player.play()
            }
            .onDisappear {
                player.pause()
                looper = nil
            }
    }
}

/// Hosts an AVPlayerLayer filling its bounds.
private struct PlayerLayerView: UIViewRepresentable {
    let player: AVPlayer

    func makeUIView(context: Context) -> PlayerUIView {
        let view = PlayerUIView()
        view.playerLayer.player = player
        view.playerLayer.videoGravity = .resizeAspectFill
        return view
    }

    func updateUIView(_ view: PlayerUIView, context: Context) {
        view.playerLayer.player = player
    }

    final class PlayerUIView: UIView {
        override class var layerClass: AnyClass { AVPlayerLayer.self }
        var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }
    }
}
