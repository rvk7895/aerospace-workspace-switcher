# SPM Restructure Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Restructure the single-file workspace switcher into an SPM package with a testable library target and comprehensive tests.

**Architecture:** Split into `WorkspaceSwitcherCore` (library: models, parsing, filtering, CLI protocol) and `aerospace-workspace-switcher` (executable: AppKit UI + entry point). Tests cover the library via mock CLI injection.

**Tech Stack:** Swift, SPM, XCTest, AppKit (executable only), Foundation (library only)

---

### Task 1: Create SPM Package.swift and directory structure

**Files:**
- Create: `Package.swift`
- Create: `Sources/WorkspaceSwitcherCore/` (empty dir)
- Create: `Sources/aerospace-workspace-switcher/` (empty dir)
- Create: `Tests/WorkspaceSwitcherCoreTests/` (empty dir)
- Create: `Tests/WorkspaceSwitcherCoreTests/Fixtures/` (empty dir)

**Step 1: Create Package.swift**

```swift
// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "aerospace-workspace-switcher",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "aerospace-workspace-switcher", targets: ["aerospace-workspace-switcher"]),
        .library(name: "WorkspaceSwitcherCore", targets: ["WorkspaceSwitcherCore"]),
    ],
    targets: [
        .target(
            name: "WorkspaceSwitcherCore"
        ),
        .executableTarget(
            name: "aerospace-workspace-switcher",
            dependencies: ["WorkspaceSwitcherCore"]
        ),
        .testTarget(
            name: "WorkspaceSwitcherCoreTests",
            dependencies: ["WorkspaceSwitcherCore"],
            resources: [.copy("Fixtures")]
        ),
    ]
)
```

**Step 2: Create directory structure**

```bash
mkdir -p Sources/WorkspaceSwitcherCore
mkdir -p Sources/aerospace-workspace-switcher
mkdir -p Tests/WorkspaceSwitcherCoreTests/Fixtures
```

**Step 3: Create placeholder files so SPM resolves**

Create `Sources/WorkspaceSwitcherCore/Models.swift`:
```swift
// Placeholder
```

Create `Sources/aerospace-workspace-switcher/main.swift`:
```swift
import Foundation
print("placeholder")
```

Create `Tests/WorkspaceSwitcherCoreTests/PlaceholderTests.swift`:
```swift
import XCTest
@testable import WorkspaceSwitcherCore

final class PlaceholderTests: XCTestCase {
    func testPlaceholder() {
        XCTAssertTrue(true)
    }
}
```

**Step 4: Verify SPM resolves**

```bash
swift build
swift test
```

Expected: Both pass.

**Step 5: Commit**

```bash
git add Package.swift Sources/ Tests/
git commit -m "chore: scaffold SPM package structure"
```

---

### Task 2: Extract Models into library

**Files:**
- Create: `Sources/WorkspaceSwitcherCore/Models.swift`

**Step 1: Write failing tests for models**

Create `Tests/WorkspaceSwitcherCoreTests/ModelsTests.swift`:

