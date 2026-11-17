import XCTest
@testable import IsletCore

final class AgentMonitorTests: XCTestCase {
    func testProcesses() {
        let ps = """
          101  12.5    02:13 /Users/u/.local/bin/claude --model sonnet
          102   0.0 01:02:03 /Users/u/Library/Application Support/Claude-Personal/claude-code/2.1/x/claude.app/Contents/MacOS/claude -p görev --bare
          107   0.0 01:02:03 /Applications/Claude.app/Contents/Helpers/disclaimer --pgroup -- /Users/u/Library/Application Support/Claude/claude-code/2.1/x/claude.app/Contents/MacOS/claude
          108   0.0    00:10 /bin/zsh -c source /Users/u/.claude/shell-snapshots/s.sh && cd /private/tmp/claude-501/x
          109   3.0    01:00 /Applications/Claude.app/Contents/Frameworks/Claude Helper (Renderer).app/Contents/MacOS/Claude Helper (Renderer) --type=renderer
          103   5.0    00:41 /usr/bin/python3 -I /Users/u/LocalLLM/agent-kit/bin/agent_run.py --repo /Users/u/Documents/GitHub/PulseBar --task /x/07-info.json
          104   0.0    10:00 /Users/u/Library/Application Support/ai.opencode.desktop/cli/2.3.0-arm64/opencode-cli serve --service
          110   0.4    03:00 /opt/homebrew/bin/opencode
          105   0.0    00:01 /bin/zsh -l
          106   0.0    00:05 grep claude
        """
        let a = AgentMonitor.parseProcesses(ps, subagents: 2)
        XCTAssertEqual(a.map(\.kind), [.claude, .agentRun, .opencode])
        XCTAssertEqual(a[0].name, "Claude Code")
        XCTAssertEqual(a[0].detail, "1 çalışıyor · 2 görev")
        XCTAssertTrue(a[0].isActive)
        XCTAssertEqual(a[1].name, "agent run")
        XCTAssertEqual(a[1].detail, "07-info · PulseBar")
        XCTAssertEqual(a[2].name, "OpenCode")
        XCTAssertEqual(a[2].detail, "1 oturum")
    }
    func testIdleClaudeAndOpenCodeService() {
        let ps = """
          201   0.1 02-17:57:40 /Users/u/Library/Application Support/Claude/claude-code/2.1/x/claude.app/Contents/MacOS/claude --output-format stream-json
          202   0.0 03-18:26:47 /Users/u/Library/Application Support/ai.opencode.desktop/cli/2.3.0-arm64/opencode-cli serve --service
        """
        let a = AgentMonitor.parseProcesses(ps)
        XCTAssertEqual(a.map(\.kind), [.claude])
        XCTAssertEqual(a[0].detail, "boşta")
        XCTAssertFalse(a[0].isActive)
        let waiting = AgentMonitor.parseProcesses(ps, subagents: 3)     // ana oturum subagent bekliyor
        XCTAssertEqual(waiting[0].detail, "3 görev")
        XCTAssertTrue(waiting[0].isActive)
    }
    func testActiveSubagents() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent("islet-sub-" + UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let now = Date(timeIntervalSince1970: 1_000_000)
        func write(_ path: String, age: TimeInterval, _ body: String = "{}") throws {
            let url = root.appendingPathComponent(path)
            try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            try Data(body.utf8).write(to: url)
            try FileManager.default.setAttributes([.modificationDate: now.addingTimeInterval(-age)], ofItemAtPath: url.path)
        }
        let bg = #"{"requestShape":"background"}"#
        try write("p1/s1/subagents/agent-a.jsonl", age: 5)
        try write("p1/s1/subagents/agent-a.meta.json", age: 5, bg)
        try write("p1/s1/subagents/agent-b.jsonl", age: 900)                       // uzun düşünüyor, hâlâ açık
        try write("p1/s1/subagents/agent-b.meta.json", age: 900, bg)
        try write("p1/s1/subagents/agent-c.jsonl", age: 5)                         // bitti: notu var
        try write("p1/s1/subagents/agent-c.meta.json", age: 5, bg)
        try write("p1/s1.jsonl", age: 1, #"{"text":"<task-id>c</task-id>"}"#)
        try write("p1/s1/subagents/agent-d.jsonl", age: 5)                         // ön planda (iç içe)
        try write("p1/s1/subagents/agent-d.meta.json", age: 5, #"{"requestShape":"foreground"}"#)
        try write("p2/s3/subagents/agent-e.jsonl", age: 7200)                      // eski, notsuz
        try write("p2/s3/subagents/agent-e.meta.json", age: 7200, bg)
        XCTAssertEqual(AgentMonitor.activeSubagents(in: root, now: now), 2)
        XCTAssertEqual(AgentMonitor.activeSubagents(in: root.appendingPathComponent("yok"), now: now), 0)
    }
    func testBackgroundCommands() {
        let out = "p12\nf1\nn/private/tmp/claude-501/x/s/tasks/b1.output\np13\nf1\nn/private/tmp/claude-501/x/s/tasks/b1.output\nf2\nn/private/tmp/claude-501/x/s/tasks/b2.output\nn/Users/u/.claude/projects/p/s/subagents/agent-a1.jsonl\nn/dev/ttys001\n"
        XCTAssertEqual(AgentMonitor.backgroundCommands(out), 2)
        let a = AgentMonitor.parseProcesses("1 0.0 01:00 claude\n", subagents: 1, commands: 2)
        XCTAssertEqual(a.first?.detail, "3 görev")
    }
    func testProxyStats() throws {
        let now = Date(timeIntervalSince1970: 1_000_000)
        let json = """
        {"loaded":[{"name":"qwen-code-256k:latest"}],
         "recent":[{"ts":999990,"model":"qwen-code-256k","output_tokens":120},{"ts":999970,"model":"qwen-code-256k","output_tokens":80},{"ts":999000,"model":"qwen-code-256k","output_tokens":5}]}
        """
        let a = AgentMonitor.parseProxyStats(Data(json.utf8), now: now)
        XCTAssertEqual(a.count, 1)
        XCTAssertEqual(a[0].kind, .qwen)
        XCTAssertEqual(a[0].name, "Qwen")
        XCTAssertEqual(a[0].detail, "2 istek / dk")
        XCTAssertTrue(a[0].isActive)
    }
    func testProxyIdleAndGemma() {
        let json = #"{"loaded":[{"name":"gemma4:31b-mlx"}],"recent":[]}"#
        let a = AgentMonitor.parseProxyStats(Data(json.utf8), now: Date())
        XCTAssertEqual(a.map(\.kind), [.gemma])
        XCTAssertEqual(a[0].detail, "yüklü, boşta")
        XCTAssertFalse(a[0].isActive)
        XCTAssertEqual(AgentMonitor.parseProxyStats(Data("bozuk".utf8), now: Date()), [])
    }
}
