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
        let a = AgentMonitor.parseProcesses(ps)
        XCTAssertEqual(a.map(\.kind), [.claude, .agentRun, .opencode])
        XCTAssertEqual(a[0].name, "Claude Code")
        XCTAssertEqual(a[0].detail, "1 çalışıyor · 2 açık")
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
        XCTAssertEqual(a[0].detail, "1 açık, boşta")
        XCTAssertFalse(a[0].isActive)
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
