import Foundation
/// Görev: Spotify ve Müzik'ten şu an çalan parçayı AppleScript ile oku, komut gönder (şu an yer tutucu).
public final class NowPlayingProvider {
    public init() {}
    /// Önce Spotify, sonra Music; çalışan uygulama yoksa ya da çalmıyorsa nil.
    public func current() -> NowPlayingInfo? { nil }
    public func send(_ command: MediaCommand, to app: String) {}
    /// AppleScript çıktısını ayrıştırır. Biçim: alanlar "||" ile ayrılmış tek satır:
    /// state||title||artist||album||artworkURL||positionSaniye||durationSaniye
    public static func parse(_ raw: String, app: String) -> NowPlayingInfo? { nil }
}