```swift
import XCTest
@testable import WorkspaceSwitcherCore

final class ModelsTests: XCTestCase {

    // MARK: - WindowInfo

    func testWindowInfoStoresLowercasedFields() {
        let win = WindowInfo(appName: "Ghostty", title: "Claude Code")
        XCTAssertEqual(win.appNameLower, "ghostty")
        XCTAssertEqual(win.titleLower, "claude code")
    }

    // MARK: - WorkspaceInfo.hasWindows

    func testHasWindowsWhenNonEmpty() {
        let ws = WorkspaceInfo.stub(windows: [.stub()])
        XCTAssertTrue(ws.hasWindows)
    }

    func testHasWindowsWhenEmpty() {
        let ws = WorkspaceInfo.stub(windows: [])
        XCTAssertFalse(ws.hasWindows)
    }

    // MARK: - WorkspaceInfo.isRelevant

    func testIsRelevantWhenHasWindows() {
        let ws = WorkspaceInfo.stub(isFocused: false, isVisible: false, windows: [.stub()])
        XCTAssertTrue(ws.isRelevant)
    }

    func testIsRelevantWhenFocusedButEmpty() {
        let ws = WorkspaceInfo.stub(isFocused: true, isVisible: false, windows: [])
        XCTAssertTrue(ws.isRelevant)
    }

    func testIsRelevantWhenVisibleButEmpty() {
        let ws = WorkspaceInfo.stub(isFocused: false, isVisible: true, windows: [])
        XCTAssertTrue(ws.isRelevant)
    }

    func testNotRelevantWhenEmptyAndNotFocusedOrVisible() {
        let ws = WorkspaceInfo.stub(isFocused: false, isVisible: false, windows: [])
        XCTAssertFalse(ws.isRelevant)
    }

    // MARK: - WorkspaceInfo.appSummary

    func testAppSummarySingleApp() {
        let ws = WorkspaceInfo.stub(windows: [.stub(appName: "Safari")])
        XCTAssertEqual(ws.appSummary, "Safari")
    }

    func testAppSummaryMultipleWindowsSameApp() {
        let ws = WorkspaceInfo.stub(windows: [
            .stub(appName: "Ghostty"),
            .stub(appName: "Ghostty"),
            .stub(appName: "Ghostty"),
        ])
        XCTAssertEqual(ws.appSummary, "Ghostty (3)")
    }

    func testAppSummaryMixedApps() {
        let ws = WorkspaceInfo.stub(windows: [
            .stub(appName: "Ghostty"),
            .stub(appName: "Cursor"),
            .stub(appName: "Ghostty"),
        ])
        XCTAssertEqual(ws.appSummary, "Ghostty (2), Cursor")
    }

    func testAppSummaryPreservesOrder() {
        let ws = WorkspaceInfo.stub(windows: [
            .stub(appName: "Cursor"),
            .stub(appName: "Safari"),
            .stub(appName: "Ghostty"),
        ])
        XCTAssertEqual(ws.appSummary, "Cursor, Safari, Ghostty")
    }

    func testAppSummaryEmpty() {
        let ws = WorkspaceInfo.stub(windows: [])
        XCTAssertEqual(ws.appSummary, "")
    }

    // MARK: - WorkspaceInfo.titleSummary

    func testTitleSummaryJoinsTitles() {
        let ws = WorkspaceInfo.stub(windows: [
            .stub(title: "main.swift"),
            .stub(title: "README.md"),
        ])
        XCTAssertEqual(ws.titleSummary, "main.swift  \u{00b7}  README.md")
    }

    func testTitleSummaryFiltersEmptyTitles() {
        let ws = WorkspaceInfo.stub(windows: [
            .stub(title: "main.swift"),
            .stub(title: ""),
            .stub(title: "README.md"),
        ])
        XCTAssertEqual(ws.titleSummary, "main.swift  \u{00b7}  README.md")
    }

    func testTitleSummaryAllEmpty() {
        let ws = WorkspaceInfo.stub(windows: [.stub(title: ""), .stub(title: "")])
        XCTAssertEqual(ws.titleSummary, "")
    }
}
```

Create `Tests/WorkspaceSwitcherCoreTests/TestHelpers.swift`:

```swift
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
```

**Step 2: Run tests to verify they fail**

```bash
swift test 2>&1 | head -30
```

Expected: Compilation errors — `WindowInfo`, `WorkspaceInfo` not found.

**Step 3: Write Models.swift**

Create `Sources/WorkspaceSwitcherCore/Models.swift`:

```swift
import Foundation

public struct WindowInfo {
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

public struct WorkspaceInfo {
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
```

**Step 4: Run tests to verify they pass**

```bash
swift test
```

Expected: All ModelsTests pass.

**Step 5: Commit**

