import SwiftUI
import AdaCore

/// Görev: açık adadaki ajan listesi.
struct AgentsSection: View {
    let store: IslandStore
    @State private var pulse = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("AJANLAR")
                .font(.system(size: 9.5, weight: .semibold))
                .tracking(0.8)
                .foregroundStyle(Theme.secondary)

            if store.agents.isEmpty {
                Text("Çalışan ajan yok")
                    .font(.system(size: 11.5))
                    .foregroundStyle(Theme.secondary)
            } else {
                VStack(alignment: .leading, spacing: 5) {
                    ForEach(visible) { agent in
                        agentRow(agent)
                    }
                    if store.agents.count > 4 {
                        Text("+\(store.agents.count - 4) ajan daha")
                            .font(.system(size: 11))
                            .foregroundStyle(Theme.secondary)
                    }
                }
            }
        }
    }

    private var visible: [AgentActivity] { Array(store.agents.prefix(4)) }

    private func agentRow(_ agent: AgentActivity) -> some View {
        HStack(spacing: 7) {
            dot(for: agent)
            Text(agent.name)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Theme.text)
            Spacer(minLength: 0)
            Text(agent.detail)
                .font(.system(size: 11))
                .foregroundStyle(Theme.secondary)
                .lineLimit(1)
        }
    }

    private func dot(for agent: AgentActivity) -> some View {
        Circle()
            .fill(color(for: agent.kind))
            .frame(width: 7, height: 7)
            .modifier(DotPulse(active: agent.isActive, pulse: $pulse))
    }

    private func color(for kind: AgentKind) -> Color {
        switch kind {
        case .claude: return Theme.claude
        case .qwen, .agentRun, .opencode: return Theme.qwen
        case .gemma: return Theme.gemma
        }
    }
}

/// Aktif ajanlar için yanıp sönme; pasifler yarı saydam sabit kalır.
private struct DotPulse: ViewModifier {
    let active: Bool
    @Binding var pulse: Bool

    func body(content: Content) -> some View {
        content
            .opacity(active ? (pulse ? 1 : 0.4) : 0.35)
            .onAppear {
                guard active else { return }
                withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                    pulse = true
                }
            }
    }
}
