import Foundation
/// Görev: Spotify ve Müzik'ten şu an çalan parçayı AppleScript ile oku, komut gönder.
public final class NowPlayingProvider {
    public init() {}

    /// Önce Spotify, sonra Music; çalışan uygulama yoksa ya da çalmıyorsa nil.
    public func current() -> NowPlayingInfo? {
        for app in ["Spotify", "Music"] {
            if let info = runScript(for: app) {
                return info
            }
        }
        return nil
    }

    public func send(_ command: MediaCommand, to app: String) {
        let action: String
        switch command {
        case .playPause: action = "playpause"
        case .next: action = "next track"
        case .previous: action = "previous track"
        }
        let source = "tell application \"\(app)\" to \(action)"
        let script = NSAppleScript(source: source)
        var err: NSDictionary?
        script?.executeAndReturnError(&err)
    }

    /// AppleScript çıktısını ayrıştırır. Biçim: alanlar "||" ile ayrılmış tek satır:
    /// state||title||artist||album||artworkURL||positionSaniye||durationSaniye
    public static func parse(_ raw: String, app: String) -> NowPlayingInfo? {
        let fields = raw.components(separatedBy: "||")
        guard fields.count == 7 else { return nil }

        let state = fields[0]
        let isPlaying: Bool
        switch state {
        case "playing": isPlaying = true
        case "paused": isPlaying = false
        default: return nil
        }

        let title = fields[1]
        let artist = fields[2]
        let album = fields[3]
        let artwork = fields[4]
        let position = NowPlayingProvider.parseDouble(fields[5])
        var duration = NowPlayingProvider.parseDouble(fields[6])

        guard !title.isEmpty else { return nil }
        let artworkURL = artwork.isEmpty ? nil : URL(string: artwork)

        if app == "Spotify", duration > 1000 {
            duration /= 1000
        }

        return NowPlayingInfo(app: app, title: title, artist: artist, album: album,
                              isPlaying: isPlaying, artworkURL: artworkURL,
                              position: position, duration: duration)
    }

    private func runScript(for app: String) -> NowPlayingInfo? {
        let artwork = app == "Spotify" ? "set aw to artwork url of t" : ""
        let source = """
        if application "\(app)" is running then
        tell application "\(app)"
        if player state is stopped then return ""
        set t to current track
        set st to (player state as string)
        set aw to ""
        \(artwork)
        return st & "||" & (name of t) & "||" & (artist of t) & "||" & (album of t) & "||" & aw & "||" & (player position as string) & "||" & (duration of t as string)
        end tell
        end if
        return ""
        """
        let script = NSAppleScript(source: source)
        var err: NSDictionary?
        guard let result = script?.executeAndReturnError(&err), err == nil else { return nil }
        let raw = result.stringValue ?? ""
        guard !raw.isEmpty else { return nil }
        return NowPlayingProvider.parse(raw, app: app)
    }

    /// AppleScript ondalık virgülle dönebilir (","); onu noktaya çevirip Double alır.
    private static func parseDouble(_ raw: String) -> Double {
        let normalized = raw.trimmingCharacters(in: .whitespaces)
            .replacingOccurrences(of: ",", with: ".")
        guard !normalized.isEmpty else { return 0 }
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.usesGroupingSeparator = false
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.number(from: normalized)?.doubleValue ?? 0
    }
}
