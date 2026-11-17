import SwiftUI
import AppKit
import IsletCore

/// `Islet --snapshot <yol.png>`: açık (genişletilmiş) adayı örnek verilerle PNG olarak çizer ve çıkar.
/// Ajanların arayüzü görsel kontrol etmesi için (ekran kaydı izni gerekmez).
enum Snapshot {
    @MainActor static func runIfRequested() -> Bool {
        let args = CommandLine.arguments
        guard let i = args.firstIndex(of: "--snapshot"), i + 1 < args.count else { return false }
        let url = URL(fileURLWithPath: args[i + 1])
        let store = IslandStore()
        store.isExpanded = true
        Task { @MainActor in
            if args.contains("--live") { await store.refresh() }   // varsayılan: medya/ajan okumadan, sadece yerleşim
            if let f = args.firstIndex(of: "--file"), f + 1 < args.count { store.handleDrop(URL(fileURLWithPath: args[f + 1])) }
            let view = IslandView(store: store)
                .frame(width: Theme.expandedSize.width, height: Theme.expandedSize.height)
                .padding(20)
                .background(Color(white: 0.85))
            let host = NSHostingView(rootView: view)
            host.frame = NSRect(origin: .zero, size: host.fittingSize)
            let window = NSWindow(contentRect: host.frame, styleMask: [.borderless], backing: .buffered, defer: false)
            window.contentView = host
            host.layoutSubtreeIfNeeded()
            var ok = false
            if let rep = host.bitmapImageRepForCachingDisplay(in: host.bounds) {
                host.cacheDisplay(in: host.bounds, to: rep)
                if let data = rep.representation(using: .png, properties: [:]) { ok = (try? data.write(to: url)) != nil }
            }
            print(ok ? "snapshot: \(url.path)" : "snapshot: yazılamadı")
            exit(ok ? 0 : 1)
        }
        return true
    }
}
