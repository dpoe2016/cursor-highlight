import Cocoa
import Carbon

// MARK: - Enums

enum HighlightShape: Int, CaseIterable {
    case circle = 0
    case ring
    case crosshair
    case spotlight
    case diamond
    case target
    case glow
    case rectangle

    var name: String {
        switch self {
        case .circle:    return "Circle"
        case .ring:      return "Ring"
        case .crosshair: return "Crosshair"
        case .spotlight:  return "Spotlight"
        case .diamond:    return "Diamond"
        case .target:     return "Target"
        case .glow:       return "Glow"
        case .rectangle:  return "Rectangle (Click)"
        }
    }
}

enum ClickEffect: Int, CaseIterable {
    case colorChange = 0
    case pulse
    case ripple
    case none

    var name: String {
        switch self {
        case .colorChange: return "Color Change"
        case .pulse:       return "Pulse"
        case .ripple:      return "Ripple"
        case .none:        return "None"
        }
    }
}

// MARK: - Configuration

class HighlightConfig {
    var shape: HighlightShape = .circle
    var radius: CGFloat = 30
    var fillColor: NSColor = NSColor.yellow
    var fillOpacity: CGFloat = 0.35
    var borderColor: NSColor = NSColor.orange
    var borderOpacity: CGFloat = 0.7
    var borderWidth: CGFloat = 2.5
    var clickEffect: ClickEffect = .colorChange
    var clickColor: NSColor = NSColor.red
    var clickOpacity: CGFloat = 0.5
    var showClickEffect: Bool = true
    var showRectangleOnMouseDown: Bool = false

    var effectiveFillColor: NSColor { fillColor.withAlphaComponent(fillOpacity) }
    var effectiveBorderColor: NSColor { borderColor.withAlphaComponent(borderOpacity) }
    var effectiveClickColor: NSColor { clickColor.withAlphaComponent(clickOpacity) }
    var windowSize: CGFloat { radius * 2 + borderWidth * 2 + 20 } // extra padding for effects

    func copy() -> HighlightConfig {
        let c = HighlightConfig()
        c.shape = shape; c.radius = radius
        c.fillColor = fillColor; c.fillOpacity = fillOpacity
        c.borderColor = borderColor; c.borderOpacity = borderOpacity
        c.borderWidth = borderWidth; c.clickEffect = clickEffect
        c.clickColor = clickColor; c.clickOpacity = clickOpacity
        c.showClickEffect = showClickEffect
        c.showRectangleOnMouseDown = showRectangleOnMouseDown
        return c
    }

    // MARK: Persistence

    private static let defaults = UserDefaults.standard

    private static func colorToHex(_ color: NSColor) -> String {
        let c = color.usingColorSpace(.sRGB) ?? color
        return String(format: "#%02X%02X%02X",
                      Int(c.redComponent * 255),
                      Int(c.greenComponent * 255),
                      Int(c.blueComponent * 255))
    }

    private static func hexToColor(_ hex: String) -> NSColor? {
        var h = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if h.hasPrefix("#") { h.removeFirst() }
        guard h.count == 6, let val = UInt64(h, radix: 16) else { return nil }
        let r = CGFloat((val >> 16) & 0xFF) / 255.0
        let g = CGFloat((val >> 8) & 0xFF) / 255.0
        let b = CGFloat(val & 0xFF) / 255.0
        return NSColor(srgbRed: r, green: g, blue: b, alpha: 1.0)
    }

    func save() {
        let d = HighlightConfig.defaults
        d.set(shape.rawValue, forKey: "shape")
        d.set(Double(radius), forKey: "radius")
        d.set(HighlightConfig.colorToHex(fillColor), forKey: "fillColor")
        d.set(Double(fillOpacity), forKey: "fillOpacity")
        d.set(HighlightConfig.colorToHex(borderColor), forKey: "borderColor")
        d.set(Double(borderOpacity), forKey: "borderOpacity")
        d.set(Double(borderWidth), forKey: "borderWidth")
        d.set(clickEffect.rawValue, forKey: "clickEffect")
        d.set(HighlightConfig.colorToHex(clickColor), forKey: "clickColor")
        d.set(Double(clickOpacity), forKey: "clickOpacity")
        d.set(showClickEffect, forKey: "showClickEffect")
        d.set(showRectangleOnMouseDown, forKey: "showRectangleOnMouseDown")
    }

    static func load() -> HighlightConfig {
        let c = HighlightConfig()
        let d = defaults
        guard d.object(forKey: "shape") != nil else { return c }

        c.shape = HighlightShape(rawValue: d.integer(forKey: "shape")) ?? .circle
        c.radius = CGFloat(d.double(forKey: "radius"))
        if let hex = d.string(forKey: "fillColor"), let col = hexToColor(hex) { c.fillColor = col }
        c.fillOpacity = CGFloat(d.double(forKey: "fillOpacity"))
        if let hex = d.string(forKey: "borderColor"), let col = hexToColor(hex) { c.borderColor = col }
        c.borderOpacity = CGFloat(d.double(forKey: "borderOpacity"))
        c.borderWidth = CGFloat(d.double(forKey: "borderWidth"))
        c.clickEffect = ClickEffect(rawValue: d.integer(forKey: "clickEffect")) ?? .colorChange
        if let hex = d.string(forKey: "clickColor"), let col = hexToColor(hex) { c.clickColor = col }
        c.clickOpacity = CGFloat(d.double(forKey: "clickOpacity"))
        c.showClickEffect = d.bool(forKey: "showClickEffect")
        c.showRectangleOnMouseDown = d.bool(forKey: "showRectangleOnMouseDown")
        return c
    }
}

// MARK: - Presets

struct Preset {
    let name: String
    let apply: (HighlightConfig) -> Void
}

let presets: [Preset] = [
    Preset(name: "Default Yellow") { c in
        c.shape = .circle; c.radius = 30
        c.fillColor = .yellow; c.fillOpacity = 0.35
        c.borderColor = .orange; c.borderOpacity = 0.7
        c.borderWidth = 2.5; c.clickEffect = .colorChange
        c.clickColor = .red; c.clickOpacity = 0.5
    },
    Preset(name: "Neon Ring") { c in
        c.shape = .ring; c.radius = 28
        c.fillColor = .cyan; c.fillOpacity = 0.0
        c.borderColor = .cyan; c.borderOpacity = 0.9
        c.borderWidth = 3.0; c.clickEffect = .pulse
        c.clickColor = .white; c.clickOpacity = 0.8
    },
    Preset(name: "Red Crosshair") { c in
        c.shape = .crosshair; c.radius = 24
        c.fillColor = .red; c.fillOpacity = 0.0
        c.borderColor = .red; c.borderOpacity = 0.85
        c.borderWidth = 2.0; c.clickEffect = .colorChange
        c.clickColor = .yellow; c.clickOpacity = 0.9
    },
    Preset(name: "Soft Spotlight") { c in
        c.shape = .spotlight; c.radius = 50
        c.fillColor = .white; c.fillOpacity = 0.15
        c.borderColor = .white; c.borderOpacity = 0.3
        c.borderWidth = 1.5; c.clickEffect = .ripple
        c.clickColor = .white; c.clickOpacity = 0.5
    },
    Preset(name: "Green Diamond") { c in
        c.shape = .diamond; c.radius = 22
        c.fillColor = .green; c.fillOpacity = 0.25
        c.borderColor = .green; c.borderOpacity = 0.8
        c.borderWidth = 2.5; c.clickEffect = .pulse
        c.clickColor = .green; c.clickOpacity = 0.7
    },
    Preset(name: "Sniper Target") { c in
        c.shape = .target; c.radius = 30
        c.fillColor = .red; c.fillOpacity = 0.0
        c.borderColor = .red; c.borderOpacity = 0.75
        c.borderWidth = 1.5; c.clickEffect = .colorChange
        c.clickColor = .yellow; c.clickOpacity = 0.9
    },
    Preset(name: "Blue Glow") { c in
        c.shape = .glow; c.radius = 35
        c.fillColor = .systemBlue; c.fillOpacity = 0.2
        c.borderColor = .systemBlue; c.borderOpacity = 0.0
        c.borderWidth = 0; c.clickEffect = .ripple
        c.clickColor = .systemBlue; c.clickOpacity = 0.6
    },
    Preset(name: "Purple Pulse") { c in
        c.shape = .circle; c.radius = 26
        c.fillColor = .purple; c.fillOpacity = 0.3
        c.borderColor = .magenta; c.borderOpacity = 0.8
        c.borderWidth = 3.0; c.clickEffect = .pulse
        c.clickColor = .magenta; c.clickOpacity = 0.7
    },
    Preset(name: "Minimal Dot") { c in
        c.shape = .circle; c.radius = 10
        c.fillColor = .white; c.fillOpacity = 0.5
        c.borderColor = .gray; c.borderOpacity = 0.6
        c.borderWidth = 1.0; c.clickEffect = .colorChange
        c.clickColor = .red; c.clickOpacity = 0.7
    },
]

