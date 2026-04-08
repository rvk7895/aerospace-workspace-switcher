import Testing
@testable import WorkspaceSwitcherCore

@Suite struct ModelsTests {

    @Test func windowInfoStoresLowercasedFields() {
        let win = WindowInfo(appName: "Ghostty", title: "Claude Code")
        #expect(win.appNameLower == "ghostty")
        #expect(win.titleLower == "claude code")
    }

    @Test func hasWindowsWhenNonEmpty() {
        let ws = WorkspaceInfo.stub(windows: [.stub()])
        #expect(ws.hasWindows)
    }

    @Test func hasWindowsWhenEmpty() {
        let ws = WorkspaceInfo.stub(windows: [])
        #expect(!ws.hasWindows)
    }

    @Test func isRelevantWhenHasWindows() {
        let ws = WorkspaceInfo.stub(isFocused: false, isVisible: false, windows: [.stub()])
        #expect(ws.isRelevant)
    }

    @Test func isRelevantWhenFocusedButEmpty() {
        let ws = WorkspaceInfo.stub(isFocused: true, isVisible: false, windows: [])
        #expect(ws.isRelevant)
    }

    @Test func isRelevantWhenVisibleButEmpty() {
        let ws = WorkspaceInfo.stub(isFocused: false, isVisible: true, windows: [])
        #expect(ws.isRelevant)
    }

    @Test func notRelevantWhenEmptyAndNotFocusedOrVisible() {
        let ws = WorkspaceInfo.stub(isFocused: false, isVisible: false, windows: [])
        #expect(!ws.isRelevant)
    }

    @Test func appSummarySingleApp() {
        let ws = WorkspaceInfo.stub(windows: [.stub(appName: "Safari")])
        #expect(ws.appSummary == "Safari")
    }

    @Test func appSummaryMultipleWindowsSameApp() {
        let ws = WorkspaceInfo.stub(windows: [
            .stub(appName: "Ghostty"), .stub(appName: "Ghostty"), .stub(appName: "Ghostty"),
        ])
        #expect(ws.appSummary == "Ghostty (3)")
    }

    @Test func appSummaryMixedApps() {
        let ws = WorkspaceInfo.stub(windows: [
            .stub(appName: "Ghostty"), .stub(appName: "Cursor"), .stub(appName: "Ghostty"),
        ])
        #expect(ws.appSummary == "Ghostty (2), Cursor")
    }

    @Test func appSummaryPreservesOrder() {
        let ws = WorkspaceInfo.stub(windows: [
            .stub(appName: "Cursor"), .stub(appName: "Safari"), .stub(appName: "Ghostty"),
        ])
        #expect(ws.appSummary == "Cursor, Safari, Ghostty")
    }

    @Test func appSummaryEmpty() {
        let ws = WorkspaceInfo.stub(windows: [])
        #expect(ws.appSummary == "")
    }

    @Test func titleSummaryJoinsTitles() {
        let ws = WorkspaceInfo.stub(windows: [.stub(title: "main.swift"), .stub(title: "README.md")])
        #expect(ws.titleSummary == "main.swift  \u{00b7}  README.md")
    }

    @Test func titleSummaryFiltersEmptyTitles() {
        let ws = WorkspaceInfo.stub(windows: [
            .stub(title: "main.swift"), .stub(title: ""), .stub(title: "README.md"),
        ])
        #expect(ws.titleSummary == "main.swift  \u{00b7}  README.md")
    }

    @Test func titleSummaryAllEmpty() {
        let ws = WorkspaceInfo.stub(windows: [.stub(title: ""), .stub(title: "")])
        #expect(ws.titleSummary == "")
    }
}
