import XCTest
@testable import IsletCore

final class CatalogTests: XCTestCase {
    func ids(_ name: String, ffmpeg: Bool = false) -> [String] {
        ConversionCatalog.options(for: URL(fileURLWithPath: "/tmp/" + name), ffmpegAvailable: ffmpeg).map(\.id)
    }
    func testKinds() {
        XCTAssertEqual(ConversionCatalog.kind(forExtension: "DOCX"), .document)
        XCTAssertEqual(ConversionCatalog.kind(forExtension: "pdf"), .pdf)
        XCTAssertEqual(ConversionCatalog.kind(forExtension: "md"), .markdown)
        XCTAssertEqual(ConversionCatalog.kind(forExtension: "heic"), .image)
        XCTAssertEqual(ConversionCatalog.kind(forExtension: "mp3"), .audio)
        XCTAssertEqual(ConversionCatalog.kind(forExtension: "mov"), .video)
        XCTAssertEqual(ConversionCatalog.kind(forExtension: "xyz"), .unknown)
    }
    func testDocument() {
        XCTAssertEqual(ids("a.docx"), ["docx-pdf", "docx-txt", "docx-rtf", "docx-html", "docx-odt"])
        XCTAssertEqual(ids("a.txt"), ["txt-pdf", "txt-docx", "txt-rtf", "txt-html", "txt-odt"])
    }
    func testPdfMarkdown() {
        XCTAssertEqual(ids("a.pdf"), ["pdf-txt", "pdf-png"])
        XCTAssertEqual(ids("a.md"), ["md-html", "md-pdf", "md-docx"])
    }
    func testImage() {
        XCTAssertEqual(ids("a.png"), ["png-jpeg", "png-heic", "png-tiff", "png-pdf"])
        XCTAssertEqual(ids("a.jpg"), ["jpg-png", "jpg-heic", "jpg-tiff", "jpg-pdf"])
    }
    func testAudio() {
        XCTAssertEqual(ids("a.wav"), ["wav-m4a", "wav-aiff", "wav-caf", "wav-flac"])
        XCTAssertEqual(ids("a.mp3"), ["mp3-m4a", "mp3-wav", "mp3-aiff", "mp3-caf", "mp3-flac"])
        XCTAssertEqual(ids("a.wav", ffmpeg: true), ["wav-m4a", "wav-aiff", "wav-caf", "wav-flac", "wav-mp3"])
    }
    func testVideoUnknown() {
        XCTAssertEqual(ids("a.mov"), ["mov-mp4", "mov-m4a"])
        XCTAssertEqual(ids("a.xyz"), [])
    }
    func testOptionFields() {
        let o = ConversionCatalog.options(for: URL(fileURLWithPath: "/tmp/a.docx"), ffmpegAvailable: false)[0]
        XCTAssertEqual(o, ConversionOption(id: "docx-pdf", title: "PDF", outputExtension: "pdf", tool: .cupsfilter))
    }
}
