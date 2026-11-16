import SwiftUI
import AppKit
import AdaCore

/// Çentiğin altında duran, odak çalmayan, bütün masaüstlerinde görünen pencere.
/// Boyutu adanın durumuna göre değişir; kapalıyken sadece ada kadar yer kaplar, alttaki tıklamaları engellemez.
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
        panel.contentView = NSHostingView(rootView: IslandView(store: store))
    }

    func show() {
        layout(animated: false)
        panel.orderFrontRegardless()
        observe()
    }

    /// isExpanded değiştikçe pencereyi yeniden boyutlandırır.
    private func observe() {
        withObservationTracking { _ = store.isExpanded; _ = store.droppedFile } onChange: { [weak self] in
            Task { @MainActor in self?.layout(animated: true); self?.observe() }
        }
    }

    private func layout(animated: Bool) {
        guard let screen = NSScreen.main else { return }
        let size = store.isExpanded ? Theme.expandedSize : Theme.collapsedSize(for: screen)
        let frame = NSRect(x: screen.frame.midX - size.width / 2, y: screen.frame.maxY - size.height,
                           width: size.width, height: size.height)
        panel.setFrame(frame, display: true, animate: animated)
    }
}
