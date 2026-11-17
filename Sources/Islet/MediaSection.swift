import SwiftUI
import IsletCore

/// Görev: MediaSection (şu an yer tutucu).
struct MediaSection: View {
    let store: IslandStore
    var body: some View {
        if let media = store.media {
            playingRow(media)
        } else {
            emptyRow
        }
    }

    private var emptyRow: some View {
        HStack(spacing: 8) {
            Image(systemName: "music.note")
            Text("Çalan bir şey yok")
        }
        .foregroundStyle(Theme.secondary)
        .font(.system(size: 12))
    }

    @ViewBuilder
    private func playingRow(_ media: NowPlayingInfo) -> some View {
        HStack(spacing: 12) {
            artwork(for: media)

            VStack(alignment: .leading, spacing: 2) {
                Text(media.title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Theme.text)
                    .lineLimit(1)
                Text(media.artist)
                    .font(.system(size: 11.5))
                    .foregroundStyle(Theme.secondary)
                    .lineLimit(1)
                if media.duration > 0 {
                    progress(for: media)
                }
            }

            Spacer()

            controls
        }
    }

    private func artwork(for media: NowPlayingInfo) -> some View {
        AsyncImage(url: media.artworkURL) { image in
            image.resizable().scaledToFill()
        } placeholder: {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white.opacity(0.12))
                .overlay(
                    Image(systemName: "music.note")
                        .foregroundStyle(Theme.secondary)
                )
        }
        .frame(width: 44, height: 44)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func progress(for media: NowPlayingInfo) -> some View {
        let fraction = min(media.position / media.duration, 1)
        return ProgressView(value: fraction)
            .progressViewStyle(.linear)
            .tint(Theme.accent)
    }

    private var controls: some View {
        HStack(spacing: 14) {
            Button {
                store.sendMedia(.previous)
            } label: {
                Image(systemName: "backward.fill")
            }

            Button {
                store.sendMedia(.playPause)
            } label: {
                Image(systemName: store.media?.isPlaying == true ? "pause.fill" : "play.fill")
            }

            Button {
                store.sendMedia(.next)
            } label: {
                Image(systemName: "forward.fill")
            }
        }
        .buttonStyle(.plain)
        .font(.system(size: 15))
        .foregroundStyle(Theme.text)
    }
}
