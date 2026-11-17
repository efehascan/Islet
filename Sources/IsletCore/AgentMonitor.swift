import Foundation

private enum AgentMonitorError: Error { case noData }

/// Görev: çalışan ajanları (süreçler + proxy istatistiği) bul.
public final class AgentMonitor {
    private let proxyURL: URL
    /// Claude Code oturum kayıtlarının kökü; subagent kayıtları `<proje>/<oturum>/subagents/*.jsonl`
    private let projectsRoot: URL
    public init(proxyURL: URL = URL(string: "http://localhost:11435/stats")!,
                projectsRoot: URL = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".claude/projects")) {
        self.proxyURL = proxyURL
        self.projectsRoot = projectsRoot
    }

    public func sample() async -> [AgentActivity] {
        var result: [AgentActivity] = []
        result.append(contentsOf: proxyStats())
        result.append(contentsOf: AgentMonitor.parseProcesses(run("/bin/ps", ["-axo", "pid=,pcpu=,etime=,command="]),
                                                         subagents: AgentMonitor.activeSubagents(in: projectsRoot, now: Date()),
                                                         commands: AgentMonitor.backgroundCommands(run("/usr/sbin/lsof", ["-nP", "-w", "-a", "-d", "1,2", "-Fn"]))))
        return result
    }

    /// Bir Claude Code oturumunu "çalışıyor" saymak için gereken CPU kullanımı (%)
    static let busyCPU = 1.0

    /// Komut satırındaki çalıştırılabilir dosyanın adı: ilk " -" bayrağına kadar olan yolun son parçası.
    /// (Yolda boşluk olabilir: "Application Support". Argümanlardaki yollar sayılmaz.)
    static func executableName(_ command: String) -> String {
        let path = command.range(of: " -").map { String(command[..<$0.lowerBound]) } ?? command
        return (path.trimmingCharacters(in: .whitespaces) as NSString).lastPathComponent
    }

    /// Bu kadar süredir yazılmayan subagent kaydı (bitiş notu düşmese de) kapanmış sayılır.
    static let subagentStale: TimeInterval = 3600

    /// Arka planda çalışan subagent sayısı (Claude uygulamasındaki "Arka plan görevleri" ile aynı tanım).
    /// Her subagent `<kök>/<proje>/<oturum>/subagents/agent-<id>.jsonl` kaydına yazar; `.meta.json`
    /// `requestShape: "background"` ise arka plandadır. Bitince ana oturum kaydına
    /// `<task-id><id></task-id>` notu düşer; notu olmayan ve son bir saatte yazılmış olanlar çalışıyor.
    public static func activeSubagents(in root: URL, now: Date) -> Int {
        let fm = FileManager.default
        var count = 0
        for project in (try? fm.contentsOfDirectory(at: root, includingPropertiesForKeys: nil)) ?? [] {
            for session in (try? fm.contentsOfDirectory(at: project, includingPropertiesForKeys: nil)) ?? [] {
                let dir = session.appendingPathComponent("subagents")
                let files = (try? fm.contentsOfDirectory(at: dir, includingPropertiesForKeys: [.contentModificationDateKey])) ?? []
                var parentLog: String?
                for file in files where file.pathExtension == "jsonl" {
                    guard let date = try? file.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate,
                          now.timeIntervalSince(date) <= subagentStale else { continue }
                    let base = file.deletingPathExtension()
                    guard let meta = try? Data(contentsOf: base.appendingPathExtension("meta.json")),
                          let json = try? JSONSerialization.jsonObject(with: meta) as? [String: Any],
                          json["requestShape"] as? String == "background" else { continue }
                    let id = String(base.lastPathComponent.dropFirst("agent-".count))
                    if parentLog == nil {
                        parentLog = (try? String(contentsOf: session.appendingPathExtension("jsonl"), encoding: .utf8)) ?? ""
                    }
                    if parentLog?.contains("<task-id>\(id)</task-id>") == true { continue }
                    count += 1
                }
            }
        }
        return count
    }

    /// `lsof -Fn` çıktısından arka planda çalışan komut sayısı: Claude'un arka plan komutları
    /// çıktısını `.../tasks/<id>.output` dosyasına yazar; dosya açıkken komut sürüyor demektir.
    public static func backgroundCommands(_ lsofOutput: String) -> Int {
        var files = Set<Substring>()
        for line in lsofOutput.split(separator: "\n") where line.hasPrefix("n") && line.hasSuffix(".output") {
            let name = line.split(separator: "/").last ?? ""
            if line.contains("/tasks/") && name.first == "b" { files.insert(line) }
        }
        return files.count
    }

    /// `ps -axo pid=,pcpu=,etime=,command=` çıktısından ajan süreçleri; `subagents`: açık subagent sayısı
    public static func parseProcesses(_ psOutput: String, subagents: Int = 0, commands: Int = 0) -> [AgentActivity] {
        var claudeSessions = 0
        var claudeBusy = 0
        var agentRuns: [AgentActivity] = []
        var opencodeCount = 0

        for line in psOutput.split(whereSeparator: { $0 == "\n" }) {
            let fields = line.split(separator: " ", maxSplits: 3, omittingEmptySubsequences: true)
            guard fields.count == 4, let pid = Int(fields[0]) else { continue }
            let cpu = Double(fields[1].replacingOccurrences(of: ",", with: ".")) ?? 0
            let command = String(fields[3])
            let exe = executableName(command)

            if exe == "claude" {
                // Sadece claude ikilisinin kendisi; onu başlatan sarmalayıcılar (disclaimer) ve
                // yolunda "claude" geçen kabuklar sayılmaz.
                claudeSessions += 1
                if cpu >= busyCPU { claudeBusy += 1 }
            } else if command.contains("agent_run.py") {
                var detail = ""
                if let taskFile = argument("task", in: command) {
                    detail = ((taskFile as NSString).lastPathComponent as NSString).deletingPathExtension
                }
                if let repo = argument("repo", in: command) {
                    let folder = (repo as NSString).lastPathComponent
                    detail += detail.isEmpty ? folder : " · \(folder)"
                }
                agentRuns.append(AgentActivity(id: "run-\(pid)", kind: .agentRun,
                                              name: "agent run", detail: detail, isActive: true))
            } else if exe.hasPrefix("opencode") && !command.contains(" serve") {
                // Arka plan servisi (`opencode-cli serve`) ajan değildir; sadece açık oturumlar.
                opencodeCount += 1
            }
        }

        var result: [AgentActivity] = []
        if claudeSessions > 0 {
            var parts: [String] = []
            if claudeBusy > 0 { parts.append("\(claudeBusy) çalışıyor") }
            if subagents > 0 { parts.append("\(subagents) subagent") }
            if commands > 0 { parts.append("\(commands) komut") }
            let detail = parts.isEmpty ? "boşta" : parts.joined(separator: " · ")
            result.append(AgentActivity(id: "claude", kind: .claude, name: "Claude Code",
                                        detail: detail, isActive: claudeBusy > 0 || subagents > 0 || commands > 0))
        }
        result.append(contentsOf: agentRuns)
        if opencodeCount > 0 {
            result.append(AgentActivity(id: "opencode", kind: .opencode, name: "OpenCode",
                                        detail: "\(opencodeCount) oturum", isActive: true))
        }
        return result
    }

    /// Proxy /stats JSON'undan yüklü model ve son dakikadaki istek etkinliği
    public static func parseProxyStats(_ data: Data, now: Date) -> [AgentActivity] {
        guard let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let loaded = obj["loaded"] as? [[String: Any]] else {
            return []
        }
        var result: [AgentActivity] = []
        if let first = loaded.first, let name = first["name"] as? String {
            let kind: AgentKind
            let displayName: String
            if name.contains("gemma") {
                kind = .gemma; displayName = "Gemma"
            } else {
                kind = .qwen; displayName = "Qwen"
            }
            let nowTime = now.timeIntervalSince1970
            let recent = (obj["recent"] as? [[String: Any]]) ?? []
            let count = recent.filter { entry in
                guard let ts = (entry["ts"] as? Double) ?? (entry["ts"] as? NSNumber)?.doubleValue
                else { return false }
                return ts >= nowTime - 60
            }.count
            let detail = count > 0 ? "\(count) istek / dk" : "yüklü, boşta"
            result.append(AgentActivity(id: "proxy-\(kind)", kind: kind, name: displayName,
                                        detail: detail, isActive: count > 0))
        }
        return result
    }

    // MARK: - Yardımcılar

    private func proxyStats() -> [AgentActivity] {
        var request = URLRequest(url: proxyURL)
        request.timeoutInterval = 1
        guard let data = try? Self.fetch(urlRequest: request) else { return [] }
        return AgentMonitor.parseProxyStats(data, now: Date())
    }

    /// Veri ağ çakışması olmadan okunabilsin diye senkron yardımcı.
    private static func fetch(urlRequest: URLRequest) throws -> Data {
        let semaphore = DispatchSemaphore(value: 0)
        var result: Data?
        var error: Error?
        let task = URLSession.shared.dataTask(with: urlRequest) { data, _, err in
            result = data; error = err; semaphore.signal()
        }
        task.resume()
        semaphore.wait()
        if let error { throw error }
        guard let result else { throw AgentMonitorError.noData }
        return result
    }

    private func run(_ path: String, _ arguments: [String]) -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: path)
        process.arguments = arguments
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()
        do {
            try process.run()
        } catch {
            return ""
        }
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        return String(data: data, encoding: .utf8) ?? ""
    }

    /// `--anahtar değer` biçiminde bir argümanın değerini döndürür.
    private static func argument(_ key: String, in command: String) -> String? {
        // Bütün komut satırı bölünür (en çok 3 parçaya bölmek bayrakları hiç bulamıyordu)
        let flag = Substring("--\(key)")
        let fields = command.split(separator: " ", omittingEmptySubsequences: true)
        guard let idx = fields.firstIndex(of: flag), idx + 1 < fields.count else {
            return nil
        }
        return String(fields[idx + 1])
    }
}
