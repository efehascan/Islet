import Foundation

/// Ada'nın bütün veri tipleri. Arayüz sadece bunları okur. Değiştirilmez.

public struct NowPlayingInfo: Equatable, Sendable {
    public var app: String          // "Spotify" ya da "Music"
    public var title: String
    public var artist: String
    public var album: String
    public var isPlaying: Bool
    public var artworkURL: URL?
    public var position: Double     // saniye
    public var duration: Double     // saniye
    public init(app: String, title: String, artist: String, album: String = "", isPlaying: Bool,
                artworkURL: URL? = nil, position: Double = 0, duration: Double = 0) {
        self.app = app; self.title = title; self.artist = artist; self.album = album; self.isPlaying = isPlaying
        self.artworkURL = artworkURL; self.position = position; self.duration = duration
    }
}

public enum MediaCommand: String, Sendable { case playPause, next, previous }

public enum AgentKind: String, Sendable { case claude, qwen, gemma, opencode, agentRun }

public struct AgentActivity: Equatable, Sendable, Identifiable {
    public var id: String
    public var kind: AgentKind
    public var name: String         // ör. "Claude Code", "Qwen", "agent run"
    public var detail: String       // ör. "pb-07-info · 2. tur", "3 istek / dk"
    public var isActive: Bool
    public init(id: String, kind: AgentKind, name: String, detail: String, isActive: Bool) {
        self.id = id; self.kind = kind; self.name = name; self.detail = detail; self.isActive = isActive
    }
}

public enum FileKind: String, Sendable { case document, pdf, markdown, image, audio, video, unknown }

public enum ConversionTool: String, Sendable {
    case textutil      // /usr/bin/textutil -convert <fmt>
    case cupsfilter    // /usr/sbin/cupsfilter <html|txt> > out.pdf
    case sips          // /usr/bin/sips -s format <fmt>
    case afconvert     // /usr/bin/afconvert -f <file> -d <data>
    case avconvert     // /usr/bin/avconvert --preset <preset>
    case pdfText       // PDFKit: PDFDocument.string
    case pdfImages     // PDFKit: her sayfa PNG
    case markdown      // Markdown → HTML (Markdown.html), gerekirse sonra textutil/cupsfilter
    case ffmpeg        // ffmpeg kuruluysa (mp3 vb.)
}

public struct ConversionOption: Equatable, Hashable, Sendable, Identifiable {
    public var id: String           // "<giriş>-<çıkış>", ör. "docx-pdf"
    public var title: String        // düğme metni, ör. "PDF"
    public var outputExtension: String
    public var tool: ConversionTool
    public init(id: String, title: String, outputExtension: String, tool: ConversionTool) {
        self.id = id; self.title = title; self.outputExtension = outputExtension; self.tool = tool
    }
}

public enum ConversionStatus: Equatable, Sendable {
    case idle
    case running(String)            // "PDF'e dönüştürülüyor…"
    case done(URL)                  // çıktı dosyası
    case failed(String)             // kullanıcıya gösterilecek hata
}

public enum ConversionError: Error, Equatable, LocalizedError {
    case unsupported(String)
    case toolFailed(tool: String, message: String)
    public var errorDescription: String? {
        switch self {
        case .unsupported(let s): return "Desteklenmiyor: \(s)"
        case .toolFailed(let t, let m): return "\(t) başarısız: \(m)"
        }
    }
}
