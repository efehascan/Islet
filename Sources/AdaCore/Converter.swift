import Foundation
/// Görev: seçeneğe göre dönüştürmeyi yapan sınıf (şu an yer tutucu).
public final class Converter {
    public init() {}
    /// Çıktıyı OutputPath.make ile kaynağın yanına yazar ve çıktı URL'sini döndürür.
    public func convert(_ source: URL, option: ConversionOption) async throws -> URL {
        throw ConversionError.unsupported(option.id)
    }
}