// MARK: - Snapshot Manager

struct ClickSnapshot {
    let stepNumber: Int
    let timestamp: Date
    let cursorPosition: CGPoint
    let imagePath: String
}

class SnapshotManager {
    var isRecording = false
    var snapshots: [ClickSnapshot] = []
    var sessionDir: URL?
    var onSnapshotCountChanged: ((Int) -> Void)?

    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss.SSS"
        return f
    }()

    private let fileDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        return f
    }()

    func startSession() {
        let sessionName = "CursorHighlight_\(fileDateFormatter.string(from: Date()))"
        let desktopDir = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first!
        sessionDir = desktopDir.appendingPathComponent(sessionName)
        try? FileManager.default.createDirectory(at: sessionDir!, withIntermediateDirectories: true)
        snapshots = []
        isRecording = true
        onSnapshotCountChanged?(0)
    }

    func stopSession() {
        isRecording = false
    }

    func captureSnapshot(at position: CGPoint) {
        guard isRecording, let sessionDir = sessionDir else { return }

        let stepNumber = snapshots.count + 1
        let fileName = String(format: "step_%03d.png", stepNumber)
        let filePath = sessionDir.appendingPathComponent(fileName)
        let timestamp = Date()

        // Find the screen containing the cursor (NSScreen coords)
        let screen = NSScreen.screens.first(where: { $0.frame.contains(position) }) ?? NSScreen.main!
        // Convert NSScreen frame to CGWindowList coordinates (origin top-left)
        let mainHeight = NSScreen.screens.map { $0.frame.maxY }.max() ?? 0
        let captureRect = CGRect(
            x: screen.frame.origin.x,
            y: mainHeight - screen.frame.maxY,
            width: screen.frame.width,
            height: screen.frame.height
        )

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }

            Thread.sleep(forTimeInterval: 0.05)

            var hasImage = false
            if let screenshot = CGWindowListCreateImage(
                captureRect,
                .optionOnScreenOnly,
                kCGNullWindowID,
                [.bestResolution]
            ) {
                let bitmapRep = NSBitmapImageRep(cgImage: screenshot)
                if let pngData = bitmapRep.representation(using: .png, properties: [:]) {
                    do {
                        try pngData.write(to: filePath)
                        hasImage = true
                    } catch {
                        NSLog("CursorHighlight: Failed to write snapshot: \(error)")
                    }
                }
            } else {
                NSLog("CursorHighlight: Screenshot capture failed — check Screen Recording permission")
            }

            let snapshot = ClickSnapshot(
                stepNumber: stepNumber,
                timestamp: timestamp,
                cursorPosition: position,
                imagePath: hasImage ? filePath.path : ""
            )

            DispatchQueue.main.async {
                self.snapshots.append(snapshot)
                self.onSnapshotCountChanged?(self.snapshots.count)
            }
        }
    }

    var lastReportError: String = ""

    func generateReport() -> URL? {
        guard let sessionDir = sessionDir, !snapshots.isEmpty else {
            lastReportError = "sessionDir=\(sessionDir?.path ?? "nil"), snapshots=\(snapshots.count)"
            return nil
        }

        let reportPath = sessionDir.appendingPathComponent("report.html")
        let sessionDate = fileDateFormatter.string(from: snapshots.first?.timestamp ?? Date())

        var html = """
        <!DOCTYPE html>
        <html lang="en">
        <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Click Steps Report - \(sessionDate)</title>
        <style>
            * { margin: 0; padding: 0; box-sizing: border-box; }
            body { font-family: -apple-system, BlinkMacSystemFont, 'SF Pro', sans-serif; background: #1a1a2e; color: #e0e0e0; padding: 40px; }
            h1 { text-align: center; font-size: 28px; margin-bottom: 8px; color: #fff; }
            .subtitle { text-align: center; color: #888; margin-bottom: 40px; font-size: 14px; }
            .summary { display: flex; justify-content: center; gap: 40px; margin-bottom: 40px; }
            .summary-item { text-align: center; }
            .summary-item .value { font-size: 32px; font-weight: 700; color: #4fc3f7; }
            .summary-item .label { font-size: 12px; color: #888; text-transform: uppercase; letter-spacing: 1px; }
            .step { background: #16213e; border-radius: 12px; margin-bottom: 24px; overflow: hidden; border: 1px solid #1a1a40; }
            .step-header { display: flex; align-items: center; padding: 16px 24px; gap: 20px; border-bottom: 1px solid #1a1a40; }
            .step-number { background: #4fc3f7; color: #1a1a2e; font-weight: 700; font-size: 14px; width: 36px; height: 36px; border-radius: 50%; display: flex; align-items: center; justify-content: center; flex-shrink: 0; }
            .step-meta { flex: 1; }
            .step-time { font-size: 16px; font-weight: 600; }
            .step-pos { font-size: 12px; color: #888; margin-top: 2px; }
            .step-img { width: 100%; display: block; cursor: pointer; transition: transform 0.2s; }
            .step-img:hover { transform: scale(1.01); }
            .step-img-container { position: relative; }
            .cursor-dot { position: absolute; width: 12px; height: 12px; background: #ff4444; border: 2px solid #fff; border-radius: 50%; transform: translate(-50%, -50%); pointer-events: none; box-shadow: 0 0 8px rgba(255,68,68,0.6); }
        </style>
        </head>
        <body>
        <h1>Click Steps Report</h1>
        <p class="subtitle">Generated by Cursor Highlight</p>
        <div class="summary">
            <div class="summary-item"><div class="value">\(snapshots.count)</div><div class="label">Total Steps</div></div>
        """

        if let first = snapshots.first, let last = snapshots.last {
            let duration = last.timestamp.timeIntervalSince(first.timestamp)
            let mins = Int(duration) / 60
            let secs = Int(duration) % 60
            html += """
                <div class="summary-item"><div class="value">\(mins)m \(secs)s</div><div class="label">Duration</div></div>
            """
        }

        html += """
        </div>
        """

        for snapshot in snapshots {
            let timeStr = dateFormatter.string(from: snapshot.timestamp)

            var imgHtml: String
            if !snapshot.imagePath.isEmpty, FileManager.default.fileExists(atPath: snapshot.imagePath) {
                let fileName = URL(fileURLWithPath: snapshot.imagePath).lastPathComponent
                imgHtml = """
                    <div class="step-img-container">
                        <img class="step-img" src="\(fileName)" alt="Step \(snapshot.stepNumber)">
                    </div>
                """
            } else {
                imgHtml = """
                    <div style="padding:40px;text-align:center;color:#666;font-style:italic;">Screenshot unavailable — Screen Recording permission required</div>
                """
            }

            html += """
            <div class="step">
                <div class="step-header">
                    <div class="step-number">\(snapshot.stepNumber)</div>
                    <div class="step-meta">
                        <div class="step-time">\(timeStr)</div>
                        <div class="step-pos">Cursor: (\(Int(snapshot.cursorPosition.x)), \(Int(snapshot.cursorPosition.y)))</div>
                    </div>
                </div>
                \(imgHtml)
            </div>
            """
        }

        html += """
        </body>
        </html>
        """

        do {
            try html.write(to: reportPath, atomically: true, encoding: .utf8)
        } catch {
            lastReportError = "Write failed: \(error.localizedDescription)\nPath: \(reportPath.path)"
            return nil
        }
        return reportPath
    }

    func clearSession() {
        if let sessionDir = sessionDir {
            try? FileManager.default.removeItem(at: sessionDir)
        }
        snapshots = []
        sessionDir = nil
        isRecording = false
        onSnapshotCountChanged?(0)
    }
}

