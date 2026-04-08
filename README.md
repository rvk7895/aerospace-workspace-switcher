# aerospace-workspace-switcher

A native macOS Spotlight-style workspace switcher for [AeroSpace](https://github.com/nikitabobko/AeroSpace) — the i3-style tiling window manager.

![workspace-switcher-screenshot](https://github.com/user-attachments/assets/placeholder)

## Features

- Floating panel with all active workspaces and their window contents
- Real-time search filtering by workspace name, app name, or window title
- FOCUSED / VISIBLE workspace badges
- Keyboard-driven: arrow keys to navigate, Enter to switch, Escape to dismiss
- Fast startup — only 3 `aerospace` CLI calls
- Pure Swift, no external dependencies

## Requirements

- macOS 14.0+
- [AeroSpace](https://github.com/nikitabobko/AeroSpace) installed and running

## Install

### Homebrew

```bash
brew tap rvk7895/tap
brew install aerospace-workspace-switcher
```

### From source

```bash
git clone https://github.com/rvk7895/aerospace-workspace-switcher.git
cd aerospace-workspace-switcher
make install
```

By default installs to `/usr/local/bin`. To change:

```bash
make install PREFIX=$HOME/.local
```

## Configuration

Add a keybinding to your `~/.aerospace.toml`:

```toml
[mode.main.binding]
ctrl-alt-space = 'exec-and-forget aerospace-workspace-switcher'
```

Then reload your AeroSpace config (`alt-shift-;` → `esc` in the default config, or restart AeroSpace).

## Usage

1. Press your keybinding (e.g. `ctrl-alt-space`)
2. A floating panel appears listing all non-empty workspaces with their apps and window titles
3. Type to filter by workspace name, app name, or window title
4. Use arrow keys (or Tab/Shift-Tab) to navigate
5. Press Enter to switch to the selected workspace
6. Press Escape to dismiss

## Development

### Run tests

```bash
make test
```

### Build

```bash
make
```

## Prior art

- [Spacelist](https://github.com/magicmark/spacelist) — terminal UI workspace viewer
- dmenu / rofi workspace switching in i3/sway on Linux

## License

MIT
