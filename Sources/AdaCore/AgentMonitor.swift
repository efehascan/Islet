import Foundation
/// Görev: çalışan ajanları (süreçler + proxy istatistiği) bul (şu an yer tutucu).
public final class AgentMonitor {
    public init(proxyURL: URL = URL(string: "http://localhost:11435/stats")!) {}
    public func sample() async -> [AgentActivity] { [] }
    /// `ps -axo pid=,etime=,command=` çıktısından ajan süreçleri
    public static func parseProcesses(_ psOutput: String) -> [AgentActivity] { [] }
    /// Proxy /stats JSON'undan yüklü model ve son dakikadaki istek etkinliği
    public static func parseProxyStats(_ data: Data, now: Date) -> [AgentActivity] { [] }
}