// MARK: - Highlight View (Drawing)

class HighlightView: NSView {
    var config = HighlightConfig()
    var isClicked = false
    var clickAnimationProgress: CGFloat = 0 // 0..1 for pulse/ripple
    var ripplePhase: CGFloat = 0

    override func draw(_ dirtyRect: NSRect) {
        guard let ctx = NSGraphicsContext.current?.cgContext else { return }
        ctx.clear(bounds)

        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let r = config.radius
        let bw = config.borderWidth
        let fill = isClicked && config.clickEffect == .colorChange ? config.effectiveClickColor : config.effectiveFillColor
        let stroke = isClicked && config.clickEffect == .colorChange ? config.effectiveClickColor : config.effectiveBorderColor

        switch config.shape {
        case .circle:
            drawCircle(ctx: ctx, center: center, radius: r, borderWidth: bw, fill: fill, stroke: stroke)

        case .ring:
            drawRing(ctx: ctx, center: center, radius: r, borderWidth: max(bw, 2), stroke: stroke)

        case .crosshair:
            drawCrosshair(ctx: ctx, center: center, radius: r, lineWidth: bw, color: stroke)

        case .spotlight:
            drawSpotlight(ctx: ctx, center: center, radius: r, fill: fill, stroke: stroke, borderWidth: bw)

        case .diamond:
            drawDiamond(ctx: ctx, center: center, radius: r, borderWidth: bw, fill: fill, stroke: stroke)

        case .target:
            drawTarget(ctx: ctx, center: center, radius: r, lineWidth: bw, color: stroke)

        case .glow:
            drawGlow(ctx: ctx, center: center, radius: r, color: fill)
        
        case .rectangle:
            // Display a rectangle at the cursor position
            let rectSize = r * 2
            let rect = CGRect(x: center.x - rectSize/2, y: center.y - rectSize/2, width: rectSize, height: rectSize)
            ctx.setFillColor(fill.cgColor)
            ctx.fill(rect)
            if bw > 0 {
                ctx.setStrokeColor(stroke.cgColor)
                ctx.setLineWidth(bw)
                ctx.stroke(rect)
            }
        }

        // Overlay click effects
        if isClicked && config.showClickEffect {
            switch config.clickEffect {
            case .pulse:
                let pulseR = r * (1.0 + clickAnimationProgress * 0.4)
                let alpha = (1.0 - clickAnimationProgress) * 0.5
                let pulseColor = config.clickColor.withAlphaComponent(alpha)
                let rect = CGRect(x: center.x - pulseR, y: center.y - pulseR, width: pulseR * 2, height: pulseR * 2)
                ctx.setStrokeColor(pulseColor.cgColor)
                ctx.setLineWidth(2)
                ctx.strokeEllipse(in:rect)

            case .ripple:
                for i in 0..<3 {
                    let phase = (ripplePhase + CGFloat(i) * 0.33).truncatingRemainder(dividingBy: 1.0)
                    let rippleR = r * (1.0 + phase * 0.6)
                    let alpha = (1.0 - phase) * 0.4
                    let rippleColor = config.clickColor.withAlphaComponent(alpha)
                    let rect = CGRect(x: center.x - rippleR, y: center.y - rippleR, width: rippleR * 2, height: rippleR * 2)
                    ctx.setStrokeColor(rippleColor.cgColor)
                    ctx.setLineWidth(1.5)
                    ctx.strokeEllipse(in:rect)
                }

            case .colorChange, .none:
                break
            }
        }
    }

    // MARK: Shape Drawings

