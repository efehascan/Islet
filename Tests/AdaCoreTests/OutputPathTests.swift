import XCTest
@testable import AdaCore

final class OutputPathTests: XCTestCase {
    func testUnique() throws {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let src = dir.appendingPathComponent("Rapor.docx")
        XCTAssertEqual(OutputPath.make(for: src, ext: "pdf").lastPathComponent, "Rapor.pdf")
        FileManager.default.createFile(atPath: dir.appendingPathComponent("Rapor.pdf").path, contents: Data())
        XCTAssertEqual(OutputPath.make(for: src, ext: "pdf").lastPathComponent, "Rapor (1).pdf")
        FileManager.default.createFile(atPath: dir.appendingPathComponent("Rapor (1).pdf").path, contents: Data())
        XCTAssertEqual(OutputPath.make(for: src, ext: "pdf").lastPathComponent, "Rapor (2).pdf")
        XCTAssertEqual(OutputPath.make(for: src, ext: "pdf").deletingLastPathComponent().path, dir.path)
    }
}
