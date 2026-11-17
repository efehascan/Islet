import SwiftUI
import AppKit
import IsletCore

/// Klavye odağı alabilen (düğmeler çalışsın) ama uygulamayı öne getirmeyen panel.
final class IslandPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}

/// Adayı sabit boyutlu pencerenin üst ortasına yerleştirir; ada bu görünümün içinde büyüyüp küçülür.
struct IslandRoot: View {
    let store: IslandStore
    let collapsed: CGSize

    var body: some View {
        IslandView(store: store)
            .frame(width: store.isExpanded ? Theme.expandedSize.width : collapsed.width,
                   height: store.isExpanded ? Theme.expandedSize.height : collapsed.height)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .animation(.spring(response: 0.35, dampingFraction: 0.8), value: store.isExpanded)
    }
}

/// Çentiğin altında duran, bütün masaüstlerinde görünen pencere.
///
/// Pencerenin boyutu HİÇ değişmez (açık adanın boyutu kadardır). Pencereyi her açılıp kapanmada
/// yeniden boyutlandırmak, SwiftUI içeriğiyle birlikte AppKit'te "Update Constraints" döngüsüne ve
/// çökmeye yol açıyordu. Ada kapalıyken pencere fare olaylarını yok sayar (alttaki her şey tıklanır);
/// fare adanın üstüne gelince olayları kabul eder ve ada açılır.
@MainActor
final class IslandPanelController {
    private let store: IslandStore
    private let panel: IslandPanel
    private var timer: Timer?
    private var collapsed = CGSize(width: 220, height: 32)
    /// Fare konumu (ekran koordinatı). Testte sahte konum verilebilir.
    var mouseLocation: () -> CGPoint = { NSEvent.mouseLocation }
    /// Saat. Testte sahte saat verilir (gerçek bekleme yok).
    var now: () -> Date = { Date() }
    /// Açılmak için farenin adanın üstünde kalması gereken süre: menü çubuğuna giderken
    /// üstünden geçmek adayı açmasın.
    static let openDelay: TimeInterval = 0.25
    /// Kapanma gecikmesi: fare adadan çıkınca hemen kapanır.
    static let closeDelay: TimeInterval = 0
    /// Açıkken ada çevresine eklenen tolerans payı (pt): yok, ada sınırında kapanır.
    static let margin: CGFloat = 0
    private var insideSince: Date?
    private var outsideSince: Date?

    init(store: IslandStore) {
        self.store = store
        panel = IslandPanel(contentRect: .zero, styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.level = NSWindow.Level(rawValue: NSWindow.Level.mainMenu.rawValue + 3)
        panel.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary, .ignoresCycle]
        panel.hidesOnDeactivate = false
        panel.isMovable = false
        panel.ignoresMouseEvents = true
    }

