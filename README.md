# Cursor Highlight

A lightweight native macOS menu bar app that draws a configurable highlight around your mouse cursor. Great for presentations, screencasts, and tutorials.

## Features

- **7 highlight shapes** — Circle, Ring, Crosshair, Spotlight, Diamond, Target, Glow
- **9 built-in presets** — Default Yellow, Neon Ring, Red Crosshair, Soft Spotlight, Green Diamond, Sniper Target, Blue Glow, Purple Pulse, Minimal Dot
- **3 click effects** — Color Change, Pulse, Ripple
- **Toolbox UI** — Full settings window with live preview, accessible from the menu bar
- **Customizable** — Shape, size, fill/border color, opacity, border width, click effect and color
- **Persistent settings** — Toolbox changes are saved automatically and restored on next launch
- **Lightweight** — Native Swift, no dependencies, runs as a menu bar app with no dock icon

## Requirements

- macOS 13.0 (Ventura) or later
- Swift 5.9+
- Accessibility permissions (prompted on first launch)

## Build & Install

```bash
# Clone
git clone https://github.com/dpoe2016/cursor-highlight.git
cd cursor-highlight

# Build app bundle
./build.sh

# Install to Applications
cp -r "build/Cursor Highlight.app" /Applications/

# Or run directly
open "build/Cursor Highlight.app"
```

### Build from source without app bundle

```bash
swift build -c release
.build/release/cursor-highlight
```

## Usage

1. Launch the app — a cursor icon appears in the menu bar
2. Click the menu bar icon to access:
   - **Toggle Highlight** (Ctrl+Shift+T) — show/hide the highlight
   - **Toolbox...** — open the settings window
   - **Quit** — exit the app
3. Use the Toolbox to customize shape, colors, size, and click effects — changes apply live

## Presets

| Preset | Shape | Description |
|--------|-------|-------------|
| Default Yellow | Circle | Yellow fill with orange border |
| Neon Ring | Ring | Cyan outline, no fill |
| Red Crosshair | Crosshair | Red cross lines with center dot |
| Soft Spotlight | Spotlight | White radial gradient fade |
| Green Diamond | Diamond | Green rotated square |
| Sniper Target | Target | Red concentric rings with crosshairs |
| Blue Glow | Glow | Soft blue radial glow |
| Purple Pulse | Circle | Purple fill with magenta border |
| Minimal Dot | Circle | Small white dot |

## License

MIT
