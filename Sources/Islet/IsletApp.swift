import SwiftUI
import AppKit
import IsletCore

@main
struct IsletApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var delegate
    var body: some Scene { Settings { EmptyView() } }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let store = IslandStore()
    private var controller: IslandPanelController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)   // Dock'ta görünmez
        if Snapshot.runIfRequested() { return }
        controller = IslandPanelController(store: store)
        controller?.show()
        if CommandLine.arguments.contains("--selftest") { controller?.selfTest(); return }
        store.start()
    }
}
