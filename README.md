<div align="center">

<img src="Assets/skull_active.png" width="120" alt="xkill-mac icon"/>

# xkill-mac

**Instantly kill any macOS app by clicking on its window.**

*Developed by [Carmelo Battiato](https://github.com/carmelobattiato)*

[![macOS](https://img.shields.io/badge/macOS-13%2B-black?logo=apple&logoColor=white)](https://www.apple.com/macos/)
[![Swift](https://img.shields.io/badge/Swift-5.9-orange?logo=swift&logoColor=white)](https://swift.org)
[![License](https://img.shields.io/badge/license-MIT-blue)](LICENSE)
[![GitHub release](https://img.shields.io/github/v/release/carmelobattiato/xkill-mac?color=red)](https://github.com/carmelobattiato/xkill-mac/releases)

</div>

---

## What is it?

xkill-mac is a lightweight **menu bar utility** inspired by the classic `xkill` command from Linux/X11.

When an app freezes and won't respond, you don't need to dig through Activity Monitor. Just click the skull, click the frozen window — it's gone.

## How it works

| Step | Action |
|------|--------|
| 1️⃣ | Click the **skull icon** in the menu bar |
| 2️⃣ | Cursor becomes a **red skull** |
| 3️⃣ | Click any window to **force-quit** its app |
| ⎋ | Press **ESC** to cancel at any time |

> Right-click the menu bar icon → **Quit xkill-mac**

---

## Install

### Download DMG *(easiest)*

1. Go to [**Releases**](https://github.com/carmelobattiato/xkill-mac/releases/latest)
2. Download `xkill-mac.dmg`
3. Open it, drag the app to `/Applications`

> **First launch:** macOS will warn about an unidentified developer.
> Right-click the app → **Open** → **Open** to bypass Gatekeeper.

### Build from source

```bash
git clone https://github.com/carmelobattiato/xkill-mac.git
cd xkill-mac
make install        # builds + copies to /Applications
```

Or double-click **`install.command`** in Finder — it does everything automatically.

---

## Accessibility permission

xkill-mac needs **Accessibility** access to intercept clicks globally (so the target app never sees the click).

On first launch macOS will prompt automatically. If not:

> **System Settings → Privacy & Security → Accessibility → add xkill-mac → enable toggle**

After granting permission, relaunch the app.

---

## Build reference

```bash
make app        # release build → xkill-mac.app
make install    # build + install to /Applications
make dmg        # build + create xkill-mac.dmg
make clean      # remove build artifacts
```

---

## Project structure

```
xkill-mac/
├── Sources/xkill-mac/
│   ├── main.swift          # Entry point
│   ├── AppDelegate.swift   # Menu bar, ESC hint panel
│   ├── XKillManager.swift  # Kill mode, CGEvent tap, cursor overlay
│   └── Info.plist          # LSUIElement, CFBundleIdentifier
├── Assets/
│   ├── skull_normal.png    # Menu bar icon (inactive)
│   └── skull_active.png    # Menu bar icon + cursor (kill mode)
├── Package.swift
├── Makefile
├── create_icon.swift       # Generates AppIcon.icns
└── install.command         # One-click installer
```

## How it works under the hood

- **No Dock icon** — runs as `LSUIElement` accessory process
- **Global click interception** — `CGEvent.tapCreate` with `.defaultTap` consumes the click before the target app receives it
- **Cursor overlay** — borderless `NSPanel` at `.screenSaver` level follows the mouse; real cursor hidden via `CGDisplayHideCursor()`
- **Window detection** — `CGWindowListCopyWindowInfo` returns on-screen windows front-to-back; first `layer == 0` window containing the click point wins
- **Force quit** — `NSRunningApplication.forceTerminate()`
- **Ad-hoc signed** — `codesign --sign -` so Accessibility permission persists across reinstalls

---

## Requirements

- macOS 13 Ventura or later
- Xcode Command Line Tools (`xcode-select --install`)

---

## License

MIT © Developed by **Carmelo Battiato** — [github.com/carmelobattiato](https://github.com/carmelobattiato)
