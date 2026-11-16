import Foundation
import Observation
/// Görev: adanın durumu (medya, ajanlar, bırakılan dosya, dönüştürme) (şu an yer tutucu).
@MainActor
@Observable
public final class IslandStore {
    public var isExpanded = false
    public private(set) var media: NowPlayingInfo?
    public private(set) var agents: [AgentActivity] = []
    public private(set) var droppedFile: URL?
    public private(set) var options: [ConversionOption] = []
    public private(set) var status: ConversionStatus = .idle
    public init(nowPlaying: NowPlayingProvider = NowPlayingProvider(), agentMonitor: AgentMonitor = AgentMonitor(),
                converter: Converter = Converter(), ffmpegAvailable: Bool? = nil) {}
    public func start() {}
    public func stop() {}
    public func refresh() async {}
    public func handleDrop(_ url: URL) {}
    public func clearDrop() {}
    public func convert(_ option: ConversionOption) async {}
    public func sendMedia(_ command: MediaCommand) {}
}