    func drawCircle(ctx: CGContext, center: CGPoint, radius: CGFloat, borderWidth: CGFloat, fill: NSColor, stroke: NSColor) {
        let rect = CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)
        ctx.setFillColor(fill.cgColor)
        ctx.fillEllipse(in:rect)
        if borderWidth > 0 {
            ctx.setStrokeColor(stroke.cgColor)
            ctx.setLineWidth(borderWidth)
            ctx.strokeEllipse(in:rect.insetBy(dx: borderWidth / 2, dy: borderWidth / 2))
        }
    }

    func drawRing(ctx: CGContext, center: CGPoint, radius: CGFloat, borderWidth: CGFloat, stroke: NSColor) {
        let rect = CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)
        ctx.setStrokeColor(stroke.cgColor)
        ctx.setLineWidth(borderWidth)
        ctx.strokeEllipse(in:rect)
    }

    func drawCrosshair(ctx: CGContext, center: CGPoint, radius: CGFloat, lineWidth: CGFloat, color: NSColor) {
        let lw = max(lineWidth, 1.5)
        let gap: CGFloat = 6
        ctx.setStrokeColor(color.cgColor)
        ctx.setLineWidth(lw)

        // Horizontal lines
        ctx.move(to: CGPoint(x: center.x - radius, y: center.y))
        ctx.addLine(to: CGPoint(x: center.x - gap, y: center.y))
        ctx.move(to: CGPoint(x: center.x + gap, y: center.y))
        ctx.addLine(to: CGPoint(x: center.x + radius, y: center.y))

        // Vertical lines
        ctx.move(to: CGPoint(x: center.x, y: center.y - radius))
        ctx.addLine(to: CGPoint(x: center.x, y: center.y - gap))
        ctx.move(to: CGPoint(x: center.x, y: center.y + gap))
        ctx.addLine(to: CGPoint(x: center.x, y: center.y + radius))

        ctx.strokePath()

        // Small center dot
        let dotR: CGFloat = 2
        ctx.setFillColor(color.cgColor)
        ctx.fillEllipse(in:CGRect(x: center.x - dotR, y: center.y - dotR, width: dotR * 2, height: dotR * 2))
    }

    func drawSpotlight(ctx: CGContext, center: CGPoint, radius: CGFloat, fill: NSColor, stroke: NSColor, borderWidth: CGFloat) {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let comps = fill.cgColor.components ?? [1, 1, 1, 0.2]
        let r = comps.count > 0 ? comps[0] : 1.0
        let g = comps.count > 1 ? comps[1] : 1.0
        let b = comps.count > 2 ? comps[2] : 1.0
        let a = comps.count > 3 ? comps[3] : 0.2
        let colors = [
            CGColor(colorSpace: colorSpace, components: [r, g, b, a])!,
            CGColor(colorSpace: colorSpace, components: [r, g, b, 0])!
        ] as CFArray
        if let gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: [0, 1]) {
            ctx.drawRadialGradient(gradient, startCenter: center, startRadius: 0, endCenter: center, endRadius: radius, options: [])
        }
        if borderWidth > 0 {
            let rect = CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)
            ctx.setStrokeColor(stroke.cgColor)
            ctx.setLineWidth(borderWidth)
            ctx.strokeEllipse(in:rect)
        }
    }

    func drawDiamond(ctx: CGContext, center: CGPoint, radius: CGFloat, borderWidth: CGFloat, fill: NSColor, stroke: NSColor) {
        let path = CGMutablePath()
        path.move(to: CGPoint(x: center.x, y: center.y + radius))
        path.addLine(to: CGPoint(x: center.x + radius, y: center.y))
        path.addLine(to: CGPoint(x: center.x, y: center.y - radius))
        path.addLine(to: CGPoint(x: center.x - radius, y: center.y))
        path.closeSubpath()
        ctx.addPath(path)
        ctx.setFillColor(fill.cgColor)
        ctx.fillPath()
        if borderWidth > 0 {
            ctx.addPath(path)
            ctx.setStrokeColor(stroke.cgColor)
            ctx.setLineWidth(borderWidth)
            ctx.strokePath()
        }
    }

    func drawTarget(ctx: CGContext, center: CGPoint, radius: CGFloat, lineWidth: CGFloat, color: NSColor) {
        let lw = max(lineWidth, 1.0)
        ctx.setStrokeColor(color.cgColor)
        ctx.setLineWidth(lw)

        // Outer ring
        let outer = CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)
        ctx.strokeEllipse(in:outer)

        // Middle ring
        let midR = radius * 0.6
        let mid = CGRect(x: center.x - midR, y: center.y - midR, width: midR * 2, height: midR * 2)
        ctx.strokeEllipse(in:mid)

        // Inner dot
        let dotR = radius * 0.15
        ctx.setFillColor(color.cgColor)
        ctx.fillEllipse(in:CGRect(x: center.x - dotR, y: center.y - dotR, width: dotR * 2, height: dotR * 2))

        // Cross lines from outer to beyond
        let ext = radius + 8
        ctx.setLineWidth(lw * 0.8)
        ctx.move(to: CGPoint(x: center.x - ext, y: center.y))
        ctx.addLine(to: CGPoint(x: center.x - radius + 4, y: center.y))
        ctx.move(to: CGPoint(x: center.x + radius - 4, y: center.y))
        ctx.addLine(to: CGPoint(x: center.x + ext, y: center.y))
        ctx.move(to: CGPoint(x: center.x, y: center.y - ext))
        ctx.addLine(to: CGPoint(x: center.x, y: center.y - radius + 4))
        ctx.move(to: CGPoint(x: center.x, y: center.y + radius - 4))
        ctx.addLine(to: CGPoint(x: center.x, y: center.y + ext))
        ctx.strokePath()
    }

    func drawGlow(ctx: CGContext, center: CGPoint, radius: CGFloat, color: NSColor) {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let comps = color.cgColor.components ?? [0.3, 0.5, 1, 0.3]
        let r = comps.count > 0 ? comps[0] : 0.3
        let g = comps.count > 1 ? comps[1] : 0.5
        let b = comps.count > 2 ? comps[2] : 1.0
        let a = comps.count > 3 ? comps[3] : 0.3
        let colors = [
            CGColor(colorSpace: colorSpace, components: [r, g, b, a * 1.5])!,
            CGColor(colorSpace: colorSpace, components: [r, g, b, a * 0.7])!,
            CGColor(colorSpace: colorSpace, components: [r, g, b, 0])!
        ] as CFArray
        if let gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: [0, 0.5, 1]) {
            ctx.drawRadialGradient(gradient, startCenter: center, startRadius: 0, endCenter: center, endRadius: radius, options: [])
        }
    }
}

// MARK: - Highlight Window Controller

class HighlightWindowController {
    var config: HighlightConfig
    let window: NSWindow
    let highlightView: HighlightView
    var trackingTimer: Timer?
    var clickFadeTimer: Timer?
    var animationTimer: Timer?

    // Selection rectangle
    struct RectOverlay {
        let window: NSWindow
        let fillLayer: CAShapeLayer
        let borderLayer: CAShapeLayer
        let screenFrame: NSRect  // screen frame in global NS coords
    }
    var rectOverlays: [RectOverlay] = []
    var dragOrigin: CGPoint? = nil
    var isDragging = false
    var rectVisible = false
    var isActive = true
    var eventTap: CFMachPort?
    var snapshotManager = SnapshotManager()

    init(config: HighlightConfig) {
        self.config = config

        let size = config.windowSize
        let frame = NSRect(x: 0, y: 0, width: size, height: size)

        window = NSWindow(
            contentRect: frame,
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )
        window.isOpaque = false
        window.backgroundColor = .clear
        window.level = .screenSaver
        window.ignoresMouseEvents = true
        window.hasShadow = false
        window.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]

