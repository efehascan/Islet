import XCTest
@testable import AdaCore

/// Gerçek dönüştürmeler: makinedeki textutil, cupsfilter, sips, afconvert, say ile.
final class ConverterTests: XCTestCase {
    var dir: URL!
    override func setUpWithError() throws {
        dir = FileManager.default.temporaryDirectory.appendingPathComponent("ada-" + UUID().uuidString)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    }
    func opt(_ url: URL, _ id: String) -> ConversionOption {
        ConversionCatalog.options(for: url, ffmpegAvailable: false).first { $0.id == id }!
    }
    func testTextToDocxAndPdf() async throws {
        let src = dir.appendingPathComponent("not.txt")
        try "Merhaba dünya".write(to: src, atomically: true, encoding: .utf8)
        let docx = try await Converter().convert(src, option: opt(src, "txt-docx"))
        XCTAssertEqual(docx.lastPathComponent, "not.docx")
        XCTAssert(FileManager.default.fileExists(atPath: docx.path))
        let pdf = try await Converter().convert(src, option: opt(src, "txt-pdf"))
        XCTAssertEqual(try Data(contentsOf: pdf).prefix(4), Data("%PDF".utf8))
    }
    func testMarkdownToHtml() async throws {
        let src = dir.appendingPathComponent("oku.md")
        try "# Başlık\n\nmetin".write(to: src, atomically: true, encoding: .utf8)
        let html = try await Converter().convert(src, option: opt(src, "md-html"))
        XCTAssert(try String(contentsOf: html, encoding: .utf8).contains("<h1>Başlık</h1>"))
    }
    func testImage() async throws {
        let src = dir.appendingPathComponent("r.png")
        let rep = NSBitmapImageRepFactory.png(width: 8, height: 8)
        try rep.write(to: src)
        let jpg = try await Converter().convert(src, option: opt(src, "png-jpeg"))
        XCTAssertEqual(jpg.pathExtension, "jpeg")
        XCTAssertEqual(try Data(contentsOf: jpg).prefix(2), Data([0xFF, 0xD8]))
    }
    func testAudio() async throws {
        let src = dir.appendingPathComponent("ses.aiff")
        let say = Process(); say.executableURL = URL(fileURLWithPath: "/usr/bin/say")
        say.arguments = ["-o", src.path, "merhaba"]; try say.run(); say.waitUntilExit()
        let wavSrc = dir.appendingPathComponent("ses.wav")
        let af = Process(); af.executableURL = URL(fileURLWithPath: "/usr/bin/afconvert")
        af.arguments = ["-f", "WAVE", "-d", "LEI16", src.path, wavSrc.path]; try af.run(); af.waitUntilExit()
        let m4a = try await Converter().convert(wavSrc, option: opt(wavSrc, "wav-m4a"))
        XCTAssertEqual(m4a.lastPathComponent, "ses.m4a")
        XCTAssert((try FileManager.default.attributesOfItem(atPath: m4a.path)[.size] as? Int ?? 0) > 100)
    }
    func testPdfToPngAndText() async throws {
        let txt = dir.appendingPathComponent("kaynak.txt")
        try String(repeating: "Merhaba\n", count: 120).write(to: txt, atomically: true, encoding: .utf8)
        let pdf = try await Converter().convert(txt, option: opt(txt, "txt-pdf"))
        let png = try await Converter().convert(pdf, option: opt(pdf, "pdf-png"))
        XCTAssertEqual(png.lastPathComponent, "kaynak (sayfa 1).png")
        XCTAssertEqual(try Data(contentsOf: png).prefix(4), Data([0x89, 0x50, 0x4E, 0x47]))
        let text = try await Converter().convert(pdf, option: opt(pdf, "pdf-txt"))
        XCTAssert(try String(contentsOf: text, encoding: .utf8).contains("Merhaba"))
    }
    func testUnsupported() async {
        let src = dir.appendingPathComponent("a.xyz")
        do {
            _ = try await Converter().convert(src, option: ConversionOption(id: "xyz-abc", title: "ABC", outputExtension: "abc", tool: .ffmpeg))
            XCTFail("hata bekleniyordu")
        } catch {}
    }
}

/// Test için küçük PNG üretir (AppKit'e bağımlı olmadan, ham PNG baytları).
enum NSBitmapImageRepFactory {
    struct PNG { let data: Data; func write(to url: URL) throws { try data.write(to: url) } }
    static func png(width: Int, height: Int) -> PNG {
        // 1x1 kırmızı PNG yeterli; boyut parametresi biçim için
        let b64 = "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8DwHwAFBQIAX8jx0gAAAABJRU5ErkJggg=="
        return PNG(data: Data(base64Encoded: b64)!)
    }
}
