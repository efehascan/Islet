import Foundation
import PDFKit
import AppKit
import CoreGraphics

/// Görev: seçeneğe göre dönüştürmeyi yapan sınıf.
public final class Converter {
    public init() {}

    /// Çıktıyı OutputPath.make ile kaynağın yanına yazar ve çıktı URL'sini döndürür.
    public func convert(_ source: URL, option: ConversionOption) async throws -> URL {
        guard FileManager.default.fileExists(atPath: source.path) || option.tool == .ffmpeg else {
            throw ConversionError.unsupported("kaynak bulunamadı")
        }
        let out = OutputPath.make(for: source, ext: option.outputExtension)
        return try await Task.detached(priority: .userInitiated) {
            let result: URL
            if option.tool == .pdfImages {
                result = try self.pdfImages(source: source)
            } else {
                try self.perform(source: source, option: option, out: out)
                if !FileManager.default.fileExists(atPath: out.path) {
                    throw ConversionError.toolFailed(tool: Self.toolName(option.tool), message: "çıktı oluşmadı")
                }
                result = out
            }
            return result
        }.value
    }

    // MARK: - Araç adları ve yardımcıları

    private static func toolName(_ tool: ConversionTool) -> String {
        switch tool {
        case .textutil: return "textutil"
        case .cupsfilter: return "cupsfilter"
        case .sips: return "sips"
        case .afconvert: return "afconvert"
        case .avconvert: return "avconvert"
        case .pdfText: return "PDFKit"
        case .pdfImages: return "PDFKit"
        case .markdown: return "markdown"
        case .ffmpeg: return "ffmpeg"
        }
    }

    private func perform(source: URL, option: ConversionOption, out: URL) throws {
        guard FileManager.default.fileExists(atPath: source.path) else {
            throw ConversionError.unsupported("kaynak bulunamadı")
        }
        switch option.tool {
        case .textutil:
            try run("/usr/bin/textutil", ["-convert", option.outputExtension, source.path, "-output", out.path])
        case .cupsfilter:
            try cupsfilter(source: source, out: out)
        case .sips:
            try run("/usr/bin/sips", ["-s", "format", option.outputExtension, source.path, "--out", out.path])
        case .afconvert:
            try run("/usr/bin/afconvert", afconvertArgs(option.outputExtension) + [source.path, out.path])
        case .avconvert:
            let preset = option.outputExtension == "m4a" ? "PresetAppleM4A" : "PresetHighestQuality"
            try run("/usr/bin/avconvert", ["--source", source.path, "--output", out.path, "--preset", preset, "--replace"])
        case .markdown:
            try markdown(source: source, option: option, out: out)
        case .pdfText:
            try pdfText(source: source, out: out)
        case .pdfImages:
            _ = try pdfImages(source: source)
        case .ffmpeg:
            try ffmpeg(source: source, out: out)
        }
    }

    private func afconvertArgs(_ ext: String) -> [String] {
        switch ext.lowercased() {
        case "m4a": return ["-f", "m4af", "-d", "aac"]
        case "wav": return ["-f", "WAVE", "-d", "LEI16"]
        case "aiff": return ["-f", "AIFF", "-d", "BEI16"]
        case "caf": return ["-f", "caff", "-d", "aac"]
        case "flac": return ["-f", "flac", "-d", "flac"]
        default: return []
        }
    }