```bash
git add Sources/WorkspaceSwitcherCore/Models.swift Tests/
git commit -m "feat: extract models into library with tests"
```

---

### Task 3: Extract CLI protocol and parsing

**Files:**
- Create: `Sources/WorkspaceSwitcherCore/AeroSpaceCLI.swift`
- Create: `Sources/WorkspaceSwitcherCore/WorkspaceParser.swift`
- Create: `Tests/WorkspaceSwitcherCoreTests/Fixtures/workspaces-all.txt`
- Create: `Tests/WorkspaceSwitcherCoreTests/Fixtures/workspaces-focused.txt`
- Create: `Tests/WorkspaceSwitcherCoreTests/Fixtures/workspaces-visible.txt`
- Create: `Tests/WorkspaceSwitcherCoreTests/Fixtures/windows-all.txt`

**Step 1: Create test fixtures from real CLI output format**

`Tests/WorkspaceSwitcherCoreTests/Fixtures/workspaces-all.txt`:
```
1
2
3
4
5
6
7
8
9
0
B
C
N
V
X
```

`Tests/WorkspaceSwitcherCoreTests/Fixtures/workspaces-focused.txt`:
```
3
```

`Tests/WorkspaceSwitcherCoreTests/Fixtures/workspaces-visible.txt`:
```
3
C
```

`Tests/WorkspaceSwitcherCoreTests/Fixtures/windows-all.txt`:
```
Obsidian	Obsidian Vault - Obsidian 1.12.7	2
Ghostty	Build omni-document LLM knowledge system	3
Ghostty	Claude Code	4
Ghostty	Add workspace switcher menu to aerospace	5
Cursor	cli.py — anyrun	6
Ghostty	vim .	7
Spotify	Spotify Premium	C
WhatsApp	Software Update	V
WhatsApp	WhatsApp	V
```

**Step 2: Write failing tests for parsing**

Create `Tests/WorkspaceSwitcherCoreTests/ParsingTests.swift`:

