import Foundation
/// Görev: Markdown'ın temel alt kümesini HTML'e çevir (şu an yer tutucu).
public enum Markdown {
    /// Tam HTML belgesi döndürür: <!doctype html><html><head><meta charset="utf-8"><title>…</title><style>…</style></head><body>…</body></html>
    public static func html(_ markdown: String, title: String = "Belge") -> String { "" }
}
