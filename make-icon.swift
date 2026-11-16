import AppKit
let target = CommandLine.arguments[1]
try FileManager.default.createDirectory(atPath: target, withIntermediateDirectories: true)
for size in [16, 32, 64, 128, 256, 512, 1024] {
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: size, pixelsHigh: size,
        bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
        colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    let scale = CGFloat(size) / 1024
    let transform = AffineTransform(scale: scale); (transform as NSAffineTransform).concat()
    let background = NSBezierPath(roundedRect: NSRect(x: 60, y: 60, width: 904, height: 904), xRadius: 205, yRadius: 205)
    NSGradient(starting: NSColor(calibratedRed: 0.12, green: 0.64, blue: 0.84, alpha: 1),
        ending: NSColor(calibratedRed: 0.08, green: 0.31, blue: 0.67, alpha: 1))!.draw(in: background, angle: -90)
    NSColor.white.setStroke()
    let port = NSBezierPath()
    port.move(to: NSPoint(x: 280, y: 735)); port.line(to: NSPoint(x: 744, y: 735))
    port.line(to: NSPoint(x: 744, y: 380)); port.line(to: NSPoint(x: 630, y: 380))
    port.line(to: NSPoint(x: 630, y: 285)); port.line(to: NSPoint(x: 394, y: 285))
    port.line(to: NSPoint(x: 394, y: 380)); port.line(to: NSPoint(x: 280, y: 380)); port.close()
    port.lineWidth = 36; port.lineJoinStyle = .round; port.stroke()
    for x in stride(from: 360.0, through: 660.0, by: 60.0) {
        let pin = NSBezierPath(); pin.move(to: NSPoint(x: x, y: 630)); pin.line(to: NSPoint(x: x, y: 720))
        pin.lineWidth = 26; pin.lineCapStyle = .round; pin.stroke()
    }
    NSColor.white.setFill(); NSBezierPath(ovalIn: NSRect(x: 476, y: 430, width: 72, height: 72)).fill()
    NSGraphicsContext.restoreGraphicsState()
    let data = rep.representation(using: .png, properties: [:])!
    if size <= 512 { try data.write(to: URL(fileURLWithPath: target + "/icon_\(size)x\(size).png")) }
    if size >= 32 { try data.write(to: URL(fileURLWithPath: target + "/icon_\(size/2)x\(size/2)@2x.png")) }
}
