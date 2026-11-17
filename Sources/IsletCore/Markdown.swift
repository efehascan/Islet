import Foundation
/// Görev: Markdown'ın temel alt kümesini HTML'e çevir (şu an yer tutucu).
public enum Markdown {
    /// Tam HTML belgesi döndürür: <!doctype html><html><head><meta charset="utf-8"><title>…</title><style>…</style></head><body>…</body></html>
    public static func html(_ markdown: String, title: String = "Belge") -> String {
        let body = renderBody(markdown)
        let head = "<!doctype html>\n<html><head><meta charset=\"utf-8\"><title>"
            + escape(title) + "</title><style>body{font-family:-apple-system,Helvetica,sans-serif;max-width:720px;margin:40px auto;line-height:1.6}code,pre{font-family:Menlo,monospace}</style></head><body>\n"
        return head + body + "\n</body></html>"
    }

    private static func renderBody(_ markdown: String) -> String {
        let lines = markdown.components(separatedBy: "\n")
        var blocks: [String] = []
        var i = 0
        while i < lines.count {
            let line = lines[i]
            if line.hasPrefix("```") {
                var content: [String] = []
                i += 1
                while i < lines.count && lines[i] != "```" {
                    content.append(lines[i])
                    i += 1
                }
                i += 1
                let inner = content.joined(separator: "\n")
                blocks.append("<pre><code>" + escape(inner) + "</code></pre>")
                continue
            }
            if line.isEmpty {
                i += 1
                continue
            }
            if let text = headingText(line) {
                blocks.append("<h\(text.0)>" + inline(escape(String(text.1))) + "</h\(text.0)>")
                i += 1
                continue
            }
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("- ") || trimmed.hasPrefix("* ") {
                var items: [String] = []
                while i < lines.count {
                    let t = lines[i].trimmingCharacters(in: .whitespaces)
                    if t.hasPrefix("- ") || t.hasPrefix("* ") {
                        items.append("<li>" + inline(escape(String(t.dropFirst(2)))) + "</li>")
                        i += 1
                    } else if t.isEmpty {
                        break
                    } else {
                        break
                    }
                }
                blocks.append("<ul>\n" + items.joined(separator: "\n") + "\n</ul>")
                continue
            }
            if isOrderedItem(trimmed) {
                var items: [String] = []
                while i < lines.count {
                    let t = lines[i].trimmingCharacters(in: .whitespaces)
                    if isOrderedItem(t) {
                        items.append("<li>" + inline(escape(textOfOrdered(t))) + "</li>")
                        i += 1
                    } else {
                        break
                    }
                }
                blocks.append("<ol>\n" + items.joined(separator: "\n") + "\n</ol>")
                continue
            }
            var para: [String] = []
            while i < lines.count {
                let l = lines[i]
                if l.isEmpty { break }
                if l.hasPrefix("```") { break }
                let t = l.trimmingCharacters(in: .whitespaces)
                if t.hasPrefix("- ") || t.hasPrefix("* ") { break }
                if isOrderedItem(t) { break }
                if isHeading(t) { break }
                para.append(l)
                i += 1
            }
            if para.isEmpty {
                i += 1
            } else {
                let joined = para.joined(separator: " ")
                blocks.append("<p>" + inline(escape(joined)) + "</p>")
            }
        }
        return blocks.joined(separator: "\n")
    }

    private static func headingText(_ s: String) -> (Int, Substring)? {
        guard s.hasPrefix("#") else { return nil }
        let level = s.prefix(while: { $0 == "#" }).count
        guard (1...6).contains(level), s.count > level, s[s.index(s.startIndex, offsetBy: level)] == " " else { return nil }
        let rest = s.dropFirst(level + 1)
        return (level, rest)
    }

    private static func isHeading(_ s: String) -> Bool {
        headingText(s) != nil
    }

    private static func isOrderedItem(_ s: String) -> Bool {
        guard let dot = s.firstIndex(of: ".") else { return false }
        let prefix = s[s.startIndex..<dot]
        guard !prefix.isEmpty, prefix.allSatisfy({ $0.isNumber }) else { return false }
        let afterDot = s.index(after: dot)
        guard afterDot < s.endIndex else { return false }
        return s[afterDot] == " "
    }

    private static func textOfOrdered(_ s: String) -> String {
        guard let dot = s.firstIndex(of: ".") else { return s }
        let afterDot = s.index(after: dot)
        guard afterDot < s.endIndex, s[afterDot] == " " else { return s }
        return String(s[s.index(after: afterDot)...])
    }

    private static func escape(_ s: String) -> String {
        var out = ""
        out.reserveCapacity(s.count)
        for ch in s {
            switch ch {
            case "&": out += "&amp;"
            case "<": out += "&lt;"
            case ">": out += "&gt;"
            default: out.append(ch)
            }
        }
        return out
    }

    private static func inline(_ s: String) -> String {
        var result = s
        if let code = applyRegex(pattern: "`([^`]+)`", template: "<code>$1</code>", in: result) {
            result = code
        }
        if let bold = applyRegex(pattern: "\\*\\*([^*]+)\\*\\*", template: "<strong>$1</strong>", in: result) {
            result = bold
        }
        if let em = applyRegex(pattern: "\\*([^*]+)\\*", template: "<em>$1</em>", in: result) {
            result = em
        }
        if let link = applyRegex(pattern: "\\[([^\\]]+)\\]\\(([^)]+)\\)", template: "<a href=\"$2\">$1</a>", in: result) {
            result = link
        }
        return result
    }

    private static func applyRegex(pattern: String, template: String, in string: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else { return nil }
        let range = NSRange(string.startIndex..., in: string)
        return regex.stringByReplacingMatches(in: string, options: [], range: range, withTemplate: template)
    }
}
