import Foundation
/// Görev: kaynağın yanında, var olan dosyanın üstüne yazmayan çıktı yolu (şu an yer tutucu).
public enum OutputPath {
    public static func make(for source: URL, ext: String, fileManager: FileManager = .default) -> URL {
        let folder = source.deletingLastPathComponent()
        let base = source.deletingPathExtension().lastPathComponent
        let candidate = makeCandidate(base: base, ext: ext, index: 0, in: folder, fileManager: fileManager)
        if !fileManager.fileExists(atPath: candidate.path) {
            return candidate
        }
        for index in 1..<1000 {
            let next = makeCandidate(base: base, ext: ext, index: index, in: folder, fileManager: fileManager)
            if !fileManager.fileExists(atPath: next.path) {
                return next
            }
        }
        return makeCandidate(base: base, ext: ext, index: 999, in: folder, fileManager: fileManager)
    }

    private static func makeCandidate(base: String, ext: String, index: Int, in folder: URL, fileManager: FileManager) -> URL {
        var name = base
        if index > 0 {
            name += " (\(index))"
        }
        return folder.appendingPathComponent("\(name).\(ext)")
    }
}
