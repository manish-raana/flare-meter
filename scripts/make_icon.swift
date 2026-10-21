import AppKit

// 1024×1024 macOS icon on Apple's grid: an 824pt rounded-square tile, a usage ring, a cloud inside.
let size: CGFloat = 1024
let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: Int(size), pixelsHigh: Int(size), bitsPerSample: 8,
                           samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
let ctx = NSGraphicsContext.current!.cgContext

let tile = CGRect(x: 100, y: 100, width: 824, height: 824)
let tilePath = CGPath(roundedRect: tile, cornerWidth: 185, cornerHeight: 185, transform: nil)

// Drop shadow.
ctx.saveGState()
ctx.setShadow(offset: CGSize(width: 0, height: -10), blur: 24, color: NSColor.black.withAlphaComponent(0.28).cgColor)
ctx.addPath(tilePath); ctx.setFillColor(NSColor.black.cgColor); ctx.fillPath()
ctx.restoreGState()

// Warm gradient tile.
ctx.saveGState()
ctx.addPath(tilePath); ctx.clip()
let colors = [NSColor(srgbRed: 1.00, green: 0.66, blue: 0.27, alpha: 1).cgColor,
              NSColor(srgbRed: 0.96, green: 0.38, blue: 0.13, alpha: 1).cgColor] as CFArray
let gradient = CGGradient(colorsSpace: CGColorSpace(name: CGColorSpace.sRGB), colors: colors, locations: [0, 1])!
ctx.drawLinearGradient(gradient, start: CGPoint(x: 512, y: 924), end: CGPoint(x: 512, y: 100), options: [])
// Soft top highlight.
let gloss = CGGradient(colorsSpace: CGColorSpace(name: CGColorSpace.sRGB),
                       colors: [NSColor.white.withAlphaComponent(0.22).cgColor, NSColor.white.withAlphaComponent(0).cgColor] as CFArray, locations: [0, 1])!
ctx.drawRadialGradient(gloss, startCenter: CGPoint(x: 512, y: 980), startRadius: 0, endCenter: CGPoint(x: 512, y: 980), endRadius: 620, options: [])
ctx.restoreGState()

// Usage ring: a faint track and a 70% arc, starting at 12 o'clock and running clockwise.
let center = CGPoint(x: 512, y: 512)
let radius: CGFloat = 292
ctx.setLineWidth(58)
ctx.setLineCap(.round)
ctx.setStrokeColor(NSColor.white.withAlphaComponent(0.25).cgColor)
ctx.addArc(center: center, radius: radius, startAngle: 0, endAngle: .pi * 2, clockwise: false); ctx.strokePath()
ctx.setStrokeColor(NSColor.white.cgColor)
let start = CGFloat.pi / 2
ctx.addArc(center: center, radius: radius, startAngle: start, endAngle: start - 0.70 * 2 * .pi, clockwise: true); ctx.strokePath()

// Cloud (SF Symbol), white with a light shadow.
let config = NSImage.SymbolConfiguration(pointSize: 300, weight: .bold).applying(.init(paletteColors: [.white]))
let cloud = NSImage(systemSymbolName: "cloud.fill", accessibilityDescription: nil)!.withSymbolConfiguration(config)!
let w: CGFloat = 390
let h = w * cloud.size.height / cloud.size.width
ctx.saveGState()
ctx.setShadow(offset: CGSize(width: 0, height: -6), blur: 14, color: NSColor(srgbRed: 0.55, green: 0.18, blue: 0.02, alpha: 0.35).cgColor)
cloud.draw(in: CGRect(x: center.x - w / 2, y: center.y - h / 2 - 6, width: w, height: h))
ctx.restoreGState()

NSGraphicsContext.restoreGraphicsState()
try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: CommandLine.arguments[1]))
