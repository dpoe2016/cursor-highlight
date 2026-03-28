# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Run

```bash
# Build the app bundle (creates build/Cursor Highlight.app)
./build.sh

# Run directly from build directory
open "build/Cursor Highlight.app"

# Or build without app bundle
swift build -c release
```

## Architecture Overview

**Single-file Swift application** (`Sources/main.swift` ~1300 lines) implementing:

### Core Components

1. **HighlightWindowController** - Manages the highlight window and global mouse tracking:
   - Uses `CGEvent.tapCreate` for event monitoring (requires Accessibility permission)
   - Falls back to `NSEvent.addGlobalMonitorForEvents` if event tap fails
   - No selection rectangle support (removed)

2. **HighlightView** - NSView subclass that draws the cursor highlight:
   - Supports 7 shapes: Circle, Ring, Crosshair, Spotlight, Diamond, Target, Glow
   - Click effects: Pulse, Ripple, Color Change
   - Custom drawing with CoreGraphics (no third-party dependencies)

3. **HighlightConfig** - Configuration model with UserDefaults persistence:
   - Shape, radius, colors (fill/border), opacity, border width
   - Click effect settings with `NSColor` persistence via hex conversion

4. **SnapshotManager** - Records click positions as screenshots:
   - Creates per-session directories on Desktop
   - Captures full-screen shots via `CGWindowListCreateImage`
   - Generates HTML reports with cursor positions and timestamps

5. **ToolboxWindowController** - Settings UI with:
   - Live preview of highlight configuration
   - 9 built-in presets with `Preset` struct
   - Snapshot recording controls (toggle, report generation, clear)

6. **StatusBarManager** - Menu bar integration:
   - Global hotkey (Ctrl+Shift+T) via Carbon Event API
   - Menu items for toggle, recording, report generation

### Key Design Patterns

- **Flat architecture** - All logic in single file with MARK: sections
- **Active tracking** - 60fps timer updates position via `tick()`
- **Minimal event handling** - Event tap only triggers click effects

### Important Notes

- No tests - direct manual testing required
- Requires Accessibility permission for global mouse tracking
- Screen Recording permission needed for snapshot capture
- Uses Swift 5.9+ features (no external dependencies)