```swift
import XCTest
@testable import WorkspaceSwitcherCore

final class ParsingTests: XCTestCase {

    // MARK: - parseWorkspaceNames

    func testParseWorkspaceNames() {
        let input = "1\n2\n3\nB\nC"
        XCTAssertEqual(WorkspaceParser.parseWorkspaceNames(input), ["1", "2", "3", "B", "C"])
    }

    func testParseWorkspaceNamesEmpty() {
        XCTAssertEqual(WorkspaceParser.parseWorkspaceNames(""), [])
    }

    func testParseWorkspaceNamesTrimsWhitespace() {
        let input = "  1  \n  2  \n"
        XCTAssertEqual(WorkspaceParser.parseWorkspaceNames(input), ["1", "2"])
    }

    // MARK: - parseVisibleNames

    func testParseVisibleNames() {
        let input = "3\nC"
        XCTAssertEqual(WorkspaceParser.parseVisibleNames(input), Set(["3", "C"]))
    }

    func testParseVisibleNamesNil() {
        XCTAssertEqual(WorkspaceParser.parseVisibleNames(nil), Set())
    }

    // MARK: - parseWindows

    func testParseWindows() {
        let input = "Ghostty\tClaude Code\t4\nGhostty\tvim .\t7"
        let result = WorkspaceParser.parseWindows(input)
        XCTAssertEqual(result["4"]?.count, 1)
        XCTAssertEqual(result["4"]?.first?.appName, "Ghostty")
        XCTAssertEqual(result["4"]?.first?.title, "Claude Code")
        XCTAssertEqual(result["7"]?.count, 1)
    }

    func testParseWindowsMultipleInSameWorkspace() {
        let input = "WhatsApp\tSoftware Update\tV\nWhatsApp\tWhatsApp\tV"
        let result = WorkspaceParser.parseWindows(input)
        XCTAssertEqual(result["V"]?.count, 2)
    }

    func testParseWindowsEmpty() {
        XCTAssertEqual(WorkspaceParser.parseWindows(nil).count, 0)
    }

    func testParseWindowsMalformedLineSkipped() {
        let input = "Ghostty\tClaude Code\t4\nmalformed-no-tabs\nCursor\tcli.py\t6"
        let result = WorkspaceParser.parseWindows(input)
        XCTAssertEqual(result.count, 2)
        XCTAssertNotNil(result["4"])
        XCTAssertNotNil(result["6"])
    }

    // MARK: - buildWorkspaces (full integration)

    func testBuildWorkspaces() {
        let result = WorkspaceParser.buildWorkspaces(
            allOutput: "1\n2\n3",
            focusedOutput: "2",
            visibleOutput: "2\n3",
            windowsOutput: "Ghostty\tClaude Code\t2"
        )
        XCTAssertEqual(result.count, 3)

        let ws1 = result[0]
        XCTAssertEqual(ws1.name, "1")
        XCTAssertFalse(ws1.isFocused)
        XCTAssertFalse(ws1.isVisible)
        XCTAssertTrue(ws1.windows.isEmpty)

        let ws2 = result[1]
        XCTAssertEqual(ws2.name, "2")
        XCTAssertTrue(ws2.isFocused)
        XCTAssertTrue(ws2.isVisible)
        XCTAssertEqual(ws2.windows.count, 1)
        XCTAssertEqual(ws2.windows[0].appName, "Ghostty")

        let ws3 = result[2]
        XCTAssertTrue(ws3.isVisible)
        XCTAssertFalse(ws3.isFocused)
    }

    func testBuildWorkspacesNilAllOutput() {
        let result = WorkspaceParser.buildWorkspaces(
            allOutput: nil, focusedOutput: nil, visibleOutput: nil, windowsOutput: nil
        )
        XCTAssertEqual(result.count, 0)
    }

    // MARK: - Fixture-based test

    func testParseFromFixtures() throws {
        let bundle = Bundle.module
        let allText = try String(contentsOf: bundle.url(forResource: "workspaces-all", withExtension: "txt", subdirectory: "Fixtures")!)
        let focusedText = try String(contentsOf: bundle.url(forResource: "workspaces-focused", withExtension: "txt", subdirectory: "Fixtures")!)
        let visibleText = try String(contentsOf: bundle.url(forResource: "workspaces-visible", withExtension: "txt", subdirectory: "Fixtures")!)
        let windowsText = try String(contentsOf: bundle.url(forResource: "windows-all", withExtension: "txt", subdirectory: "Fixtures")!)

        let result = WorkspaceParser.buildWorkspaces(
            allOutput: allText.trimmingCharacters(in: .whitespacesAndNewlines),
            focusedOutput: focusedText.trimmingCharacters(in: .whitespacesAndNewlines),
            visibleOutput: visibleText.trimmingCharacters(in: .whitespacesAndNewlines),
            windowsOutput: windowsText.trimmingCharacters(in: .whitespacesAndNewlines)
        )

        XCTAssertEqual(result.count, 15)

        let ws3 = result.first { $0.name == "3" }!
        XCTAssertTrue(ws3.isFocused)
        XCTAssertTrue(ws3.isVisible)
        XCTAssertEqual(ws3.windows.count, 1)
        XCTAssertEqual(ws3.windows[0].appName, "Ghostty")

        let wsC = result.first { $0.name == "C" }!
        XCTAssertTrue(wsC.isVisible)
        XCTAssertFalse(wsC.isFocused)
        XCTAssertEqual(wsC.windows.count, 1)

        let wsV = result.first { $0.name == "V" }!
        XCTAssertEqual(wsV.windows.count, 2)

        let ws1 = result.first { $0.name == "1" }!
        XCTAssertFalse(ws1.isFocused)
        XCTAssertFalse(ws1.isVisible)
        XCTAssertTrue(ws1.windows.isEmpty)
    }
}
```

