import Foundation

public protocol AeroSpaceCLIProtocol: Sendable {
    func runCommand(_ args: [String]) -> String?
}

public final class AeroSpaceCLI: AeroSpaceCLIProtocol, @unchecked Sendable {
    private let binaryPath: String?

    public init() {
        self.binaryPath = AeroSpaceCLI.resolvePath()
    }

    public init(binaryPath: String) {
        self.binaryPath = binaryPath
    }

    public func runCommand(_ args: [String]) -> String? {
        guard let path = binaryPath else { return nil }
        let process = Process()
        let pipe = Pipe()
        process.executableURL = URL(fileURLWithPath: path)
        process.arguments = args
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice
        do {
            try process.run()
            process.waitUntilExit()
            return String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8)?
                .trimmingCharacters(in: .whitespacesAndNewlines)
        } catch { return nil }
    }

    static func resolvePath() -> String? {
        let candidates = [
            "/opt/homebrew/bin/aerospace",
            "/usr/local/bin/aerospace",
            "/Applications/AeroSpace.app/Contents/MacOS/aerospace",
            ProcessInfo.processInfo.environment["HOME"].map { "\($0)/.local/bin/aerospace" },
        ].compactMap { $0 }

        for path in candidates {
            if FileManager.default.fileExists(atPath: path) { return path }
        }

        let w = Process()
        let wp = Pipe()
        w.executableURL = URL(fileURLWithPath: "/usr/bin/which")
        w.arguments = ["aerospace"]
        w.standardOutput = wp
        w.standardError = FileHandle.nullDevice
        do {
            try w.run(); w.waitUntilExit()
            if let p = String(data: wp.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8)?
                .trimmingCharacters(in: .whitespacesAndNewlines), !p.isEmpty { return p }
        } catch {}
        return nil
    }
}

public func fetchWorkspaces(cli: AeroSpaceCLIProtocol) -> [WorkspaceInfo] {
    WorkspaceParser.buildWorkspaces(
        allOutput: cli.runCommand(["list-workspaces", "--all"]),
        focusedOutput: cli.runCommand(["list-workspaces", "--focused"]),
        visibleOutput: cli.runCommand(["list-workspaces", "--monitor", "all", "--visible"]),
        windowsOutput: cli.runCommand(["list-windows", "--all", "--format", "%{app-name}\t%{window-title}\t%{workspace}"])
    )
}

public func switchToWorkspace(_ name: String, cli: AeroSpaceCLIProtocol) {
    _ = cli.runCommand(["workspace", name])
}