        highlightView = HighlightView(frame: frame)
        highlightView.config = config
        window.contentView = highlightView
    }

    func applyConfig() {
        highlightView.config = config
        let size = config.windowSize
        let frame = NSRect(x: 0, y: 0, width: size, height: size)
        window.setContentSize(NSSize(width: size, height: size))
        highlightView.frame = frame
        highlightView.needsDisplay = true
    }

    private func setupRectWindows() {
        for screen in NSScreen.screens {
            let frame = screen.frame

            let rw = NSWindow(
                contentRect: frame,
                styleMask: .borderless,
                backing: .buffered,
                defer: false
            )
            rw.isOpaque = false
            rw.backgroundColor = .clear
            rw.level = .screenSaver
            rw.ignoresMouseEvents = true
            rw.hasShadow = false
            rw.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
            rw.setFrame(frame, display: false)

            let cv = NSView(frame: NSRect(origin: .zero, size: frame.size))
            cv.wantsLayer = true
            rw.contentView = cv

            let fill = CAShapeLayer()
            fill.fillColor = NSColor.systemBlue.withAlphaComponent(0.15).cgColor
            fill.strokeColor = nil
            cv.layer?.addSublayer(fill)

            let border = CAShapeLayer()
            border.fillColor = nil
            border.strokeColor = NSColor.systemBlue.withAlphaComponent(0.8).cgColor
            border.lineWidth = 2.0
            cv.layer?.addSublayer(border)

            rectOverlays.append(RectOverlay(window: rw, fillLayer: fill, borderLayer: border, screenFrame: frame))
        }
    }

    func start() {
        window.orderFront(nil)
        updatePosition()
        setupRectWindows()

        trackingTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { [weak self] _ in
            self?.tick()
        }
        RunLoop.current.add(trackingTimer!, forMode: .common)

        setupEventTap()

        NSEvent.addGlobalMonitorForEvents(matching: [.rightMouseDown]) { [weak self] _ in
            self?.clearRect()
            self?.isDragging = false
            self?.dragOrigin = nil
        }
    }

    func setupEventTap() {
        let eventMask: CGEventMask = (1 << CGEventType.leftMouseDown.rawValue)
            | (1 << CGEventType.leftMouseUp.rawValue)
            | (1 << CGEventType.leftMouseDragged.rawValue)

        let controller = Unmanaged.passUnretained(self)

        guard let tap = CGEvent.tapCreate(
            tap: .cghidEventTap,
            place: .headInsertEventTap,
            options: .defaultTap, // active tap — can modify/suppress events
            eventsOfInterest: eventMask,
            callback: { (proxy, type, event, refcon) -> Unmanaged<CGEvent>? in
                guard let refcon = refcon else { return Unmanaged.passUnretained(event) }
                let ctrl = Unmanaged<HighlightWindowController>.fromOpaque(refcon).takeUnretainedValue()

                // If the tap gets disabled by the system, re-enable it
                if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
                    if let tap = ctrl.eventTap {
                        CGEvent.tapEnable(tap: tap, enable: true)
                    }
                    return Unmanaged.passUnretained(event)
                }

                guard ctrl.isActive else { return Unmanaged.passUnretained(event) }

                switch type {
                case .leftMouseDown:
                    ctrl.animateClick()
                    ctrl.dragOrigin = NSEvent.mouseLocation
                    ctrl.isDragging = true
                    ctrl.clearRect()
                    // Pass through the initial click
                    return Unmanaged.passUnretained(event)

                case .leftMouseUp:
                    ctrl.animateRelease()
                    let wasDraggingRect = ctrl.isDragging && ctrl.rectVisible
                    if ctrl.isDragging {
                        ctrl.isDragging = false
                        if let origin = ctrl.dragOrigin {
                            let pos = NSEvent.mouseLocation
                            if abs(pos.x - origin.x) < 5 && abs(pos.y - origin.y) < 5 {
                                ctrl.clearRect()
                            }
                        }
                    }
                    // Suppress mouse-up if we were drawing a rectangle
                    if wasDraggingRect {
                        return nil
                    }
                    return Unmanaged.passUnretained(event)

                case .leftMouseDragged:
                    // Suppress drag events while drawing a selection rectangle
                    if ctrl.isDragging && ctrl.rectVisible {
                        return nil
                    }
                    return Unmanaged.passUnretained(event)

                default:
                    return Unmanaged.passUnretained(event)
                }
            },
            userInfo: controller.toOpaque()
        ) else {
            // Fallback: if event tap fails (no Accessibility permission), use global monitors
            NSLog("CursorHighlight: CGEvent tap failed — falling back to global monitors (text selection during drag won't be suppressed). Grant Accessibility permission in System Settings to enable suppression.")
            NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown]) { [weak self] _ in
                guard let self = self, self.isActive else { return }
                self.animateClick()
                self.dragOrigin = NSEvent.mouseLocation
                self.isDragging = true
                self.clearRect()
            }
            NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseUp]) { [weak self] _ in
                guard let self = self, self.isActive else { return }
                self.animateRelease()
                if self.isDragging {
                    self.isDragging = false
                    if let origin = self.dragOrigin {
                        let pos = NSEvent.mouseLocation
                        if abs(pos.x - origin.x) < 5 && abs(pos.y - origin.y) < 5 {
                            self.clearRect()
                        }
                    }
                }
            }
            return
        }

        self.eventTap = tap
        let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
    }

    func tick() {
        updatePosition()
        updateRect()
    }

    func updatePosition() {
        let mouseLocation = NSEvent.mouseLocation
        let size = config.windowSize
        let origin = CGPoint(x: mouseLocation.x - size / 2, y: mouseLocation.y - size / 2)
        window.setFrameOrigin(origin)
    }

    func updateRect() {
        guard isDragging, let origin = dragOrigin else { return }

        // Double-check left button is still held
        if NSEvent.pressedMouseButtons & 1 == 0 {
            isDragging = false
            return
        }

        let pos = NSEvent.mouseLocation
        let w = abs(pos.x - origin.x)
        let h = abs(pos.y - origin.y)
        guard w > 3 || h > 3 else { return }

        // The selection rectangle in screen coordinates
        let selectionRect = NSRect(
            x: min(origin.x, pos.x),
            y: min(origin.y, pos.y),
            width: w,
            height: h
        )

        if !rectVisible {
            for overlay in rectOverlays {
                overlay.window.orderFront(nil)
            }
            rectVisible = true
        }

        for overlay in rectOverlays {
            let sf = overlay.screenFrame
            let intersection = selectionRect.intersection(sf)

            CATransaction.begin()
            CATransaction.setDisableActions(true)
            if !intersection.isNull && intersection.width > 0 && intersection.height > 0 {
                let localRect = NSRect(
                    x: intersection.origin.x - sf.origin.x,
                    y: intersection.origin.y - sf.origin.y,
                    width: intersection.width,
                    height: intersection.height
                )
                let path = CGPath(rect: localRect, transform: nil)
                overlay.fillLayer.path = path
                overlay.borderLayer.path = path
            } else {
                overlay.fillLayer.path = nil
                overlay.borderLayer.path = nil
            }
            CATransaction.commit()
        }
    }

    func clearRect() {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        for overlay in rectOverlays {
            overlay.fillLayer.path = nil
            overlay.borderLayer.path = nil
            overlay.window.orderOut(nil)
        }
        CATransaction.commit()
        rectVisible = false
    }

    func animateClick() {
        clickFadeTimer?.invalidate()
        animationTimer?.invalidate()
        highlightView.isClicked = true
        highlightView.clickAnimationProgress = 0
        highlightView.ripplePhase = 0
        highlightView.needsDisplay = true

        // Capture snapshot if recording
        if snapshotManager.isRecording {
            snapshotManager.captureSnapshot(at: NSEvent.mouseLocation)
        }

        if config.clickEffect == .pulse || config.clickEffect == .ripple {
            var elapsed: CGFloat = 0
            animationTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { [weak self] timer in
                guard let self = self else { timer.invalidate(); return }
                elapsed += 1.0 / 60.0
                if self.config.clickEffect == .pulse {
                    self.highlightView.clickAnimationProgress = min(elapsed / 0.4, 1.0)
                } else {
                    self.highlightView.ripplePhase = (elapsed * 1.5).truncatingRemainder(dividingBy: 1.0)
                }
                self.highlightView.needsDisplay = true
            }
            RunLoop.current.add(animationTimer!, forMode: .common)
        }
    }

    func animateRelease() {
        clickFadeTimer?.invalidate()
        clickFadeTimer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: false) { [weak self] _ in
            self?.animationTimer?.invalidate()
            self?.highlightView.isClicked = false
            self?.highlightView.clickAnimationProgress = 0
            self?.highlightView.needsDisplay = true
        }
    }
}


// MARK: - Preview View (for toolbox)

class PreviewView: NSView {
    var config = HighlightConfig()
    private let highlightView = HighlightView()

    override init(frame: NSRect) {
        super.init(frame: frame)
        wantsLayer = true
        layer?.backgroundColor = NSColor(white: 0.15, alpha: 1).cgColor
        layer?.cornerRadius = 8
        addSubview(highlightView)
    }
    required init?(coder: NSCoder) { fatalError() }

    func updatePreview(config: HighlightConfig) {
        self.config = config
        highlightView.config = config
        let size = config.windowSize
        highlightView.frame = NSRect(
            x: (bounds.width - size) / 2,
            y: (bounds.height - size) / 2,
            width: size,
            height: size
        )
        highlightView.needsDisplay = true
    }
}

// MARK: - Toolbox Window

class ToolboxWindowController: NSObject, NSWindowDelegate {
    let window: NSWindow
    var config: HighlightConfig
    var onConfigChanged: ((HighlightConfig) -> Void)?

