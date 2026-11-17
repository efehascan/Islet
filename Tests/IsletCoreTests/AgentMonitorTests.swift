import XCTest
@testable import IsletCore

final class AgentMonitorTests: XCTestCase {
    func testProcesses() {
        let ps = """
          101    02:13 /Users/u/.local/bin/claude --model sonnet
          102 01:02:03 /Users/u/Library/Application Support/Claude-Personal/claude-code/2.1/x/claude.app/Contents/MacOS/claude -p görev --bare
          103    00:41 /usr/bin/python3 -I /Users/u/LocalLLM/agent-kit/bin/agent_run.py --repo /Users/u/Documents/GitHub/PulseBar --task /x/07-info.json
          104    10:00 /Applications/OpenCode.app/Contents/MacOS/opencode-cli serve
          105    00:01 /bin/zsh -l
          106    00:05 grep claude
        """
        let a = AgentMonitor.parseProcesses(ps)
        XCTAssertEqual(a.map(\.kind), [.claude, .agentRun, .opencode])
        XCTAssertEqual(a[0].name, "Claude Code")
        XCTAssertEqual(a[0].detail, "2 oturum")
        XCTAssertEqual(a[1].name, "agent run")
        XCTAssertEqual(a[1].detail, "07-info · PulseBar")
        XCTAssertEqual(a[2].name, "OpenCode")
        XCTAssert(a.allSatisfy(\.isActive))
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
