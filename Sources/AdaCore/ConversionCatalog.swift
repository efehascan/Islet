import Foundation
/// Görev: dosya uzantısına göre tür ve dönüştürme seçenekleri (şu an yer tutucu).
public enum ConversionCatalog {
    public static func kind(forExtension ext: String) -> FileKind { .unknown }
    public static func options(for url: URL, ffmpegAvailable: Bool) -> [ConversionOption] { [] }
}
