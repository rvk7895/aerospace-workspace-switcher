import Foundation

public struct WindowInfo: Sendable {
    public let appName: String
    public let title: String
    public let appNameLower: String
    public let titleLower: String

    public init(appName: String, title: String) {
        self.appName = appName
        self.title = title
        self.appNameLower = appName.lowercased()
        self.titleLower = title.lowercased()
    }
}

public struct WorkspaceInfo: Sendable {
    public let name: String
    public let nameLower: String
    public let isFocused: Bool
    public let isVisible: Bool
    public let windows: [WindowInfo]

    public init(name: String, isFocused: Bool, isVisible: Bool, windows: [WindowInfo]) {
        self.name = name
        self.nameLower = name.lowercased()
        self.isFocused = isFocused
        self.isVisible = isVisible
        self.windows = windows
    }

    public var hasWindows: Bool { !windows.isEmpty }
    public var isRelevant: Bool { hasWindows || isFocused || isVisible }

    public var appSummary: String {
        var appCounts: [(String, Int)] = []
        var seen: [String: Int] = [:]
        for win in windows {
            if let idx = seen[win.appName] { appCounts[idx].1 += 1 }
            else { seen[win.appName] = appCounts.count; appCounts.append((win.appName, 1)) }
        }
        return appCounts.map { $1 > 1 ? "\($0) (\($1))" : $0 }.joined(separator: ", ")
    }

    public var titleSummary: String {
        windows.map { $0.title }.filter { !$0.isEmpty }.joined(separator: "  \u{00b7}  ")
    }
}
