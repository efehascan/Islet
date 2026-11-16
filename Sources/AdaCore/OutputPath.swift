import Foundation
/// Görev: kaynağın yanında, var olan dosyanın üstüne yazmayan çıktı yolu (şu an yer tutucu).
public enum OutputPath {
    public static func make(for source: URL, ext: String, fileManager: FileManager = .default) -> URL { source }
}