**Step 3: Run tests to verify they fail**

```bash
swift test 2>&1 | head -20
```

Expected: `WorkspaceParser` not found.

**Step 4: Write WorkspaceParser.swift**

Create `Sources/WorkspaceSwitcherCore/WorkspaceParser.swift`:

```swift
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
```

**Step 5: Write AeroSpaceCLI.swift (protocol + real impl)**

Create `Sources/WorkspaceSwitcherCore/AeroSpaceCLI.swift`:

```swift
import Foundation

public protocol AeroSpaceCLIProtocol {
    func runCommand(_ args: [String]) -> String?
}

public final class AeroSpaceCLI: AeroSpaceCLIProtocol {
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
```

**Step 6: Run tests**

```bash
swift test
```

Expected: All pass.

**Step 7: Commit**

```bash
git add Sources/WorkspaceSwitcherCore/ Tests/
git commit -m "feat: extract CLI protocol and workspace parser with tests"
```

---

### Task 4: Extract filter logic

**Files:**
- Create: `Sources/WorkspaceSwitcherCore/WorkspaceFilter.swift`
- Create: `Tests/WorkspaceSwitcherCoreTests/FilterTests.swift`

**Step 1: Write failing tests**

Create `Tests/WorkspaceSwitcherCoreTests/FilterTests.swift`:

```swift
import XCTest
@testable import WorkspaceSwitcherCore

final class FilterTests: XCTestCase {
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

    // MARK: - defaultFilter

    func testDefaultFilterExcludesEmptyNonFocusedNonVisible() {
        let result = WorkspaceFilter.defaultFilter(workspaces)
        let names = result.map { $0.name }
        XCTAssertFalse(names.contains("1"))
        XCTAssertTrue(names.contains("2"))
        XCTAssertTrue(names.contains("3"))
        XCTAssertTrue(names.contains("C"))
        XCTAssertTrue(names.contains("V"))
    }

    // MARK: - search

    func testSearchByWorkspaceName() {
        let result = WorkspaceFilter.search(workspaces, query: "C")
        let names = result.map { $0.name }
        XCTAssertTrue(names.contains("C"))
        XCTAssertTrue(names.contains("3")) // "Claude Code" contains "c"
    }

    func testSearchByAppName() {
        let result = WorkspaceFilter.search(workspaces, query: "ghostty")
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].name, "3")
    }

    func testSearchByWindowTitle() {
        let result = WorkspaceFilter.search(workspaces, query: "vault")
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].name, "2")
    }

    func testSearchCaseInsensitive() {
        let result = WorkspaceFilter.search(workspaces, query: "SPOTIFY")
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].name, "C")
    }

    func testSearchNoResults() {
        let result = WorkspaceFilter.search(workspaces, query: "zzzzz")
        XCTAssertEqual(result.count, 0)
    }

    func testSearchEmptyQueryReturnsDefaultFiltered() {
        let result = WorkspaceFilter.search(workspaces, query: "")
        XCTAssertEqual(result.count, 4) // excludes workspace "1"
    }

    func testSearchPartialMatch() {
        let result = WorkspaceFilter.search(workspaces, query: "clau")
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].name, "3")
    }

    func testSearchIncludesEmptyWorkspacesWhenNameMatches() {
        let result = WorkspaceFilter.search(workspaces, query: "1")
        XCTAssertTrue(result.contains { $0.name == "1" })
    }
}
```

**Step 2: Run tests to verify they fail**

```bash
swift test 2>&1 | head -10
```

Expected: `WorkspaceFilter` not found.

**Step 3: Write WorkspaceFilter.swift**

Create `Sources/WorkspaceSwitcherCore/WorkspaceFilter.swift`:

```swift
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
```

**Step 4: Run tests**

```bash
swift test
```

Expected: All pass.

**Step 5: Commit**

