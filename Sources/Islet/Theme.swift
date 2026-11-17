import SwiftUI
import AppKit

/// Adanın ölçüleri ve renkleri. Ada siyahtır (çentikle birleşir); içerik beyaz tonlarda.
enum Theme {
    static let island = Color.black
    static let text = Color.white
    static let secondary = Color.white.opacity(0.6)
    static let accent = Color(red: 0.38, green: 0.82, blue: 0.55)     // çalıyor / aktif
    static let qwen = Color(red: 0.30, green: 0.70, blue: 0.76)
    static let claude = Color(red: 0.89, green: 0.56, blue: 0.30)
    static let gemma = Color(red: 0.66, green: 0.52, blue: 0.90)
    static let expandedSize = CGSize(width: 520, height: 190)
    static let cornerCollapsed: CGFloat = 14
    static let cornerExpanded: CGFloat = 28

    /// Kapalı ada: çentik genişliğinin biraz fazlası; çentik yoksa 220.
    static func collapsedSize(for screen: NSScreen) -> CGSize {
        let notchHeight = screen.safeAreaInsets.top
        var notchWidth: CGFloat = 0
        if let l = screen.auxiliaryTopLeftArea, let r = screen.auxiliaryTopRightArea {
            notchWidth = screen.frame.width - l.width - r.width
        }
        return CGSize(width: max(notchWidth + 120, 220), height: max(notchHeight, 32))
    }
}
