@testable import WorkspaceSwitcherCore

extension WindowInfo {
    static func stub(appName: String = "TestApp", title: String = "Test Window") -> WindowInfo {
        WindowInfo(appName: appName, title: title)
    }
}

extension WorkspaceInfo {
    static func stub(
        name: String = "1",
        isFocused: Bool = false,
        isVisible: Bool = false,
        windows: [WindowInfo] = []
    ) -> WorkspaceInfo {
        WorkspaceInfo(name: name, isFocused: isFocused, isVisible: isVisible, windows: windows)
    }
}
