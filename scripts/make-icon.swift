// Gera Resources/AppIcon.icns. Uso: swift scripts/make-icon.swift
import AppKit

func render(_ size: Int) -> Data {
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil, pixelsWide: size, pixelsHigh: size, bitsPerSample: 8,
        samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB,
        bytesPerRow: 0, bitsPerPixel: 0)!
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    let s = CGFloat(size) / 1024
    func r(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat) -> NSRect {
        NSRect(x: x * s, y: y * s, width: w * s, height: h * s)
    }
    let body = NSBezierPath(roundedRect: r(100, 100, 824, 824), xRadius: 185 * s, yRadius: 185 * s)
    NSGradient(starting: NSColor(calibratedRed: 0.36, green: 0.62, blue: 0.98, alpha: 1),
               ending: NSColor(calibratedRed: 0.11, green: 0.27, blue: 0.70, alpha: 1))!
        .draw(in: body, angle: -90)
    NSColor(white: 1, alpha: 0.28).setFill()
    NSBezierPath(roundedRect: r(170, 290, 684, 300), xRadius: 70 * s, yRadius: 70 * s).fill()
    NSColor.white.setFill()
    NSBezierPath(roundedRect: r(225, 345, 190, 190), xRadius: 44 * s, yRadius: 44 * s).fill()
    NSBezierPath(roundedRect: r(609, 345, 190, 190), xRadius: 44 * s, yRadius: 44 * s).fill()
    NSBezierPath(roundedRect: r(498, 325, 28, 230), xRadius: 14 * s, yRadius: 14 * s).fill()
    NSGraphicsContext.current = nil
    return rep.representation(using: .png, properties: [:])!
}

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let iconset = FileManager.default.temporaryDirectory.appendingPathComponent("AppIcon.iconset")
try? FileManager.default.removeItem(at: iconset)
try FileManager.default.createDirectory(at: iconset, withIntermediateDirectories: true)
for base in [16, 32, 128, 256, 512] {
    try render(base).write(to: iconset.appendingPathComponent("icon_\(base)x\(base).png"))
    try render(base * 2).write(to: iconset.appendingPathComponent("icon_\(base)x\(base)@2x.png"))
}
let tool = Process()
tool.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
tool.arguments = ["-c", "icns", iconset.path, "-o", root.appendingPathComponent("Resources/AppIcon.icns").path]
try tool.run()
tool.waitUntilExit()
exit(tool.terminationStatus)
