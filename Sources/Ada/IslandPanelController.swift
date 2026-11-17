import SwiftUI
import AppKit
import AdaCore

/// Fare izleme alanı her zaman etkin olan barındırıcı: odak almayan pencerede SwiftUI'ın
/// onHover'ı güvenilir değil, giriş/çıkışı burada yakalıyoruz.
final class HoverHostingView<Content: View>: NSHostingView<Content> {
    var onHover: ((Bool) -> Void)?
    private var area: NSTrackingArea?

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let area { removeTrackingArea(area) }
        let a = NSTrackingArea(rect: .zero, options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect], owner: self, userInfo: nil)
        addTrackingArea(a); area = a
    }
    override func mouseEntered(with event: NSEvent) { onHover?(true) }
    override func mouseExited(with event: NSEvent) { onHover?(false) }
}

/// Çentiğin altında duran, odak çalmayan, bütün masaüstlerinde görünen pencere.
/// Boyutu adanın durumuna göre değişir; kapalıyken sadece ada kadar yer kaplar.
@MainActor
final class IslandPanelController {
    private let store: IslandStore
    private let panel: NSPanel

    init(store: IslandStore) {
        self.store = store
        panel = NSPanel(contentRect: .zero, styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.level = NSWindow.Level(rawValue: NSWindow.Level.mainMenu.rawValue + 3)
        panel.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary, .ignoresCycle]
        panel.hidesOnDeactivate = false
        panel.isMovable = false
        panel.acceptsMouseMovedEvents = true
        let host = HoverHostingView(rootView: IslandView(store: store))
        // Barındırıcı pencereye boyut kısıtı koymasın: pencereyi biz boyutlandırıyoruz.
        // (Varsayılan kısıtlar, boyut değişirken AppKit'te kısıt döngüsü çökmesine yol açıyordu.)
        host.sizingOptions = []
        host.onHover = { [weak store] inside in
            guard let store else { return }
            if inside { store.isExpanded = true; return }
            if case .running = store.status { return }   // dönüştürme sürerken kapanma
            store.isExpanded = false
        }
        panel.contentView = host
    }

    func show() {
        layout()
        panel.orderFrontRegardless()
        observe()
    }

    private func observe() {
        withObservationTracking { _ = store.isExpanded } onChange: { [weak self] in
            Task { @MainActor in self?.layout(); self?.observe() }
        }
    }

    private func layout() {
        guard let screen = NSScreen.main else { return }
        let size = store.isExpanded ? Theme.expandedSize : Theme.collapsedSize(for: screen)
        let frame = NSRect(x: screen.frame.midX - size.width / 2, y: screen.frame.maxY - size.height,
                           width: size.width, height: size.height)
        panel.setFrame(frame, display: true)
    }

    /// `--selftest`: açıp kapamayı birkaç kez dener; çökmezse 0 ile çıkar.
    func selfTest() {
        Task { @MainActor in
            for i in 0..<8 {
                try? await Task.sleep(for: .milliseconds(400))
                store.isExpanded = (i % 2 == 0)
            }
            try? await Task.sleep(for: .milliseconds(500))
            print("selftest: OK, son çerçeve \(panel.frame)")
            exit(0)
        }
    }
}
