import Foundation
import Observation
/// Görev: adanın durumu (medya, ajanlar, bırakılan dosya, dönüştürme).
@MainActor
@Observable
public final class IslandStore {
    public var isExpanded = false
    public private(set) var media: NowPlayingInfo?
    public private(set) var agents: [AgentActivity] = []
    public private(set) var droppedFile: URL?
    public private(set) var options: [ConversionOption] = []
    public private(set) var status: ConversionStatus = .idle

    private let nowPlaying: NowPlayingProvider
    private let agentMonitor: AgentMonitor
    private let converter: Converter
    private let ffmpegAvailable: Bool

    private var timer: Timer?
    private var refreshTask: Task<Void, Never>?

    public init(nowPlaying: NowPlayingProvider = NowPlayingProvider(),
                agentMonitor: AgentMonitor = AgentMonitor(),
                converter: Converter = Converter(),
                ffmpegAvailable: Bool? = nil) {
        self.nowPlaying = nowPlaying
        self.agentMonitor = agentMonitor
        self.converter = converter
        if let ffmpegAvailable {
            self.ffmpegAvailable = ffmpegAvailable
        } else {
            self.ffmpegAvailable =
                FileManager.default.isExecutableFile(atPath: "/opt/homebrew/bin/ffmpeg")
                || FileManager.default.isExecutableFile(atPath: "/usr/local/bin/ffmpeg")
        }
    }

    // MARK: - Yaşam döngüsü

    public func start() {
        guard refreshTask == nil else { return }
        refreshTask = Task { await refresh() }
        let timer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.refresh()
            }
        }
        timer.tolerance = 0
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    public func stop() {
        timer?.invalidate()
        timer = nil
        refreshTask?.cancel()
        refreshTask = nil
    }

    // MARK: - Tazeleme

    private var refreshing = false
    private var lastAgentSample = Date.distantPast

    public func refresh() async {
        guard !refreshing else { return }              // önceki tur bitmeden yenisini başlatma
        refreshing = true
        defer { refreshing = false }
        let provider = nowPlaying
        let info = await Task.detached {
            provider.current()
        }.value
        self.media = info
        if Date().timeIntervalSince(lastAgentSample) >= 5 {   // ajanlar 5 sn'de bir yeter
            lastAgentSample = Date()
            let monitor = agentMonitor
            self.agents = await Task.detached { await monitor.sample() }.value
        }
    }

    // MARK: - Dosya bırakma

    public func handleDrop(_ url: URL) {
        droppedFile = url
        options = ConversionCatalog.options(for: url, ffmpegAvailable: ffmpegAvailable)
        isExpanded = true
        if options.isEmpty {
            status = .failed("Bu dosya türü için dönüştürme yok: \(url.pathExtension.lowercased())")
        } else {
            status = .idle
        }
    }

    public func clearDrop() {
        droppedFile = nil
        options = []
        status = .idle
    }

    // MARK: - Dönüştürme

    public func convert(_ option: ConversionOption) async {
        guard let file = droppedFile else { return }
        status = .running("\(option.title) biçimine dönüştürülüyor…")
        do {
            let out = try await converter.convert(file, option: option)
            status = .done(out)
        } catch {
            status = .failed(error.localizedDescription)
        }
    }

    // MARK: - Medya kontrolü

    public func sendMedia(_ command: MediaCommand) {
        guard let media else { return }
        nowPlaying.send(command, to: media.app)
        Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(0.3))
            await self?.refresh()
        }
    }
}