    func show() {
        place()
        panel.orderFrontRegardless()
        NotificationCenter.default.addObserver(forName: NSApplication.didChangeScreenParametersNotification, object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor in self?.place() }
        }
        let t = Timer(timeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tick() }
        }
        RunLoop.main.add(t, forMode: .common)
        timer = t
    }

    /// Pencereyi ekranın üst ortasına, açık ada boyutunda yerleştirir (açılışta ve ekran değişince).
    private func place() {
        guard let screen = NSScreen.main else { return }
        collapsed = Theme.collapsedSize(for: screen)
        let size = Theme.expandedSize
        let host = NSHostingView(rootView: IslandRoot(store: store, collapsed: collapsed))
        host.sizingOptions = []          // pencere boyutunu içerik belirlemez
        panel.contentView = host
        panel.setFrame(NSRect(x: screen.frame.midX - size.width / 2, y: screen.frame.maxY - size.height,
                              width: size.width, height: size.height), display: true)
    }

    /// Adanın şu anki dikdörtgeni (ekran koordinatı): kapalıyken hap, açıkken bütün pencere.
    private var islandRect: NSRect {
        let f = panel.frame
        if store.isExpanded { return f.insetBy(dx: -Self.margin, dy: -Self.margin) }
        return NSRect(x: f.midX - collapsed.width / 2, y: f.maxY - collapsed.height, width: collapsed.width, height: collapsed.height)
    }

    /// Fare adanın üstündeyse açar ve olayları kabul eder; değilse kapatır ve olayları alttakilere bırakır.
    func tick() {
        let t = now()
        let inside = islandRect.contains(mouseLocation())
        if inside { insideSince = insideSince ?? t; outsideSince = nil } else { outsideSince = outsideSince ?? t; insideSince = nil }
        var keepOpen = false
        if case .running = store.status { keepOpen = true }       // dönüştürme sürerken kapanma
        var shouldExpand = store.isExpanded
        if !store.isExpanded, let since = insideSince, t.timeIntervalSince(since) >= Self.openDelay { shouldExpand = true }
        if store.isExpanded, !keepOpen, let since = outsideSince, t.timeIntervalSince(since) >= Self.closeDelay { shouldExpand = false }
        if store.isExpanded != shouldExpand { store.isExpanded = shouldExpand }
        let ignore = !shouldExpand
        if panel.ignoresMouseEvents != ignore { panel.ignoresMouseEvents = ignore }
    }

    /// `--selftest`: gerçek veriler yüklüyken sahte fare konumuyla adayı açıp kapar, dosya bırakır;
    /// pencere boyutunun değişmediğini ve kapalıyken tıklamaları geçirdiğini doğrular. Çökmezse 0 ile çıkar.
    func selfTest() {
        store.start()
        timer?.invalidate()
        Task { @MainActor in
            var failures: [String] = []
            var clock = Date(timeIntervalSince1970: 0)
            now = { clock }
            @MainActor func step(_ point: CGPoint, _ seconds: TimeInterval) {
                mouseLocation = { point }
                var left = seconds
                repeat { tick(); clock += 0.1; left -= 0.1 } while left > 0
                tick()
            }
            @MainActor func expect(_ open: Bool, _ what: String) {
                if store.isExpanded != open { failures.append("\(what): isExpanded \(store.isExpanded)") }
                if panel.ignoresMouseEvents == open { failures.append("\(what): ignoresMouseEvents \(panel.ignoresMouseEvents)") }
            }
            let frame0 = panel.frame
            let onIsland = CGPoint(x: frame0.midX, y: frame0.maxY - 5)
            let below = CGPoint(x: frame0.midX, y: frame0.minY + 20)
            let justOutside = CGPoint(x: frame0.maxX + 6, y: frame0.midY)
            let away = CGPoint(x: frame0.minX - 300, y: frame0.minY - 300)
            try? await Task.sleep(for: .milliseconds(2500))     // ajanlar ve medya gerçekten yüklensin
            step(onIsland, 0.1); expect(false, "üstünden geçiş (0,1 sn) açmamalı")
            step(away, 0.1)
            step(onIsland, 0.4); expect(true, "0,4 sn üstünde kalınca açılmalı")
            step(justOutside, 0); expect(false, "kenarın 6 pt dışına çıkınca hemen kapanmalı")
            step(onIsland, 0.4); expect(true, "tekrar 0,4 sn üstünde kalınca açılmalı")
            step(away, 0); expect(false, "uzağa çıkınca hemen kapanmalı")
            step(below, 0.6); expect(false, "kapalıyken alt bölge açmamalı")
            for i in 0..<6 {                                     // gerçek animasyonla aç/kapa (çökme kontrolü)
                step(i % 2 == 0 ? onIsland : away, 0.7)
                try? await Task.sleep(for: .milliseconds(400))
            }
            step(onIsland, 0.4)
            let tmp = FileManager.default.temporaryDirectory.appendingPathComponent("islet-selftest.txt")
            try? "selftest".write(to: tmp, atomically: true, encoding: .utf8)
            store.handleDrop(tmp)
            try? await Task.sleep(for: .milliseconds(700))
            if store.options.isEmpty { failures.append("bırakılan dosya için seçenek yok") }
            store.clearDrop()
            step(away, 0.8)
            try? await Task.sleep(for: .milliseconds(500))
            if panel.frame != frame0 { failures.append("pencere boyutu değişti: \(panel.frame)") }
            if failures.isEmpty {
                print("selftest: OK · ajan \(store.agents.count) · açılma \(Self.openDelay) sn, kapanma \(Self.closeDelay) sn")
                exit(0)
            }
            print("selftest: BAŞARISIZ\n" + failures.joined(separator: "\n"))
            exit(1)
        }
    }
}
