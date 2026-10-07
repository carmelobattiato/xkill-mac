# xkill-mac

A macOS menu bar utility that lets you instantly kill any application by clicking on its window — inspired by the classic `xkill` tool from Linux/X11.

## How it works

1. Click the skull icon in the menu bar
2. Your cursor turns into a red skull
3. Click on any application window to force-quit it
4. Press **ESC** at any time to cancel

Right-click the menu bar icon to quit the app.

## Screenshot

> Skull icon in the menu bar → click → red skull cursor → click any window → app is killed

## Requirements

- macOS 13 (Ventura) or later
- Xcode Command Line Tools (`xcode-select --install`)
- Swift Package Manager (included with Xcode CLT)

## Install

### One-step installer (recommended)

Double-click `install.command` in Finder.

This will:
1. Generate the app icon
2. Compile the project in release mode
3. Build `xkill-mac.app`
4. Install it to `/Applications`
5. Launch the app

### Manual build

```bash
git clone https://github.com/carmelobattiato/xkill-mac.git
cd xkill-mac
make install
```

Or just build without installing:

```bash
make app
open xkill-mac.app
```

## First launch — Accessibility permission

xkill-mac needs **Accessibility** access to intercept mouse clicks globally.

On first launch macOS will show a permission dialog. If it doesn't appear automatically:

1. Open **System Settings → Privacy & Security → Accessibility**
2. Click **+** and add `xkill-mac`
3. Enable the toggle
4. Relaunch the app

> **Note:** If you reinstall or recompile the app, you may need to remove and re-add it in the Accessibility list.

## Usage

| Action | Result |
|--------|--------|
| Left-click menu bar icon | Activate kill mode |
| Click any window (kill mode) | Force-quit that app |
| **ESC** (kill mode) | Cancel, restore cursor |
| Right-click menu bar icon | Open context menu / Quit |

## Build from source

```bash
# Debug build
swift build

# Release build
swift build -c release

# Full .app bundle (release + icon + code sign)
make app

# Install to /Applications
make install

# Clean
make clean
```

## Project structure

```
xkill-mac/
├── Package.swift           # Swift Package Manager manifest
├── Makefile                # Build, bundle, install targets
├── install.command         # Double-click installer for Finder
├── create_icon.swift       # Generates AppIcon.icns from skull PNG
├── Assets/
│   ├── skull_normal.png    # Menu bar icon (inactive)
│   └── skull_active.png    # Menu bar icon + cursor (kill mode)
└── Sources/xkill-mac/
    ├── main.swift          # App entry point
    ├── AppDelegate.swift   # Menu bar setup, ESC hint panel
    ├── XKillManager.swift  # Kill mode logic, CGEvent tap, cursor overlay
    └── Info.plist          # Bundle metadata (LSUIElement, CFBundleIdentifier)
```

## How it works (technical)

- **Menu bar icon** — `NSStatusItem` with custom skull PNG, no Dock icon (`LSUIElement = true`)
- **Global click interception** — `CGEvent.tapCreate` with `.defaultTap` consumes the click before it reaches the target app (requires Accessibility permission)
- **Cursor overlay** — borderless `NSPanel` at `.screenSaver` window level that follows the mouse via a global `NSEvent` monitor; real cursor hidden with `CGDisplayHideCursor()`
- **Window hit-testing** — `CGWindowListCopyWindowInfo` returns on-screen windows in front-to-back order; the first layer-0 window containing the click point is selected
- **App termination** — `NSRunningApplication.forceTerminate()`
- **Code signing** — ad-hoc signed (`codesign --sign -`) so Accessibility permission persists across reinstalls

## License

MIT
