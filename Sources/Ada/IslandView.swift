import SwiftUI
import AdaCore

/// Görev: adanın kendisi; kapalı/açık durum, fareyle açılma, dosya bırakma (şu an yer tutucu).
struct IslandView: View {
    @Bindable var store: IslandStore
    var body: some View {
        RoundedRectangle(cornerRadius: Theme.cornerCollapsed).fill(Theme.island)
    }
}
