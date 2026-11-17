import XCTest
@testable import IsletCore

final class NowPlayingTests: XCTestCase {
    func testParsePlaying() {
        let i = NowPlayingProvider.parse("playing||Yalnızlık||Sezen Aksu||Albüm||https://i.scdn.co/image/abc||12.5||215", app: "Spotify")
        XCTAssertEqual(i, NowPlayingInfo(app: "Spotify", title: "Yalnızlık", artist: "Sezen Aksu", album: "Albüm", isPlaying: true,
                                         artworkURL: URL(string: "https://i.scdn.co/image/abc"), position: 12.5, duration: 215))
    }
    func testParsePausedNoArtwork() {
        let i = NowPlayingProvider.parse("paused||A||B||||||0||180", app: "Music")
        XCTAssertEqual(i?.isPlaying, false)
        XCTAssertNil(i?.artworkURL)
        XCTAssertEqual(i?.duration, 180)
    }
    func testSpotifyMillisecondsDuration() {
        // Spotify süreyi milisaniye verir: 1000'den büyük süre saniyeye çevrilir
        XCTAssertEqual(NowPlayingProvider.parse("playing||A||B||C||||1||215000", app: "Spotify")?.duration, 215)
    }
    func testParseInvalid() {
        XCTAssertNil(NowPlayingProvider.parse("", app: "Spotify"))
        XCTAssertNil(NowPlayingProvider.parse("stopped||||||||||0||0", app: "Spotify"))
        XCTAssertNil(NowPlayingProvider.parse("playing||eksik", app: "Spotify"))
    }
}
