import Foundation
/// Görev: dosya uzantısına göre tür ve dönüştürme seçenekleri.
public enum ConversionCatalog {

    public static func kind(forExtension ext: String) -> FileKind {
        switch ext.lowercased() {
        case "docx", "doc", "rtf", "odt", "txt", "html", "htm": return .document
        case "pdf": return .pdf
        case "md", "markdown": return .markdown
        case "png", "jpg", "jpeg", "heic", "tiff", "tif", "gif", "bmp", "webp": return .image
        case "mp3", "wav", "m4a", "aiff", "aif", "caf", "flac", "aac": return .audio
        case "mov", "mp4", "m4v": return .video
        default: return .unknown
        }
    }

    public static func options(for url: URL, ffmpegAvailable: Bool) -> [ConversionOption] {
        let ext = url.pathExtension.lowercased()
        let kind = ConversionCatalog.kind(forExtension: ext)

        // (hedef, araç) sıralı listeler.
        let targets: [(String, ConversionTool)]
        switch kind {
        case .document:
            targets = [
                ("pdf", .cupsfilter),
                ("docx", .textutil),
                ("txt", .textutil),
                ("rtf", .textutil),
                ("html", .textutil),
                ("odt", .textutil),
            ]
        case .pdf:
            targets = [
                ("txt", .pdfText),
                ("png", .pdfImages),
            ]
        case .markdown:
            targets = [
                ("html", .markdown),
                ("pdf", .markdown),
                ("docx", .markdown),
            ]
        case .image:
            targets = [
                ("png", .sips),
                ("jpeg", .sips),
                ("heic", .sips),
                ("tiff", .sips),
                ("pdf", .sips),
            ]
        case .audio:
            targets = [
                ("m4a", .afconvert),
                ("wav", .afconvert),
                ("aiff", .afconvert),
                ("caf", .afconvert),
                ("flac", .afconvert),
            ]
        case .video:
            targets = [
                ("mp4", .avconvert),
                ("m4a", .avconvert),
            ]
        case .unknown:
            return []
        }

        // ffmpeg: sadece ses için ve kaynak mp3 değilse sona mp3.
        var list = targets
        if kind == .audio, ffmpegAvailable, ext != "mp3" {
            list.append(("mp3", .ffmpeg))
        }

        // Kaynağın kendi biçimlerini listeden çıkar.
        var skip = Set(ext == "jpg" ? ["jpg", "jpeg"] : [ext])
        if ext == "htm" { skip.insert("html") }
        if ext == "tif" { skip.insert("tiff") }

        return list.compactMap { target, tool in
            guard !skip.contains(target) else { return nil }
            return ConversionOption(
                id: "\(ext)-\(target)",
                title: target.uppercased(),
                outputExtension: target,
                tool: tool
            )
        }
    }
}
