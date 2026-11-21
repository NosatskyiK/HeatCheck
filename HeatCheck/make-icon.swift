// Draws the HeatCheck icon: a white thermometer on a blue background.
// Everything is drawn in code with custom shapes — no SF Symbols, no downloaded files.
// Run it via make-icon.sh.

import AppKit

let outputDir = CommandLine.arguments.dropFirst().first ?? "AppIcon.iconset"
try FileManager.default.createDirectory(atPath: outputDir, withIntermediateDirectories: true)

func rgb(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat, _ a: CGFloat = 1) -> NSColor {
    NSColor(srgbRed: r, green: g, blue: b, alpha: a)
}

/// A drop shadow. Shadows don't scale with the drawing, so multiply by k manually.
func shadow(y: CGFloat, blur: CGFloat, alpha: CGFloat, k: CGFloat) -> NSShadow {
    let s = NSShadow()
    s.shadowOffset = NSSize(width: 0, height: y * k)
    s.shadowBlurRadius = blur * k
    s.shadowColor = rgb(0, 0, 0, alpha)
    return s
}

/// Thermometer bulb + tube as a single shape.
func thermometerShape(cx: CGFloat, bulbY: CGFloat, bulbR: CGFloat, tubeHalf: CGFloat, top: CGFloat) -> NSBezierPath {
    let path = NSBezierPath(ovalIn: NSRect(x: cx - bulbR, y: bulbY - bulbR, width: bulbR * 2, height: bulbR * 2))
    path.append(NSBezierPath(roundedRect: NSRect(x: cx - tubeHalf, y: bulbY, width: tubeHalf * 2, height: top - bulbY),
                             xRadius: tubeHalf, yRadius: tubeHalf))
    return path
}

/// Draws the icon in 1024×1024 coordinates (origin at bottom left). k is the scale to pixels.
func drawIcon(k: CGFloat) {
    // Background: rounded square on the macOS icon grid (824×824 with a 100 px margin).
    let body = NSBezierPath(roundedRect: NSRect(x: 100, y: 100, width: 824, height: 824), xRadius: 185, yRadius: 185)
    NSGraphicsContext.saveGraphicsState()
    shadow(y: -12, blur: 28, alpha: 0.3, k: k).set()
    rgb(0.09, 0.20, 0.52).setFill()
    body.fill()
    NSGraphicsContext.restoreGraphicsState()
    NSGradient(starting: rgb(0.24, 0.58, 0.98), ending: rgb(0.09, 0.20, 0.52))!.draw(in: body, angle: -90)

    let cx: CGFloat = 470
    let bulbY: CGFloat = 325

    // White thermometer glass with a soft shadow.
    NSGraphicsContext.saveGraphicsState()
    shadow(y: -8, blur: 24, alpha: 0.25, k: k).set()
    rgb(1, 1, 1).setFill()
    thermometerShape(cx: cx, bulbY: bulbY, bulbR: 125, tubeHalf: 80, top: 825).fill()
    NSGraphicsContext.restoreGraphicsState()

    // Empty channel inside.
    rgb(0.86, 0.90, 0.96).setFill()
    thermometerShape(cx: cx, bulbY: bulbY, bulbR: 90, tubeHalf: 45, top: 790).fill()

    // Mercury column: red at the bottom to orange at the top.
    let mercury = thermometerShape(cx: cx, bulbY: bulbY, bulbR: 90, tubeHalf: 45, top: 620)
    NSGradient(starting: rgb(0.93, 0.20, 0.22), ending: rgb(1.0, 0.60, 0.20))!.draw(in: mercury, angle: 90)

    // Scale marks on the right.
    let ticks = NSBezierPath()
    ticks.lineWidth = 22
    ticks.lineCapStyle = .round
    for (i, y) in stride(from: CGFloat(450), through: 790, by: 68).enumerated() {
        let length: CGFloat = i.isMultiple(of: 2) ? 95 : 60
        ticks.move(to: NSPoint(x: cx + 120, y: y))
        ticks.line(to: NSPoint(x: cx + 120 + length, y: y))
    }
    rgb(1, 1, 1, 0.9).setStroke()
    ticks.stroke()
}

// The set of sizes macOS needs for an .icns file.
let sizes: [(name: String, px: Int)] = [
    ("icon_16x16", 16), ("icon_16x16@2x", 32),
    ("icon_32x32", 32), ("icon_32x32@2x", 64),
    ("icon_128x128", 128), ("icon_128x128@2x", 256),
    ("icon_256x256", 256), ("icon_256x256@2x", 512),
    ("icon_512x512", 512), ("icon_512x512@2x", 1024),
]

for (name, px) in sizes {
    guard let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: px, pixelsHigh: px,
                                     bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                                     colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0),
          let context = NSGraphicsContext(bitmapImageRep: rep)
    else { fatalError("Could not create a \(px)×\(px) image") }

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = context
    let k = CGFloat(px) / 1024
    context.cgContext.scaleBy(x: k, y: k)
    drawIcon(k: k)
    context.flushGraphics()
    NSGraphicsContext.restoreGraphicsState()

    guard let png = rep.representation(using: .png, properties: [:]) else { fatalError("Could not encode \(name).png") }
    try png.write(to: URL(fileURLWithPath: outputDir).appendingPathComponent("\(name).png"))
}
