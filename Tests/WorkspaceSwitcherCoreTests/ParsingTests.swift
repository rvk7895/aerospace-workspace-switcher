import Testing
@testable import WorkspaceSwitcherCore

@Suite struct ParsingTests {

    @Test func parseWorkspaceNames() {
        let input = "1\n2\n3\nB\nC"
        #expect(WorkspaceParser.parseWorkspaceNames(input) == ["1", "2", "3", "B", "C"])
    }

    @Test func parseWorkspaceNamesEmpty() {
        #expect(WorkspaceParser.parseWorkspaceNames("") == [])
    }

    @Test func parseWorkspaceNamesTrimsWhitespace() {
        let input = "  1  \n  2  \n"
        #expect(WorkspaceParser.parseWorkspaceNames(input) == ["1", "2"])
    }

    @Test func parseVisibleNames() {
        let input = "3\nC"
        #expect(WorkspaceParser.parseVisibleNames(input) == Set(["3", "C"]))
    }

    @Test func parseVisibleNamesNil() {
        #expect(WorkspaceParser.parseVisibleNames(nil) == Set<String>())
    }

    @Test func parseWindows() {
        let input = "Ghostty\tClaude Code\t4\nGhostty\tvim .\t7"
        let result = WorkspaceParser.parseWindows(input)
        #expect(result["4"]?.count == 1)
        #expect(result["4"]?.first?.appName == "Ghostty")
        #expect(result["4"]?.first?.title == "Claude Code")
        #expect(result["7"]?.count == 1)
    }

    @Test func parseWindowsMultipleInSameWorkspace() {
        let input = "WhatsApp\tSoftware Update\tV\nWhatsApp\tWhatsApp\tV"
        let result = WorkspaceParser.parseWindows(input)
        #expect(result["V"]?.count == 2)
    }

    @Test func parseWindowsEmpty() {
        #expect(WorkspaceParser.parseWindows(nil).count == 0)
    }

    @Test func parseWindowsMalformedLineSkipped() {
        let input = "Ghostty\tClaude Code\t4\nmalformed-no-tabs\nCursor\tcli.py\t6"
        let result = WorkspaceParser.parseWindows(input)
        #expect(result.count == 2)
        #expect(result["4"] != nil)
        #expect(result["6"] != nil)
    }

    @Test func buildWorkspaces() {
        let result = WorkspaceParser.buildWorkspaces(
            allOutput: "1\n2\n3",
            focusedOutput: "2",
            visibleOutput: "2\n3",
            windowsOutput: "Ghostty\tClaude Code\t2"
        )
        #expect(result.count == 3)
        #expect(result[0].name == "1")
        #expect(!result[0].isFocused)
        #expect(!result[0].isVisible)
        #expect(result[0].windows.isEmpty)
        #expect(result[1].name == "2")
        #expect(result[1].isFocused)
        #expect(result[1].isVisible)
        #expect(result[1].windows.count == 1)
        #expect(result[2].isVisible)
        #expect(!result[2].isFocused)
    }

    @Test func buildWorkspacesNilAllOutput() {
        let result = WorkspaceParser.buildWorkspaces(
            allOutput: nil, focusedOutput: nil, visibleOutput: nil, windowsOutput: nil
        )
        #expect(result.count == 0)
    }

    @Test func parseFromFixtures() throws {
        let allText = try FixtureLoader.loadFixture("workspaces-all")
        let focusedText = try FixtureLoader.loadFixture("workspaces-focused")
        let visibleText = try FixtureLoader.loadFixture("workspaces-visible")
        let windowsText = try FixtureLoader.loadFixture("windows-all")

        let result = WorkspaceParser.buildWorkspaces(
            allOutput: allText,
            focusedOutput: focusedText,
            visibleOutput: visibleText,
            windowsOutput: windowsText
        )
        #expect(result.count == 15)

        let ws3 = result.first { $0.name == "3" }!
        #expect(ws3.isFocused)
        #expect(ws3.isVisible)
        #expect(ws3.windows.count == 1)
        #expect(ws3.windows[0].appName == "Ghostty")

        let wsC = result.first { $0.name == "C" }!
        #expect(wsC.isVisible)
        #expect(!wsC.isFocused)

        let wsV = result.first { $0.name == "V" }!
        #expect(wsV.windows.count == 2)

        let ws1 = result.first { $0.name == "1" }!
        #expect(!ws1.isFocused)
        #expect(!ws1.isVisible)
        #expect(ws1.windows.isEmpty)
    }
}
