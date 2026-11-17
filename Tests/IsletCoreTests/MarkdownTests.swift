import XCTest
@testable import IsletCore

final class MarkdownTests: XCTestCase {
    func body(_ md: String) -> String {
        let h = Markdown.html(md)
        guard let s = h.range(of: "<body>"), let e = h.range(of: "</body>") else { return "" }
        return String(h[s.upperBound..<e.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
    }
    func testDocument() {
        let h = Markdown.html("# A", title: "Not")
        XCTAssert(h.hasPrefix("<!doctype html>"))
        XCTAssert(h.contains("<meta charset=\"utf-8\">"))
        XCTAssert(h.contains("<title>Not</title>"))
    }
    func testHeadingsAndParagraph() {
        XCTAssertEqual(body("# Başlık"), "<h1>Başlık</h1>")
        XCTAssertEqual(body("### Üç"), "<h3>Üç</h3>")
        XCTAssertEqual(body("Bir satır\nikinci satır"), "<p>Bir satır ikinci satır</p>")
        XCTAssertEqual(body("A\n\nB"), "<p>A</p>\n<p>B</p>")
    }
    func testInline() {
        XCTAssertEqual(body("**kalın** ve *eğik* ve `kod`"), "<p><strong>kalın</strong> ve <em>eğik</em> ve <code>kod</code></p>")
        XCTAssertEqual(body("[site](https://x.com)"), "<p><a href=\"https://x.com\">site</a></p>")
        XCTAssertEqual(body("a < b & c"), "<p>a &lt; b &amp; c</p>")
    }
    func testLists() {
        XCTAssertEqual(body("- bir\n- iki"), "<ul>\n<li>bir</li>\n<li>iki</li>\n</ul>")
        XCTAssertEqual(body("1. bir\n2. iki"), "<ol>\n<li>bir</li>\n<li>iki</li>\n</ol>")
    }
    func testCodeBlock() {
        XCTAssertEqual(body("```\nlet a = 1 < 2\n```"), "<pre><code>let a = 1 &lt; 2</code></pre>")
    }
}