```bash
git add Sources/WorkspaceSwitcherCore/WorkspaceFilter.swift Tests/WorkspaceSwitcherCoreTests/FilterTests.swift
git commit -m "feat: extract workspace filter with tests"
```

---

### Task 5: Rewrite main.swift as thin executable

**Files:**
- Modify: `Sources/aerospace-workspace-switcher/main.swift`
- Delete: top-level `main.swift`

**Step 1: Write the new main.swift**

Replace `Sources/aerospace-workspace-switcher/main.swift` with the full AppKit UI code. This file imports `WorkspaceSwitcherCore` and uses:
- `AeroSpaceCLI()` for the real CLI
- `fetchWorkspaces(cli:)` instead of the old free function
- `WorkspaceFilter.search()` / `WorkspaceFilter.defaultFilter()`
- `ws.appSummary` / `ws.titleSummary` instead of inline computation
- `switchToWorkspace(_:cli:)` with the injected CLI
- All drawing constants stay here (they are AppKit-only)
- `exit(0)` replaced with `onDismiss` callback

The executable target has all the AppKit code: `RowView`, `SwitcherPanel`, `Controller`, `AppDelegate`, constants, and the entry point.

**Step 2: Delete old top-level main.swift**

```bash
git rm main.swift
```

**Step 3: Verify build**

```bash
swift build -c release
```

Expected: Builds successfully.

**Step 4: Verify tests still pass**

```bash
swift test
```

Expected: All pass.

**Step 5: Smoke test the binary**

```bash
cp .build/release/aerospace-workspace-switcher ~/.local/bin/aerospace-workspace-switcher
```

Then trigger with `ctrl-alt-space` and verify it works.

**Step 6: Commit**

```bash
git add Sources/aerospace-workspace-switcher/main.swift
git rm main.swift
git commit -m "feat: rewrite executable as thin AppKit shell over library"
```

---

### Task 6: Update Makefile and README

**Files:**
- Modify: `Makefile`
- Modify: `README.md`
- Modify: `.gitignore`

**Step 1: Update Makefile**

```makefile
PREFIX ?= /usr/local
BINARY = aerospace-workspace-switcher

.PHONY: install uninstall clean test

$(BINARY): Sources/WorkspaceSwitcherCore/*.swift Sources/aerospace-workspace-switcher/*.swift Package.swift
	swift build -c release
	cp .build/release/$(BINARY) ./$(BINARY)

install: $(BINARY)
	install -d $(PREFIX)/bin
	install -m 755 $(BINARY) $(PREFIX)/bin/$(BINARY)

uninstall:
	rm -f $(PREFIX)/bin/$(BINARY)

test:
	swift test

clean:
	swift package clean
	rm -f $(BINARY)
```

**Step 2: Update .gitignore**

Add:
```
.build/
.swiftpm/
```

**Step 3: Update README.md**

Update the "From source" section:
```markdown
### From source

\`\`\`bash
git clone https://github.com/rvk7895/aerospace-workspace-switcher.git
cd aerospace-workspace-switcher
make install
\`\`\`

### Run tests

\`\`\`bash
make test
\`\`\`
```

**Step 4: Verify everything**

```bash
make clean && make && make test
```

Expected: Build succeeds, all tests pass.

**Step 5: Commit**

```bash
git add Makefile .gitignore README.md
git commit -m "chore: update build system for SPM package structure"
```

---

### Task 7: Final cleanup and push

**Step 1: Remove placeholder test**

Delete `Tests/WorkspaceSwitcherCoreTests/PlaceholderTests.swift`.

**Step 2: Run full test suite**

```bash
make clean && make test
```

Expected: All tests pass.

**Step 3: Verify binary works**

```bash
make && cp aerospace-workspace-switcher ~/.local/bin/
```

Trigger with `ctrl-alt-space`.

**Step 4: Commit and push**

```bash
git add -A
git commit -m "chore: remove placeholder test, finalize restructure"
git push origin master
```
