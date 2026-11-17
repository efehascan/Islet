import SwiftUI
import AppKit
import AdaCore

/// Görev: açık adadaki dosya bırakma ve dönüştürme alanı.
struct DropSection: View {
    let store: IslandStore

    var body: some View {
        if let url = store.droppedFile {
            droppedView(url)
        } else {
            emptyBox
        }
    }

    // MARK: - Dosya yok

    private var emptyBox: some View {
        RoundedRectangle(cornerRadius: 12)
            .strokeBorder(Theme.secondary.opacity(0.5),
                          style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
            .overlay(
                VStack(spacing: 6) {
                    Image(systemName: "arrow.down.doc")
                    Text("Dönüştürmek için dosya bırak")
                }
                .font(.system(size: 11.5))
                .foregroundStyle(Theme.secondary)
            )
            .frame(height: 54)
    }

    // MARK: - Dosya var

    private func droppedView(_ url: URL) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            fileRow(url)
            if !store.options.isEmpty {
                optionsRow
            }
            statusRow
        }
    }

    private func fileRow(_ url: URL) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "doc")
                .foregroundStyle(Theme.secondary)
            Text(url.lastPathComponent)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Theme.text)
                .lineLimit(1)
                .truncationMode(.middle)
            Spacer(minLength: 0)
            Button {
                store.clearDrop()
            } label: {
                Image(systemName: "xmark.circle.fill")
            }
            .buttonStyle(.plain)
            .foregroundStyle(Theme.secondary)
        }
    }

    private var optionsRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(store.options) { option in
                    optionButton(option)
                }
            }
        }
    }

    private func optionButton(_ option: ConversionOption) -> some View {
        Button(option.title) {
            Task { await store.convert(option) }
        }
        .buttonStyle(OptionPillStyle(isRunning: isRunning))
        .disabled(isRunning)
    }

    private var isRunning: Bool {
        if case .running = store.status { return true }
        return false
    }

    // MARK: - Durum

    @ViewBuilder
    private var statusRow: some View {
        switch store.status {
        case .running(let message):
            HStack(spacing: 6) {
                ProgressView()
                    .controlSize(.small)
                Text(message)
            }
            .font(.system(size: 11))
            .foregroundStyle(Theme.text)

        case .done(let url):
            Button {
                NSWorkspace.shared.activateFileViewerSelecting([url])
            } label: {
                Label("\(url.lastPathComponent) kaydedildi", systemImage: "checkmark.circle.fill")
            }
            .buttonStyle(.plain)
            .font(.system(size: 11))
            .foregroundStyle(Theme.accent)

        case .failed(let message):
            Label(message, systemImage: "exclamationmark.triangle.fill")
                .font(.system(size: 11))
                .foregroundStyle(.orange)

        case .idle:
            EmptyView()
        }
    }
}

/// Dönüştürme seçenekleri için kapsül düğme görünümü.
private struct OptionPillStyle: ButtonStyle {
    let isRunning: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(Theme.text)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Capsule().fill(Color.white.opacity(0.14)))
            .opacity(isRunning ? 0.4 : (configuration.isPressed ? 0.7 : 1))
    }
}
