import XCTest
@testable import IsletCore

final class StoreTests: XCTestCase {
    @MainActor func testDropAndConvert() async throws {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent("islet-store-" + UUID().uuidString)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let src = dir.appendingPathComponent("not.txt")
        try "selam".write(to: src, atomically: true, encoding: .utf8)
        let store = IslandStore(ffmpegAvailable: false)
        store.handleDrop(src)
        XCTAssertEqual(store.droppedFile, src)
        XCTAssertEqual(store.options.map(\.id), ["txt-pdf", "txt-docx", "txt-rtf", "txt-html", "txt-odt"])
        XCTAssertTrue(store.isExpanded)
        await store.convert(store.options[1])
        guard case .done(let out) = store.status else { return XCTFail("\(store.status)") }
        XCTAssertEqual(out.lastPathComponent, "not.docx")
        store.clearDrop()
        XCTAssertNil(store.droppedFile)
        XCTAssertEqual(store.options, [])
        XCTAssertEqual(store.status, .idle)
    }
    @MainActor func testUnknownDrop() {
        let store = IslandStore(ffmpegAvailable: false)
        store.handleDrop(URL(fileURLWithPath: "/tmp/a.xyz"))
        XCTAssertEqual(store.options, [])
        XCTAssertEqual(store.status, .failed("Bu dosya türü için dönüştürme yok: xyz"))
    }
}
