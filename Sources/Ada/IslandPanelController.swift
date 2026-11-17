import SwiftUI
import AppKit
import AdaCore

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
        if store.isExpanded { return f }
        return NSRect(x: f.midX - collapsed.width / 2, y: f.maxY - collapsed.height, width: collapsed.width, height: collapsed.height)
    }

    /// Fare adanın üstündeyse açar ve olayları kabul eder; değilse kapatır ve olayları alttakilere bırakır.
    func tick() {
        let inside = islandRect.contains(mouseLocation())
        var keepOpen = false
        if case .running = store.status { keepOpen = true }       // dönüştürme sürerken kapanma
        let shouldExpand = inside || keepOpen
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
            let frame0 = panel.frame
            let onIsland = CGPoint(x: frame0.midX, y: frame0.maxY - 5)
            let below = CGPoint(x: frame0.midX, y: frame0.minY + 20)       // kapalıyken saydam bölge
            let away = CGPoint(x: frame0.minX - 300, y: frame0.minY - 300)
            try? await Task.sleep(for: .milliseconds(2500))                 // ajanlar ve medya yüklensin
            for i in 0..<10 {
                mouseLocation = { i % 2 == 0 ? onIsland : away }
                tick()
                if store.isExpanded != (i % 2 == 0) { failures.append("tur \(i): isExpanded \(store.isExpanded)") }
                if panel.ignoresMouseEvents != (i % 2 != 0) { failures.append("tur \(i): ignoresMouseEvents \(panel.ignoresMouseEvents)") }
                try? await Task.sleep(for: .milliseconds(450))
            }
            mouseLocation = { below }; tick()
            if store.isExpanded { failures.append("kapalıyken alt bölge adayı açtı") }
            mouseLocation = { onIsland }; tick()
            let tmp = FileManager.default.temporaryDirectory.appendingPathComponent("ada-selftest.txt")
            try? "selftest".write(to: tmp, atomically: true, encoding: .utf8)
            store.handleDrop(tmp)
            try? await Task.sleep(for: .milliseconds(700))
            if store.options.isEmpty { failures.append("bırakılan dosya için seçenek yok") }
            mouseLocation = { below }; tick()                               // açıkken alt bölge adanın içi
            if !store.isExpanded { failures.append("açıkken ada içinde kapandı") }
            store.clearDrop()
            mouseLocation = { away }; tick()
            try? await Task.sleep(for: .milliseconds(700))
            if panel.frame != frame0 { failures.append("pencere boyutu değişti: \(panel.frame)") }
            if failures.isEmpty {
                print("selftest: OK · ajan \(store.agents.count) · pencere \(Int(frame0.width))×\(Int(frame0.height)) sabit")
                exit(0)
            }
            print("selftest: BAŞARISIZ\n" + failures.joined(separator: "\n"))
            exit(1)
        }
    }
}
