import SwiftUI
import AdaCore

/// Görev: adanın kendisi; kapalı/açık durum, fareyle açılma, dosya bırakma.
struct IslandView: View {
    @Bindable var store: IslandStore

    var body: some View {
        ZStack(alignment: .top) {
            shape
            content
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .onHover { inside in
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                store.isExpanded = inside || (store.droppedFile != nil && isRunning)
            }
        }
        .dropDestination(for: URL.self) { urls, _ in
            guard let u = urls.first else { return false }
            store.handleDrop(u)
            return true
        } isTargeted: { targeted in
            if targeted {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    store.isExpanded = true
                }
            }
        }
    }

    // MARK: - Şekil

    private var shape: some View {
        UnevenRoundedRectangle(
            bottomLeadingRadius: store.isExpanded ? Theme.cornerExpanded : Theme.cornerCollapsed,
            bottomTrailingRadius: store.isExpanded ? Theme.cornerExpanded : Theme.cornerCollapsed
        )
        .fill(Theme.island)
    }

    // MARK: - İçerik

    @ViewBuilder
    private var content: some View {
        if store.isExpanded {
            expandedContent
                .transition(.opacity)
        } else {
            collapsedContent
                .transition(.opacity)
        }
    }

    private var isRunning: Bool {
        if case .running = store.status { return true }
        return false
    }

    // MARK: - Kapalı hap

    private var collapsedContent: some View {
        HStack(spacing: 10) {
            collapsedLeft
            Spacer(minLength: 0)
            collapsedRight
        }
        .padding(.horizontal, 14)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private var collapsedLeft: some View {
        if let media = store.media {
            AsyncImage(url: media.artworkURL) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                RoundedRectangle(cornerRadius: 4).fill(Color.white.opacity(0.12))
            }
            .frame(width: 18, height: 18)
            .clipShape(RoundedRectangle(cornerRadius: 4))
        } else if let first = store.agents.first(where: { $0.isActive }) {
            Circle().fill(agentColor(first.kind)).frame(width: 7, height: 7)
        }
    }

    @ViewBuilder
    private var collapsedRight: some View {
        if let media = store.media, media.isPlaying {
            wave
        } else if let n = activeAgentCount, n > 0 {
            Text("\(n)")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Theme.qwen)
        }
    }

    // MARK: - Açık kart

    private var expandedContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            MediaSection(store: store)
            Divider().overlay(Color.white.opacity(0.12))
            HStack(alignment: .top, spacing: 16) {
                AgentsSection(store: store)
                    .frame(maxWidth: .infinity, alignment: .leading)
                DropSection(store: store)
                    .frame(width: 230)
            }
        }
        .padding(.top, 38)
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    // MARK: - Yardımcılar

    private var wave: some View {
        WaveView()
    }

    private var activeAgentCount: Int? {
        let count = store.agents.filter { $0.isActive }.count
        return count > 0 ? count : nil
    }

    private func agentColor(_ kind: AgentKind) -> Color {
        switch kind {
        case .claude: return Theme.claude
        case .qwen, .agentRun, .opencode: return Theme.qwen
        case .gemma: return Theme.gemma
        }
    }
}

/// Çalan medya için 3 çubuklu, 6…12 yükseklik arasında animasyonlu dalga.
private struct WaveView: View {
    @State private var animate = false

    var body: some View {
        HStack(spacing: 3) {
            bar(phase: 0)
            bar(phase: 1)
            bar(phase: 2)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                animate = true
            }
        }
    }

    private func bar(phase: Int) -> some View {
        RoundedRectangle(cornerRadius: 1.25)
            .fill(Theme.accent)
            .frame(width: 2.5, height: animate ? 12 : 6)
            .offset(y: animate ? -3 : 3)
            .animation(
                .easeInOut(duration: 0.9 - Double(phase) * 0.15)
                    .repeatForever(autoreverses: true)
                    .delay(Double(phase) * 0.18),
                value: animate
            )
    }
}