    /// text/html ya da txt doğrudan; diğer document biçimleri önce textutil ile geçici html'e çevrilir.
    private func cupsfilter(source: URL, out: URL) throws {
        let ext = source.pathExtension.lowercased()
        if ext == "txt" || ext == "html" || ext == "htm" {
            try run("/usr/sbin/cupsfilter", [source.path], stdoutTo: out)
        } else {
            let html = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".html")
            try run("/usr/bin/textutil", ["-convert", "html", source.path, "-output", html.path])
            defer { try? FileManager.default.removeItem(at: html) }
            try run("/usr/sbin/cupsfilter", [html.path], stdoutTo: out)
        }
    }

    private func markdown(source: URL, option: ConversionOption, out: URL) throws {
        let content = try String(contentsOf: source, encoding: .utf8)
        let title = source.deletingPathExtension().lastPathComponent
        let html = Markdown.html(content, title: title)
        let ext = option.outputExtension.lowercased()
        if ext == "html" {
            try html.write(to: out, atomically: true, encoding: .utf8)
        } else {
            let tmp = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".html")
            try html.write(to: tmp, atomically: true, encoding: .utf8)
            defer { try? FileManager.default.removeItem(at: tmp) }
            if ext == "pdf" {
                try run("/usr/sbin/cupsfilter", [tmp.path], stdoutTo: out)
            } else { // docx
                try run("/usr/bin/textutil", ["-convert", "docx", tmp.path, "-output", out.path])
            }
        }
    }

    private func pdfText(source: URL, out: URL) throws {
        guard let document = PDFDocument(url: source), let text = document.string else {
            throw ConversionError.toolFailed(tool: "PDFKit", message: "pdf okunamadı")
        }
        try text.write(to: out, atomically: true, encoding: .utf8)
    }

    /// Her sayfayı "taban (sayfa N).png" olarak yazar, ilk sayfanın URL'sini döndürür.
    private func pdfImages(source: URL) throws -> URL {
        guard let document = PDFDocument(url: source) else {
            throw ConversionError.toolFailed(tool: "PDFKit", message: "pdf okunamadı")
        }
        let folder = source.deletingLastPathComponent()
        let base = source.deletingPathExtension().lastPathComponent
        var first: URL?
        for index in 0..<document.pageCount {
            guard let page = document.page(at: index) else { continue }
            let size = page.bounds(for: .mediaBox).size
            guard let cg = Self.renderPNG(page: page, size: size) else { continue }
            let name = "\(base) (sayfa \(index + 1)).png"
            var url = folder.appendingPathComponent(name)
            if FileManager.default.fileExists(atPath: url.path) { url = OutputPath.make(for: url, ext: "png") }
            try cg.write(to: url, options: [])
            if first == nil { first = url }
        }
        guard let first else {
            throw ConversionError.toolFailed(tool: "PDFKit", message: "sayfa görüntüsü alınamadı")
        }
        return first
    }

    /// PDF sayfasını PNG baytlarına çevirir; çizilemezse nil.
    private static func renderPNG(page: PDFPage, size: CGSize) -> Data? {
        guard let context = CGContext(
            data: nil,
            width: Int(ceil(size.width)),
            height: Int(ceil(size.height)),
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }
        // PDF ve bitmap bağlamı ikisi de sol-alt köşe kökenli: çevirme gerekmez.
        context.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: size.width, height: size.height))
        page.draw(with: .mediaBox, to: context)
        guard let image = context.makeImage() else { return nil }
        return NSBitmapImageRep(cgImage: image).representation(using: .png, properties: [:])
    }

    private func ffmpeg(source: URL, out: URL) throws {
        let candidates = ["/opt/homebrew/bin/ffmpeg", "/usr/local/bin/ffmpeg"]
        let path = candidates.first { FileManager.default.isExecutableFile(atPath: $0) }
        guard let path else {
            throw ConversionError.unsupported("ffmpeg kurulu değil")
        }
        try run(path, ["-y", "-i", source.path, out.path])
    }

    /// Process ile çalıştırır. stdoutTo verilirse çıktı o dosyaya, değilse atılır;
    /// hata durumunda stderr'in son 300 karakteriyle toolFailed fırlatılır.
    private func run(_ path: String, _ args: [String], stdoutTo: URL? = nil) throws {
        let tool = (path as NSString).lastPathComponent
        let process = Process()
        process.executableURL = URL(fileURLWithPath: path)
        process.arguments = args

        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe

        var writer: FileHandle?
        if let outURL = stdoutTo {
            FileManager.default.createFile(atPath: outURL.path, contents: nil)
            writer = try FileHandle(forWritingTo: outURL)
        }

        do {
            try process.run()
        } catch {
            throw ConversionError.toolFailed(tool: tool, message: error.localizedDescription)
        }

        // stdout'u tüket; verilmişse dosyaya aktar, değilse oku-at.
        let consumed = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()

        if let writer {
            do {
                try writer.write(contentsOf: consumed)
                try writer.close()
            } catch {
                throw ConversionError.toolFailed(tool: tool, message: error.localizedDescription)
            }
        }

        if process.terminationStatus != 0 {
            let data = stderrPipe.fileHandleForReading.readDataToEndOfFile()
            let message = String(decoding: data, as: UTF8.self).suffix(300)
            throw ConversionError.toolFailed(tool: tool, message: String(message))
        }
    }
}