    // Controls
    var shapePopup: NSPopUpButton!
    var radiusSlider: NSSlider!
    var radiusLabel: NSTextField!
    var fillColorWell: NSColorWell!
    var fillOpacitySlider: NSSlider!
    var fillOpacityLabel: NSTextField!
    var borderColorWell: NSColorWell!
    var borderOpacitySlider: NSSlider!
    var borderOpacityLabel: NSTextField!
    var borderWidthSlider: NSSlider!
    var borderWidthLabel: NSTextField!
    var clickEffectPopup: NSPopUpButton!
    var clickColorWell: NSColorWell!
    var clickOpacitySlider: NSSlider!
    var clickOpacityLabel: NSTextField!
    var presetPopup: NSPopUpButton!
    var previewView: PreviewView!
    var snapshotToggle: NSButton!
    var snapshotCountLabel: NSTextField!
    var generateReportButton: NSButton!
    var clearSnapshotsButton: NSButton!
    weak var highlightController: HighlightWindowController?

    init(config: HighlightConfig) {
        self.config = config

        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 380, height: 740),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Cursor Highlight Toolbox"
        window.isReleasedWhenClosed = false
        window.center()

        super.init()
        window.delegate = self
        buildUI()
        syncControlsFromConfig()
    }

    func windowShouldClose(_ sender: NSWindow) -> Bool {
        window.orderOut(nil)
        NSApp.setActivationPolicy(.accessory)
        return false
    }

    func show() {
        NSApp.setActivationPolicy(.regular)
        window.level = .floating
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    // MARK: Build UI

    func buildUI() {
        let contentView = NSView(frame: window.contentView!.bounds)
        contentView.autoresizingMask = [.width, .height]
        window.contentView = contentView

        var y: CGFloat = 700

        // Preview
        let previewLabel = makeLabel("Preview", bold: true)
        previewLabel.frame.origin = CGPoint(x: 20, y: y)
        contentView.addSubview(previewLabel)
        y -= 110
        previewView = PreviewView(frame: NSRect(x: 20, y: y, width: 340, height: 100))
        contentView.addSubview(previewView)
        y -= 20

        // Presets
        y -= 20
        let presetLabel = makeLabel("Preset")
        presetLabel.frame.origin = CGPoint(x: 20, y: y + 2)
        contentView.addSubview(presetLabel)
        presetPopup = NSPopUpButton(frame: NSRect(x: 130, y: y, width: 230, height: 25))
        presetPopup.addItem(withTitle: "Custom")
        for p in presets { presetPopup.addItem(withTitle: p.name) }
        presetPopup.target = self
        presetPopup.action = #selector(presetChanged)
        contentView.addSubview(presetPopup)

        // Shape
        y -= 34
        let shapeLabel = makeLabel("Shape")
        shapeLabel.frame.origin = CGPoint(x: 20, y: y + 2)
        contentView.addSubview(shapeLabel)
        shapePopup = NSPopUpButton(frame: NSRect(x: 130, y: y, width: 230, height: 25))
        for s in HighlightShape.allCases { shapePopup.addItem(withTitle: s.name) }
        shapePopup.target = self
        shapePopup.action = #selector(controlChanged)
        contentView.addSubview(shapePopup)

        // Radius
        y -= 34
        let rLabel = makeLabel("Size")
        rLabel.frame.origin = CGPoint(x: 20, y: y + 2)
        contentView.addSubview(rLabel)
        radiusSlider = NSSlider(frame: NSRect(x: 130, y: y + 2, width: 190, height: 20))
        radiusSlider.minValue = 8; radiusSlider.maxValue = 80
        radiusSlider.target = self; radiusSlider.action = #selector(controlChanged)
        contentView.addSubview(radiusSlider)
        radiusLabel = makeValueLabel(frame: NSRect(x: 325, y: y + 2, width: 40, height: 18))
        contentView.addSubview(radiusLabel)

        // Separator
        y -= 20
        let sep1 = makeSeparator(y: y, width: 340)
        contentView.addSubview(sep1)

        // Fill Color section header
        y -= 22
        let fillHeader = makeLabel("Fill", bold: true)
        fillHeader.frame.origin = CGPoint(x: 20, y: y)
        contentView.addSubview(fillHeader)

        // Fill Color
        y -= 30
        let fcLabel = makeLabel("Color")
        fcLabel.frame.origin = CGPoint(x: 20, y: y + 2)
        contentView.addSubview(fcLabel)
        fillColorWell = NSColorWell(frame: NSRect(x: 130, y: y, width: 44, height: 24))
        fillColorWell.target = self; fillColorWell.action = #selector(controlChanged)
        contentView.addSubview(fillColorWell)

        // Fill Opacity
        y -= 30
        let foLabel = makeLabel("Opacity")
        foLabel.frame.origin = CGPoint(x: 20, y: y + 2)
        contentView.addSubview(foLabel)
        fillOpacitySlider = NSSlider(frame: NSRect(x: 130, y: y + 2, width: 190, height: 20))
        fillOpacitySlider.minValue = 0; fillOpacitySlider.maxValue = 1
        fillOpacitySlider.target = self; fillOpacitySlider.action = #selector(controlChanged)
        contentView.addSubview(fillOpacitySlider)
        fillOpacityLabel = makeValueLabel(frame: NSRect(x: 325, y: y + 2, width: 40, height: 18))
        contentView.addSubview(fillOpacityLabel)

        // Separator
        y -= 20
        contentView.addSubview(makeSeparator(y: y, width: 340))

        // Border section header
        y -= 22
        let borderHeader = makeLabel("Border", bold: true)
        borderHeader.frame.origin = CGPoint(x: 20, y: y)
        contentView.addSubview(borderHeader)

        // Border Color
        y -= 30
        let bcLabel = makeLabel("Color")
        bcLabel.frame.origin = CGPoint(x: 20, y: y + 2)
        contentView.addSubview(bcLabel)
        borderColorWell = NSColorWell(frame: NSRect(x: 130, y: y, width: 44, height: 24))
        borderColorWell.target = self; borderColorWell.action = #selector(controlChanged)
        contentView.addSubview(borderColorWell)

        // Border Opacity
        y -= 30
        let boLabel = makeLabel("Opacity")
        boLabel.frame.origin = CGPoint(x: 20, y: y + 2)
        contentView.addSubview(boLabel)
        borderOpacitySlider = NSSlider(frame: NSRect(x: 130, y: y + 2, width: 190, height: 20))
        borderOpacitySlider.minValue = 0; borderOpacitySlider.maxValue = 1
        borderOpacitySlider.target = self; borderOpacitySlider.action = #selector(controlChanged)
        contentView.addSubview(borderOpacitySlider)
        borderOpacityLabel = makeValueLabel(frame: NSRect(x: 325, y: y + 2, width: 40, height: 18))
        contentView.addSubview(borderOpacityLabel)

        // Border Width
        y -= 30
        let bwLabel = makeLabel("Width")
        bwLabel.frame.origin = CGPoint(x: 20, y: y + 2)
        contentView.addSubview(bwLabel)
        borderWidthSlider = NSSlider(frame: NSRect(x: 130, y: y + 2, width: 190, height: 20))
        borderWidthSlider.minValue = 0; borderWidthSlider.maxValue = 8
        borderWidthSlider.target = self; borderWidthSlider.action = #selector(controlChanged)
        contentView.addSubview(borderWidthSlider)
        borderWidthLabel = makeValueLabel(frame: NSRect(x: 325, y: y + 2, width: 40, height: 18))
        contentView.addSubview(borderWidthLabel)

        // Separator
        y -= 20
        contentView.addSubview(makeSeparator(y: y, width: 340))

        // Click Effect section header
        y -= 22
        let clickHeader = makeLabel("Click Effect", bold: true)
        clickHeader.frame.origin = CGPoint(x: 20, y: y)
        contentView.addSubview(clickHeader)

        // Click Effect type
        y -= 30
        let ceLabel = makeLabel("Effect")
        ceLabel.frame.origin = CGPoint(x: 20, y: y + 2)
        contentView.addSubview(ceLabel)
        clickEffectPopup = NSPopUpButton(frame: NSRect(x: 130, y: y, width: 230, height: 25))
        for e in ClickEffect.allCases { clickEffectPopup.addItem(withTitle: e.name) }
        clickEffectPopup.target = self; clickEffectPopup.action = #selector(controlChanged)
        contentView.addSubview(clickEffectPopup)

        // Click Color
        y -= 30
        let ccLabel = makeLabel("Color")
        ccLabel.frame.origin = CGPoint(x: 20, y: y + 2)
        contentView.addSubview(ccLabel)
        clickColorWell = NSColorWell(frame: NSRect(x: 130, y: y, width: 44, height: 24))
        clickColorWell.target = self; clickColorWell.action = #selector(controlChanged)
        contentView.addSubview(clickColorWell)

        // Click Opacity
        y -= 30
        let coLabel = makeLabel("Opacity")
        coLabel.frame.origin = CGPoint(x: 20, y: y + 2)
        contentView.addSubview(coLabel)
        clickOpacitySlider = NSSlider(frame: NSRect(x: 130, y: y + 2, width: 190, height: 20))
        clickOpacitySlider.minValue = 0; clickOpacitySlider.maxValue = 1
        clickOpacitySlider.target = self; clickOpacitySlider.action = #selector(controlChanged)
        contentView.addSubview(clickOpacitySlider)
        clickOpacityLabel = makeValueLabel(frame: NSRect(x: 325, y: y + 2, width: 40, height: 18))
        contentView.addSubview(clickOpacityLabel)

        // Separator
        y -= 20
        contentView.addSubview(makeSeparator(y: y, width: 340))

        // Snapshot Recording section header
        y -= 22
        let snapHeader = makeLabel("Snapshot Recording", bold: true)
        snapHeader.frame.origin = CGPoint(x: 20, y: y)
        contentView.addSubview(snapHeader)

        // Record toggle + count
        y -= 34
        snapshotToggle = NSButton(checkboxWithTitle: "Record click snapshots", target: self, action: #selector(snapshotToggleChanged))
        snapshotToggle.frame.origin = CGPoint(x: 20, y: y + 2)
        snapshotToggle.sizeToFit()
        contentView.addSubview(snapshotToggle)
        snapshotCountLabel = makeValueLabel(frame: NSRect(x: 260, y: y + 2, width: 100, height: 18))
        snapshotCountLabel.stringValue = "0 steps"
        snapshotCountLabel.alignment = .right
        contentView.addSubview(snapshotCountLabel)

        // Buttons row
        y -= 34
        generateReportButton = NSButton(frame: NSRect(x: 20, y: y, width: 165, height: 28))
        generateReportButton.title = "Generate Report"
        generateReportButton.bezelStyle = .rounded
        generateReportButton.target = self
        generateReportButton.action = #selector(onGenerateReport)
        contentView.addSubview(generateReportButton)

        clearSnapshotsButton = NSButton(frame: NSRect(x: 195, y: y, width: 165, height: 28))
        clearSnapshotsButton.title = "Clear Snapshots"
        clearSnapshotsButton.bezelStyle = .rounded
        clearSnapshotsButton.target = self
        clearSnapshotsButton.action = #selector(onClearSnapshots)
        contentView.addSubview(clearSnapshotsButton)
    }

    // MARK: Helpers

    func makeLabel(_ text: String, bold: Bool = false) -> NSTextField {
        let label = NSTextField(labelWithString: text)
        label.font = bold ? NSFont.boldSystemFont(ofSize: 13) : NSFont.systemFont(ofSize: 12)
        label.sizeToFit()
        return label
    }

    func makeValueLabel(frame: NSRect) -> NSTextField {
        let label = NSTextField(frame: frame)
        label.isEditable = false; label.isBordered = false
        label.backgroundColor = .clear
        label.font = NSFont.monospacedDigitSystemFont(ofSize: 11, weight: .regular)
        label.alignment = .right
        return label
    }

    func makeSeparator(y: CGFloat, width: CGFloat) -> NSBox {
        let sep = NSBox(frame: NSRect(x: 20, y: y, width: width, height: 1))
        sep.boxType = .separator
        return sep
    }

    // MARK: Sync

    func syncControlsFromConfig() {
        shapePopup.selectItem(at: config.shape.rawValue)
        radiusSlider.doubleValue = Double(config.radius)
        radiusLabel.stringValue = String(format: "%.0f", config.radius)
        fillColorWell.color = config.fillColor
        fillOpacitySlider.doubleValue = Double(config.fillOpacity)
        fillOpacityLabel.stringValue = String(format: "%.0f%%", config.fillOpacity * 100)
        borderColorWell.color = config.borderColor
        borderOpacitySlider.doubleValue = Double(config.borderOpacity)
        borderOpacityLabel.stringValue = String(format: "%.0f%%", config.borderOpacity * 100)
        borderWidthSlider.doubleValue = Double(config.borderWidth)
        borderWidthLabel.stringValue = String(format: "%.1f", config.borderWidth)
        clickEffectPopup.selectItem(at: config.clickEffect.rawValue)
        clickColorWell.color = config.clickColor
        clickOpacitySlider.doubleValue = Double(config.clickOpacity)
        clickOpacityLabel.stringValue = String(format: "%.0f%%", config.clickOpacity * 100)
        previewView.updatePreview(config: config)
    }

    func syncConfigFromControls() {
        config.shape = HighlightShape(rawValue: shapePopup.indexOfSelectedItem) ?? .circle
        config.radius = CGFloat(radiusSlider.doubleValue)
        config.fillColor = fillColorWell.color
        config.fillOpacity = CGFloat(fillOpacitySlider.doubleValue)
        config.borderColor = borderColorWell.color
        config.borderOpacity = CGFloat(borderOpacitySlider.doubleValue)
        config.borderWidth = CGFloat(borderWidthSlider.doubleValue)
        config.clickEffect = ClickEffect(rawValue: clickEffectPopup.indexOfSelectedItem) ?? .colorChange
        config.clickColor = clickColorWell.color
        config.clickOpacity = CGFloat(clickOpacitySlider.doubleValue)

        // Update value labels
        radiusLabel.stringValue = String(format: "%.0f", config.radius)
        fillOpacityLabel.stringValue = String(format: "%.0f%%", config.fillOpacity * 100)
        borderOpacityLabel.stringValue = String(format: "%.0f%%", config.borderOpacity * 100)
        borderWidthLabel.stringValue = String(format: "%.1f", config.borderWidth)
        clickOpacityLabel.stringValue = String(format: "%.0f%%", config.clickOpacity * 100)

        previewView.updatePreview(config: config)
        config.save()
        onConfigChanged?(config)
    }

    @objc func controlChanged(_ sender: Any?) {
        presetPopup.selectItem(at: 0) // switch to "Custom"
        syncConfigFromControls()
    }

    @objc func presetChanged(_ sender: Any?) {
        let idx = presetPopup.indexOfSelectedItem
        if idx > 0 {
            presets[idx - 1].apply(config)
            syncControlsFromConfig()
            config.save()
            onConfigChanged?(config)
        }
    }

    @objc func snapshotToggleChanged(_ sender: Any?) {
        guard let mgr = highlightController?.snapshotManager else { return }
        if snapshotToggle.state == .on {
            mgr.startSession()
            mgr.onSnapshotCountChanged = { [weak self] count in
                self?.snapshotCountLabel.stringValue = "\(count) step\(count == 1 ? "" : "s")"
                self?.generateReportButton.isEnabled = count > 0
                self?.clearSnapshotsButton.isEnabled = true
            }
        } else {
            mgr.stopSession()
            generateReportButton.isEnabled = !mgr.snapshots.isEmpty
        }
    }

    @objc func onGenerateReport(_ sender: Any?) {
        guard let mgr = highlightController?.snapshotManager else {
            let alert = NSAlert()
            alert.messageText = "No recording session"
            alert.informativeText = "Enable 'Record click snapshots' first."
            alert.runModal()
            return
        }

        let count = mgr.snapshots.count
        let dir = mgr.sessionDir?.path ?? "nil"

        if mgr.snapshots.isEmpty {
            let alert = NSAlert()
            alert.messageText = "No snapshots recorded"
            alert.informativeText = "Snapshots: \(count), sessionDir: \(dir)"
            alert.runModal()
            return
        }

        guard let reportURL = mgr.generateReport() else {
            let alert = NSAlert()
            alert.messageText = "Failed to generate report"
            alert.informativeText = "Snapshots: \(count), sessionDir: \(dir)\nError: \(mgr.lastReportError)"
            alert.runModal()
            return
        }

        // Open via /usr/bin/open which is always reliable
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        process.arguments = [reportURL.path]
        try? process.run()
    }

    @objc func onClearSnapshots(_ sender: Any?) {
        guard let mgr = highlightController?.snapshotManager else { return }
        mgr.clearSession()
        snapshotToggle.state = .off
        snapshotCountLabel.stringValue = "0 steps"
    }
}

// MARK: - Status Bar Menu

class StatusBarManager: NSObject {
    let statusItem: NSStatusItem
    var isVisible = true
    let controller: HighlightWindowController
    var toolbox: ToolboxWindowController?

    init(controller: HighlightWindowController) {
        self.controller = controller
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        super.init()
        setupMenu()
        registerGlobalHotkey()
    }

    func registerGlobalHotkey() {
        // Use Carbon hotkey API for reliable global shortcut
        let hotKeyID = EventHotKeyID(signature: OSType(0x4348_4C54), id: 1) // "CHLT"
        var hotKeyRef: EventHotKeyRef?

        // Ctrl+Shift+T: kVK_ANSI_T = 0x11, controlKey = 0x1000, shiftKey = 0x0200
        let modifiers: UInt32 = UInt32(controlKey | shiftKey)
        RegisterEventHotKey(UInt32(0x11), modifiers, hotKeyID,
                            GetApplicationEventTarget(), 0, &hotKeyRef)

        var eventSpec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard),
                                      eventKind: UInt32(kEventHotKeyPressed))

        let refcon = Unmanaged.passUnretained(self).toOpaque()
        InstallEventHandler(GetApplicationEventTarget(), { _, event, refcon -> OSStatus in
            guard let refcon = refcon else { return OSStatus(eventNotHandledErr) }
            let mgr = Unmanaged<StatusBarManager>.fromOpaque(refcon).takeUnretainedValue()
            DispatchQueue.main.async {
                mgr.toggleHighlight()
            }
            return noErr
        }, 1, &eventSpec, refcon, nil)
    }

    func setupMenu() {
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "cursor.rays", accessibilityDescription: "Cursor Highlight")
            button.image?.isTemplate = true
        }

        let menu = NSMenu()

        let toggleItem = NSMenuItem(title: "Toggle Highlight", action: #selector(toggleHighlight), keyEquivalent: "t")
        toggleItem.keyEquivalentModifierMask = [.control, .shift]
        toggleItem.target = self
        menu.addItem(toggleItem)

        menu.addItem(NSMenuItem.separator())

        let recordItem = NSMenuItem(title: "Start Recording Clicks", action: #selector(toggleRecording), keyEquivalent: "r")
        recordItem.keyEquivalentModifierMask = [.control, .shift]
        recordItem.target = self
        menu.addItem(recordItem)

        let reportItem = NSMenuItem(title: "Generate Report", action: #selector(generateReport), keyEquivalent: "")
        reportItem.target = self
        menu.addItem(reportItem)

        menu.addItem(NSMenuItem.separator())

        let toolboxItem = NSMenuItem(title: "Toolbox...", action: #selector(openToolbox), keyEquivalent: ",")
        toolboxItem.target = self
        menu.addItem(toolboxItem)

        menu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem.menu = menu
    }

    @objc func toggleHighlight() {
        isVisible.toggle()
        if isVisible {
            controller.isActive = true
            controller.window.orderFront(nil)
        } else {
            controller.isActive = false
            controller.clearRect()
            controller.isDragging = false
            controller.dragOrigin = nil
            controller.window.orderOut(nil)
        }
    }

    @objc func toggleRecording() {
        let mgr = controller.snapshotManager
        if mgr.isRecording {
            mgr.stopSession()
            updateRecordingMenuTitle()
        } else {
            mgr.startSession()
            mgr.onSnapshotCountChanged = { [weak self] count in
                self?.updateRecordingMenuTitle()
            }
            updateRecordingMenuTitle()
        }
        // Sync toolbox if open
        if let tb = toolbox {
            tb.snapshotToggle.state = mgr.isRecording ? .on : .off
        }
    }

    @objc func generateReport() {
        let mgr = controller.snapshotManager
        if mgr.snapshots.isEmpty {
            let alert = NSAlert()
            alert.messageText = "No snapshots recorded"
            alert.informativeText = "Start recording and click on the screen to capture steps first."
            alert.runModal()
            return
        }
        guard let reportURL = mgr.generateReport() else {
            let alert = NSAlert()
            alert.messageText = "Failed to generate report"
            alert.informativeText = "Snapshots: \(mgr.snapshots.count)\nsessionDir: \(mgr.sessionDir?.path ?? "nil")\nError: \(mgr.lastReportError)"
            alert.runModal()
            return
        }
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        process.arguments = [reportURL.path]
        try? process.run()
    }

    func updateRecordingMenuTitle() {
        guard let menu = statusItem.menu else { return }
        let mgr = controller.snapshotManager
        // Recording item is at index 2 (after toggle + separator)
        if menu.items.count > 2 {
            let item = menu.items[2]
            if mgr.isRecording {
                let count = mgr.snapshots.count
                item.title = "Stop Recording (\(count) step\(count == 1 ? "" : "s"))"
            } else {
                item.title = "Start Recording Clicks"
            }
        }
        // Report item
        if menu.items.count > 3 {
            menu.items[3].isHidden = mgr.snapshots.isEmpty && !mgr.isRecording
        }
    }

    @objc func openToolbox() {
        if toolbox == nil {
            toolbox = ToolboxWindowController(config: controller.config)
            toolbox?.highlightController = controller
            toolbox?.onConfigChanged = { [weak self] config in
                guard let self = self else { return }
                self.controller.config = config
                self.controller.applyConfig()
            }
        }
        toolbox?.show()
    }

    @objc func quit() {
        NSApplication.shared.terminate(nil)
    }
}

// MARK: - App Delegate

class AppDelegate: NSObject, NSApplicationDelegate {
    var controller: HighlightWindowController!
    var statusBarManager: StatusBarManager!

    func applicationDidFinishLaunching(_ notification: Notification) {
        let config = HighlightConfig.load()
        controller = HighlightWindowController(config: config)
        statusBarManager = StatusBarManager(controller: controller)
        controller.start()
    }
}

// MARK: - Main

let app = NSApplication.shared
app.setActivationPolicy(.accessory)
let delegate = AppDelegate()
app.delegate = delegate
app.run()
