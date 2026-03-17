import Cocoa

// MARK: - Enums

enum HighlightShape: Int, CaseIterable {
    case circle = 0
    case ring
    case crosshair
    case spotlight
    case diamond
    case target
    case glow

    var name: String {
        switch self {
        case .circle:    return "Circle"
        case .ring:      return "Ring"
        case .crosshair: return "Crosshair"
        case .spotlight:  return "Spotlight"
        case .diamond:    return "Diamond"
        case .target:     return "Target"
        case .glow:       return "Glow"
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

    func start() {
        window.orderFront(nil)
        updatePosition()

        trackingTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { [weak self] _ in
            self?.updatePosition()
        }
        RunLoop.current.add(trackingTimer!, forMode: .common)

        NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            self?.animateClick()
        }
        NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseUp, .rightMouseUp]) { [weak self] _ in
            self?.animateRelease()
        }
    }

    func updatePosition() {
        let mouseLocation = NSEvent.mouseLocation
        let size = config.windowSize
        let origin = CGPoint(x: mouseLocation.x - size / 2, y: mouseLocation.y - size / 2)
        window.setFrameOrigin(origin)
    }

    func animateClick() {
        clickFadeTimer?.invalidate()
        animationTimer?.invalidate()
        highlightView.isClicked = true
        highlightView.clickAnimationProgress = 0
        highlightView.ripplePhase = 0
        highlightView.needsDisplay = true

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

    init(config: HighlightConfig) {
        self.config = config

        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 380, height: 620),
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

        var y: CGFloat = 580

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
            controller.window.orderFront(nil)
        } else {
            controller.window.orderOut(nil)
        }
    }

    @objc func openToolbox() {
        if toolbox == nil {
            toolbox = ToolboxWindowController(config: controller.config)
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
