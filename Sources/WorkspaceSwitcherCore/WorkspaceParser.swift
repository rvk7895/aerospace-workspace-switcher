import Foundation

public enum WorkspaceParser {
    public static func parseWorkspaceNames(_ output: String) -> [String] {
        output.split(separator: "\n")
            .map { String($0).trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }

    public static func parseVisibleNames(_ output: String?) -> Set<String> {
        guard let output else { return [] }
        return Set(parseWorkspaceNames(output))
    }

    public static func parseWindows(_ output: String?) -> [String: [WindowInfo]] {
        guard let output else { return [:] }
        var result: [String: [WindowInfo]] = [:]
        for line in output.split(separator: "\n") {
            let parts = line.split(separator: "\t", maxSplits: 2).map { String($0) }
            guard parts.count >= 3 else { continue }
            result[parts[2], default: []].append(WindowInfo(appName: parts[0], title: parts[1]))
        }
        return result
    }

    public static func buildWorkspaces(
        allOutput: String?,
        focusedOutput: String?,
        visibleOutput: String?,
        windowsOutput: String?
    ) -> [WorkspaceInfo] {
        guard let allOutput, !allOutput.isEmpty else { return [] }
        let names = parseWorkspaceNames(allOutput)
        let focused = focusedOutput?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let visible = parseVisibleNames(visibleOutput)
        let windows = parseWindows(windowsOutput)

        return names.map { name in
            WorkspaceInfo(
                name: name,
                isFocused: name == focused,
                isVisible: visible.contains(name),
                windows: windows[name] ?? []
            )
        }
    }
}
