import AppKit
import Carbon.HIToolbox

// MARK: - Models

struct WindowInfo {
    let appName: String
    let title: String
    let appNameLower: String
    let titleLower: String
}

struct WorkspaceInfo {
    let name: String
    let nameLower: String
    let isFocused: Bool
    let isVisible: Bool
    let windows: [WindowInfo]

    var hasWindows: Bool { !windows.isEmpty }
    var isRelevant: Bool { hasWindows || isFocused || isVisible }
}

// MARK: - AeroSpace CLI

let aerospacePath: String? = {
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
}()

func runAerospaceCommand(_ args: [String]) -> String? {
    guard let path = aerospacePath else { return nil }
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

func fetchWorkspaces() -> [WorkspaceInfo] {
    guard let allOut = runAerospaceCommand(["list-workspaces", "--all"]) else { return [] }
    let focusedName = runAerospaceCommand(["list-workspaces", "--focused"])?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    let visibleOutput = runAerospaceCommand(["list-workspaces", "--monitor", "all", "--visible"])
    let winOutput = runAerospaceCommand(["list-windows", "--all", "--format", "%{app-name}\t%{window-title}\t%{workspace}"])

    guard !allOut.isEmpty else { return [] }
    let allNames = allOut.split(separator: "\n").map { String($0).trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }

    let visibleNames = Set((visibleOutput ?? "").split(separator: "\n").map { String($0).trimmingCharacters(in: .whitespaces) })

    var workspaceWindows: [String: [WindowInfo]] = [:]
    if let wOut = winOutput {
        for line in wOut.split(separator: "\n") {
            let parts = line.split(separator: "\t", maxSplits: 2).map { String($0) }
            guard parts.count >= 3 else { continue }
            let win = WindowInfo(appName: parts[0], title: parts[1], appNameLower: parts[0].lowercased(), titleLower: parts[1].lowercased())
            workspaceWindows[parts[2], default: []].append(win)
        }
    }

    return allNames.map { name in
        WorkspaceInfo(
            name: name,
            nameLower: name.lowercased(),
            isFocused: name == focusedName,
            isVisible: visibleNames.contains(name),
            windows: workspaceWindows[name] ?? []
        )
    }
}

func switchToWorkspace(_ name: String) {
    _ = runAerospaceCommand(["workspace", name])
}

// MARK: - Drawing Constants

let PANEL_W: CGFloat = 600
let PANEL_RADIUS: CGFloat = 12
let SEARCH_H: CGFloat = 50
let ROW_H: CGFloat = 56
let MAX_VISIBLE = 8
let PAD: CGFloat = 6
let WS_LABEL_W: CGFloat = 50
let CONTENT_INSET: CGFloat = 8

let BG = NSColor(white: 0.12, alpha: 1.0)
let SEL_BG = NSColor(red: 0.24, green: 0.46, blue: 0.96, alpha: 1.0)
let TEXT_PRIMARY = NSColor.white
let TEXT_SECONDARY = NSColor(white: 0.65, alpha: 1.0)
let TEXT_DIM = NSColor(white: 0.38, alpha: 1.0)
let BADGE_FOCUSED = NSColor(red: 0.3, green: 0.8, blue: 0.45, alpha: 1.0)
let BADGE_VISIBLE = NSColor(red: 0.35, green: 0.55, blue: 0.95, alpha: 1.0)
let SEPARATOR = NSColor(white: 0.2, alpha: 1.0)

// MARK: - Row View

class RowView: NSView {
    let wsLabel = NSTextField(labelWithString: "")
    let badge = NSTextField(labelWithString: "")
    let appLabel = NSTextField(labelWithString: "")
    let titleLabel = NSTextField(labelWithString: "")

    override init(frame: NSRect) {
        super.init(frame: frame)
        wantsLayer = true
        layer?.cornerRadius = 6

        wsLabel.font = .monospacedDigitSystemFont(ofSize: 20, weight: .bold)
        wsLabel.alignment = .center
        wsLabel.translatesAutoresizingMaskIntoConstraints = false
        wsLabel.setContentHuggingPriority(.required, for: .horizontal)

        badge.font = .systemFont(ofSize: 8, weight: .bold)
        badge.alignment = .center
        badge.wantsLayer = true
        badge.layer?.cornerRadius = 3
        badge.translatesAutoresizingMaskIntoConstraints = false
        badge.setContentHuggingPriority(.required, for: .horizontal)

        appLabel.font = .systemFont(ofSize: 13, weight: .medium)
        appLabel.translatesAutoresizingMaskIntoConstraints = false
        appLabel.lineBreakMode = .byTruncatingTail
        appLabel.maximumNumberOfLines = 1
        appLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        titleLabel.font = .systemFont(ofSize: 11)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.lineBreakMode = .byTruncatingTail
        titleLabel.maximumNumberOfLines = 1
        titleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        let textStack = NSStackView()
        textStack.orientation = .vertical
        textStack.alignment = .leading
        textStack.spacing = 2
        textStack.translatesAutoresizingMaskIntoConstraints = false
        textStack.addArrangedSubview(appLabel)
        textStack.addArrangedSubview(titleLabel)

        let leftStack = NSStackView()
        leftStack.orientation = .vertical
        leftStack.alignment = .centerX
        leftStack.spacing = 2
        leftStack.translatesAutoresizingMaskIntoConstraints = false
        leftStack.addArrangedSubview(wsLabel)
        leftStack.addArrangedSubview(badge)

        addSubview(leftStack)
        addSubview(textStack)

        NSLayoutConstraint.activate([
            leftStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: CONTENT_INSET),
            leftStack.widthAnchor.constraint(equalToConstant: WS_LABEL_W),
            leftStack.centerYAnchor.constraint(equalTo: centerYAnchor),
            textStack.leadingAnchor.constraint(equalTo: leftStack.trailingAnchor, constant: CONTENT_INSET),
            textStack.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -14),
            textStack.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(_ ws: WorkspaceInfo, selected: Bool) {
        layer?.backgroundColor = selected ? SEL_BG.cgColor : NSColor.clear.cgColor

        wsLabel.stringValue = ws.name
        wsLabel.textColor = selected || ws.hasWindows ? TEXT_PRIMARY : TEXT_DIM

        if ws.isFocused {
            badge.stringValue = " FOCUSED "
            badge.textColor = .white
            badge.layer?.backgroundColor = BADGE_FOCUSED.cgColor
            badge.isHidden = false
        } else if ws.isVisible {
            badge.stringValue = " VISIBLE "
            badge.textColor = .white
            badge.layer?.backgroundColor = BADGE_VISIBLE.cgColor
            badge.isHidden = false
        } else {
            badge.isHidden = true
        }

        if ws.hasWindows {
            var appCounts: [(String, Int)] = []
            var seen: [String: Int] = [:]
            for win in ws.windows {
                if let idx = seen[win.appName] { appCounts[idx].1 += 1 }
                else { seen[win.appName] = appCounts.count; appCounts.append((win.appName, 1)) }
            }
            appLabel.stringValue = appCounts.map { $1 > 1 ? "\($0) (\($1))" : $0 }.joined(separator: ", ")
            appLabel.textColor = TEXT_PRIMARY

            let titles = ws.windows.map { $0.title }.filter { !$0.isEmpty }
            let joined = titles.joined(separator: "  \u{00b7}  ")
            titleLabel.stringValue = joined
            titleLabel.textColor = selected ? NSColor(white: 0.82, alpha: 1) : TEXT_SECONDARY
            titleLabel.isHidden = joined.isEmpty
        } else {
            appLabel.stringValue = "Empty"
            appLabel.textColor = selected ? NSColor(white: 0.8, alpha: 1) : TEXT_DIM
            titleLabel.stringValue = ""
            titleLabel.isHidden = true
        }
    }
}

// MARK: - Panel

class SwitcherPanel: NSPanel {
    init(rect: NSRect) {
        super.init(contentRect: rect, styleMask: [.borderless], backing: .buffered, defer: false)
        level = .floating
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        isReleasedWhenClosed = false
        hidesOnDeactivate = true
        isMovableByWindowBackground = false
        backgroundColor = .clear
        isOpaque = false
        hasShadow = true
    }
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

// MARK: - Controller

class Controller: NSObject, NSTextFieldDelegate {
    var panel: SwitcherPanel!
    var container: NSView!
    var searchField: NSTextField!
    var scrollView: NSScrollView!
    var listView: NSView!
    var scrollH: NSLayoutConstraint!

    var all: [WorkspaceInfo] = []
    var filtered: [WorkspaceInfo] = []
    var selectedIndex = 0
    var rows: [RowView] = []

    var listHeight: CGFloat {
        CGFloat(min(filtered.count, MAX_VISIBLE)) * ROW_H
    }

    var panelHeight: CGFloat {
        SEARCH_H + 1 + PAD + listHeight + PAD + 20
    }

    var defaultFiltered: [WorkspaceInfo] {
        all.filter { $0.isRelevant }
    }

    func show() {
        all = fetchWorkspaces()
        filtered = defaultFiltered
        selectedIndex = 0
        if let fi = filtered.firstIndex(where: { $0.isFocused }) { selectedIndex = fi }

        buildPanel()
        rebuildRows()
        position()
        panel.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        panel.makeFirstResponder(searchField)
    }

    func buildPanel() {
        panel = SwitcherPanel(rect: NSRect(x: 0, y: 0, width: PANEL_W, height: panelHeight))

        container = NSView(frame: panel.contentView!.bounds)
        container.wantsLayer = true
        container.layer?.backgroundColor = BG.cgColor
        container.layer?.cornerRadius = PANEL_RADIUS
        container.layer?.masksToBounds = true
        container.layer?.borderWidth = 1
        container.layer?.borderColor = NSColor(white: 0.25, alpha: 0.6).cgColor
        container.autoresizingMask = [.width, .height]
        panel.contentView?.addSubview(container)

        let contentLeft: CGFloat = PAD + CONTENT_INSET + WS_LABEL_W + CONTENT_INSET

        let icon = NSImageView()
        icon.translatesAutoresizingMaskIntoConstraints = false
        icon.image = NSImage(systemSymbolName: "magnifyingglass", accessibilityDescription: nil)
        icon.contentTintColor = NSColor(white: 0.4, alpha: 1)
        container.addSubview(icon)

        searchField = NSTextField(frame: .zero)
        searchField.translatesAutoresizingMaskIntoConstraints = false
        searchField.isBordered = false
        searchField.isBezeled = false
        searchField.focusRingType = .none
        searchField.font = .systemFont(ofSize: 18, weight: .light)
        searchField.textColor = TEXT_PRIMARY
        searchField.backgroundColor = .clear
        searchField.placeholderAttributedString = NSAttributedString(
            string: "Switch to workspace...",
            attributes: [.foregroundColor: NSColor(white: 0.35, alpha: 1), .font: NSFont.systemFont(ofSize: 18, weight: .light)]
        )
        searchField.delegate = self
        searchField.cell?.sendsActionOnEndEditing = false
        container.addSubview(searchField)

        let sep = NSView()
        sep.translatesAutoresizingMaskIntoConstraints = false
        sep.wantsLayer = true
        sep.layer?.backgroundColor = SEPARATOR.cgColor
        container.addSubview(sep)

        scrollView = NSScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.drawsBackground = false
        scrollView.borderType = .noBorder
        scrollView.scrollerStyle = .overlay
        container.addSubview(scrollView)

        listView = NSView()
        listView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.documentView = listView

        let hint = NSTextField(labelWithString: "")
        hint.translatesAutoresizingMaskIntoConstraints = false
        hint.alignment = .center
        let dim: [NSAttributedString.Key: Any] = [.foregroundColor: NSColor(white: 0.32, alpha: 1), .font: NSFont.systemFont(ofSize: 10)]
        let key: [NSAttributedString.Key: Any] = [.foregroundColor: NSColor(white: 0.5, alpha: 1), .font: NSFont.systemFont(ofSize: 10, weight: .medium)]
        let h = NSMutableAttributedString()
        h.append(NSAttributedString(string: "\u{2191}\u{2193} ", attributes: key))
        h.append(NSAttributedString(string: "navigate   ", attributes: dim))
        h.append(NSAttributedString(string: "\u{23ce} ", attributes: key))
        h.append(NSAttributedString(string: "switch   ", attributes: dim))
        h.append(NSAttributedString(string: "esc ", attributes: key))
        h.append(NSAttributedString(string: "close", attributes: dim))
        hint.attributedStringValue = h
        container.addSubview(hint)

        scrollH = scrollView.heightAnchor.constraint(equalToConstant: listHeight)

        NSLayoutConstraint.activate([
            searchField.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: contentLeft),
            searchField.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -14),
            searchField.centerYAnchor.constraint(equalTo: container.topAnchor, constant: SEARCH_H / 2),

            icon.centerXAnchor.constraint(equalTo: container.leadingAnchor, constant: PAD + CONTENT_INSET + WS_LABEL_W / 2),
            icon.centerYAnchor.constraint(equalTo: searchField.centerYAnchor),
            icon.widthAnchor.constraint(equalToConstant: 18),
            icon.heightAnchor.constraint(equalToConstant: 18),

            sep.topAnchor.constraint(equalTo: container.topAnchor, constant: SEARCH_H),
            sep.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            sep.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            sep.heightAnchor.constraint(equalToConstant: 1),

            scrollView.topAnchor.constraint(equalTo: sep.bottomAnchor, constant: PAD),
            scrollView.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: PAD),
            scrollView.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -PAD),
            scrollH,

            hint.topAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: 2),
            hint.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            hint.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -4),

            listView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            listView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
        ])

        NSEvent.addLocalMonitorForEvents(matching: .leftMouseDown) { [weak self] ev in
            guard let s = self else { return ev }
            if !s.panel.contentView!.frame.contains(ev.locationInWindow) { s.dismiss(); return nil }
            let pt = s.listView.convert(ev.locationInWindow, from: nil)
            for (i, r) in s.rows.enumerated() {
                if r.frame.contains(pt) { s.selectedIndex = i; s.refresh(); s.selectCurrent(); return nil }
            }
            return ev
        }

        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] ev in
            guard let s = self else { return ev }
            return s.handleKey(ev) ? nil : ev
        }
    }

    func rebuildRows() {
        for r in rows { r.removeFromSuperview() }
        rows.removeAll()

        let total = CGFloat(filtered.count) * ROW_H
        listView.frame = NSRect(x: 0, y: 0, width: scrollView.frame.width, height: max(total, 1))

        for (i, ws) in filtered.enumerated() {
            let y = total - CGFloat(i + 1) * ROW_H
            let r = RowView(frame: NSRect(x: 0, y: y, width: scrollView.frame.width, height: ROW_H))
            r.autoresizingMask = [.width]
            r.configure(ws, selected: i == selectedIndex)
            listView.addSubview(r)
            rows.append(r)
        }

        let h = panelHeight
        var f = panel.frame
        f.origin.y += f.height - h
        f.size.height = h
        panel.setFrame(f, display: true, animate: false)
        scrollH.constant = listHeight
        ensureVisible()
    }

    func refresh() {
        for (i, r) in rows.enumerated() {
            guard i < filtered.count else { break }
            r.configure(filtered[i], selected: i == selectedIndex)
        }
        ensureVisible()
    }

    func ensureVisible() {
        guard selectedIndex >= 0, selectedIndex < rows.count else { return }
        scrollView.contentView.scrollToVisible(rows[selectedIndex].frame)
    }

    func position() {
        guard let scr = NSScreen.main else { return }
        let h = panelHeight
        let sf = scr.visibleFrame
        let x = sf.midX - PANEL_W / 2
        let y = sf.midY + sf.height * 0.12 - h / 2
        panel.setFrame(NSRect(x: x, y: y, width: PANEL_W, height: h), display: true)
    }

    // MARK: - Navigation helpers

    func moveUp() { if selectedIndex > 0 { selectedIndex -= 1; refresh() } }
    func moveDown() { if selectedIndex < filtered.count - 1 { selectedIndex += 1; refresh() } }

    func selectCurrent() {
        guard selectedIndex >= 0, selectedIndex < filtered.count else { return }
        let name = filtered[selectedIndex].name
        panel.orderOut(nil); panel.close()
        switchToWorkspace(name)
        exit(0)
    }

    func dismiss() {
        panel.orderOut(nil); panel.close()
        exit(0)
    }

    // MARK: - Filter

    func filter(_ q: String) {
        if q.isEmpty {
            filtered = defaultFiltered
        } else {
            let lq = q.lowercased()
            filtered = all.filter { ws in
                ws.nameLower.contains(lq) ||
                ws.windows.contains { $0.appNameLower.contains(lq) || $0.titleLower.contains(lq) }
            }
        }
        selectedIndex = 0
        rebuildRows()
    }

    // MARK: - Key handling

    func handleKey(_ ev: NSEvent) -> Bool {
        switch Int(ev.keyCode) {
        case kVK_Escape: dismiss(); return true
        case kVK_Return: selectCurrent(); return true
        case kVK_DownArrow: moveDown(); return true
        case kVK_UpArrow: moveUp(); return true
        case kVK_Tab:
            if ev.modifierFlags.contains(.shift) { moveUp() } else { moveDown() }
            return true
        default: return false
        }
    }

    // MARK: - NSTextFieldDelegate

    func controlTextDidChange(_ obj: Notification) { filter(searchField.stringValue) }

    func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        if commandSelector == #selector(NSResponder.insertNewline(_:)) { selectCurrent(); return true }
        if commandSelector == #selector(NSResponder.cancelOperation(_:)) { dismiss(); return true }
        if commandSelector == #selector(NSResponder.moveUp(_:)) { moveUp(); return true }
        if commandSelector == #selector(NSResponder.moveDown(_:)) { moveDown(); return true }
        if commandSelector == #selector(NSResponder.insertTab(_:)) { moveDown(); return true }
        if commandSelector == #selector(NSResponder.insertBacktab(_:)) { moveUp(); return true }
        return false
    }
}

// MARK: - Entry

class AppDelegate: NSObject, NSApplicationDelegate {
    let ctrl = Controller()
    func applicationDidFinishLaunching(_ n: Notification) {
        NSApp.setActivationPolicy(.accessory)
        NotificationCenter.default.addObserver(forName: NSApplication.didResignActiveNotification, object: nil, queue: .main) { _ in
            exit(0)
        }
        ctrl.show()
    }
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
