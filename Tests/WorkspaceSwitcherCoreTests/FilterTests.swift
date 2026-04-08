import Testing
@testable import WorkspaceSwitcherCore

@Suite struct FilterTests {
    let workspaces: [WorkspaceInfo] = [
        .stub(name: "1", isFocused: false, isVisible: false, windows: []),
        .stub(name: "2", isFocused: false, isVisible: false, windows: [.stub(appName: "Obsidian", title: "Vault")]),
        .stub(name: "3", isFocused: true, isVisible: true, windows: [.stub(appName: "Ghostty", title: "Claude Code")]),
        .stub(name: "C", isFocused: false, isVisible: true, windows: [.stub(appName: "Spotify", title: "Premium")]),
        .stub(name: "V", isFocused: false, isVisible: false, windows: [
            .stub(appName: "WhatsApp", title: "Software Update"),
            .stub(appName: "WhatsApp", title: "Chat"),
        ]),
    ]

    @Test func defaultFilterExcludesEmptyNonFocusedNonVisible() {
        let result = WorkspaceFilter.defaultFilter(workspaces)
        let names = result.map { $0.name }
        #expect(!names.contains("1"))
        #expect(names.contains("2"))
        #expect(names.contains("3"))
        #expect(names.contains("C"))
        #expect(names.contains("V"))
    }

    @Test func searchByWorkspaceName() {
        let result = WorkspaceFilter.search(workspaces, query: "C")
        let names = result.map { $0.name }
        #expect(names.contains("C"))
        #expect(names.contains("3")) // "Claude Code" contains "c"
    }

    @Test func searchByAppName() {
        let result = WorkspaceFilter.search(workspaces, query: "ghostty")
        #expect(result.count == 1)
        #expect(result[0].name == "3")
    }

    @Test func searchByWindowTitle() {
        let result = WorkspaceFilter.search(workspaces, query: "vault")
        #expect(result.count == 1)
        #expect(result[0].name == "2")
    }

    @Test func searchCaseInsensitive() {
        let result = WorkspaceFilter.search(workspaces, query: "SPOTIFY")
        #expect(result.count == 1)
        #expect(result[0].name == "C")
    }

    @Test func searchNoResults() {
        let result = WorkspaceFilter.search(workspaces, query: "zzzzz")
        #expect(result.count == 0)
    }

    @Test func searchEmptyQueryReturnsDefaultFiltered() {
        let result = WorkspaceFilter.search(workspaces, query: "")
        #expect(result.count == 4) // excludes workspace "1"
    }

    @Test func searchPartialMatch() {
        let result = WorkspaceFilter.search(workspaces, query: "clau")
        #expect(result.count == 1)
        #expect(result[0].name == "3")
    }

    @Test func searchIncludesEmptyWorkspacesWhenNameMatches() {
        let result = WorkspaceFilter.search(workspaces, query: "1")
        #expect(result.contains { $0.name == "1" })
    }
}
