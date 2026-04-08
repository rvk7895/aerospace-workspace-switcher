import Foundation

public enum WorkspaceFilter {
    public static func defaultFilter(_ workspaces: [WorkspaceInfo]) -> [WorkspaceInfo] {
        workspaces.filter { $0.isRelevant }
    }

    public static func search(_ workspaces: [WorkspaceInfo], query: String) -> [WorkspaceInfo] {
        guard !query.isEmpty else { return defaultFilter(workspaces) }
        let lq = query.lowercased()
        return workspaces.filter { ws in
            ws.nameLower.contains(lq) ||
            ws.windows.contains { $0.appNameLower.contains(lq) || $0.titleLower.contains(lq) }
        }
    }
}
