#!/usr/bin/env swift

import AppKit
import Foundation

func createIcon(size: Int) -> NSImage {
    let image = NSImage(size: NSSize(width: size, height: size))
    image.lockFocus()

    let s = CGFloat(size)
    let margin = s * 0.05
    let contentSize = s - 2 * margin
    let gap = s * 0.025
    let outerRadius = contentSize * 0.22
    let innerRadius = contentSize * 0.09

    // Background rounded rect
    let bgRect = NSRect(x: margin, y: margin, width: contentSize, height: contentSize)
    let bgPath = NSBezierPath(roundedRect: bgRect, xRadius: outerRadius, yRadius: outerRadius)

    // Subtle gradient background
    let gradient = NSGradient(
        starting: NSColor(white: 0.97, alpha: 1.0),
        ending: NSColor(white: 0.92, alpha: 1.0)
    )
    gradient?.draw(in: bgPath, angle: -90)

    // Light border
    NSColor(white: 0.86, alpha: 0.5).setStroke()
    bgPath.lineWidth = s * 0.004
    bgPath.stroke()

    // Calculate quadrant positions
    let innerPadding = contentSize * 0.085
    let qx = margin + innerPadding
    let qy = margin + innerPadding
    let availableW = contentSize - 2 * innerPadding
    let availableH = contentSize - 2 * innerPadding
    let quadW = (availableW - gap) / 2
    let quadH = (availableH - gap) / 2

    // Quadrant definitions (AppKit: origin at bottom-left)
    // Visual layout: Red(TL) Blue(TR) / Amber(BL) Gray(BR)
    let quadrants: [(NSRect, NSColor, NSColor)] = [
        // Top-left = Q1 (coral red) - in AppKit at top means higher y
        (NSRect(x: qx, y: qy + quadH + gap, width: quadW, height: quadH),
         NSColor(calibratedRed: 0.90, green: 0.32, blue: 0.32, alpha: 1.0),
         NSColor(calibratedRed: 0.82, green: 0.24, blue: 0.24, alpha: 1.0)),
        // Top-right = Q2 (blue)
        (NSRect(x: qx + quadW + gap, y: qy + quadH + gap, width: quadW, height: quadH),
         NSColor(calibratedRed: 0.26, green: 0.58, blue: 0.92, alpha: 1.0),
         NSColor(calibratedRed: 0.18, green: 0.48, blue: 0.84, alpha: 1.0)),
        // Bottom-left = Q3 (amber)
        (NSRect(x: qx, y: qy, width: quadW, height: quadH),
         NSColor(calibratedRed: 0.94, green: 0.72, blue: 0.24, alpha: 1.0),
         NSColor(calibratedRed: 0.86, green: 0.62, blue: 0.16, alpha: 1.0)),
        // Bottom-right = Q4 (gray)
        (NSRect(x: qx + quadW + gap, y: qy, width: quadW, height: quadH),
         NSColor(calibratedRed: 0.58, green: 0.58, blue: 0.63, alpha: 1.0),
         NSColor(calibratedRed: 0.48, green: 0.48, blue: 0.53, alpha: 1.0)),
    ]

    for (rect, startColor, endColor) in quadrants {
        let path = NSBezierPath(roundedRect: rect, xRadius: innerRadius, yRadius: innerRadius)
        let grad = NSGradient(starting: startColor, ending: endColor)
        grad?.draw(in: path, angle: -90)
    }

    image.unlockFocus()
    return image
}

func savePNG(_ image: NSImage, size: Int, to path: String) {
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: size,
        pixelsHigh: size,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    )!
    rep.size = NSSize(width: size, height: size)

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    image.draw(
        in: NSRect(x: 0, y: 0, width: size, height: size),
        from: NSRect(x: 0, y: 0, width: image.size.width, height: image.size.height),
        operation: .copy, fraction: 1.0
    )
    NSGraphicsContext.restoreGraphicsState()

    let data = rep.representation(using: .png, properties: [:])!
    try! data.write(to: URL(fileURLWithPath: path))
}

// --- Generate iconset ---
let iconsetDir = "AppIcon.iconset"
try? FileManager.default.removeItem(atPath: iconsetDir)
try! FileManager.default.createDirectory(atPath: iconsetDir, withIntermediateDirectories: true)

let entries: [(String, Int)] = [
    ("icon_16x16", 16), ("icon_16x16@2x", 32),
    ("icon_32x32", 32), ("icon_32x32@2x", 64),
    ("icon_128x128", 128), ("icon_128x128@2x", 256),
    ("icon_256x256", 256), ("icon_256x256@2x", 512),
    ("icon_512x512", 512), ("icon_512x512@2x", 1024),
]

for (name, size) in entries {
    let image = createIcon(size: size)
    savePNG(image, size: size, to: "\(iconsetDir)/\(name).png")
}

print("Icon set generated at \(iconsetDir)/")
