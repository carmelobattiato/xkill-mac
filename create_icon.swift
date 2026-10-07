#!/usr/bin/swift
import AppKit

guard let sourceImage = NSImage(contentsOfFile: "Assets/skull_active.png") else {
    print("Cannot load Assets/skull_active.png"); exit(1)
}

// Find tight bounding box of non-transparent pixels
func contentRect(of image: NSImage) -> CGRect {
    guard let rep = NSBitmapImageRep(data: image.tiffRepresentation!) else { return .zero }
    let w = rep.pixelsWide, h = rep.pixelsHigh
    var minX = w, maxX = 0, minY = h, maxY = 0
    for y in 0..<h {
        for x in 0..<w {
            if (rep.colorAt(x: x, y: y)?.alphaComponent ?? 0) > 0.02 {
                if x < minX { minX = x }; if x > maxX { maxX = x }
                if y < minY { minY = y }; if y > maxY { maxY = y }
            }
        }
    }
    guard minX <= maxX, minY <= maxY else { return CGRect(origin: .zero, size: image.size) }
    // Convert pixel coords to NSImage logical coords (NSImage uses bottom-left origin)
    let scaleX = image.size.width  / CGFloat(w)
    let scaleY = image.size.height / CGFloat(h)
    return CGRect(x: CGFloat(minX) * scaleX,
                  y: CGFloat(minY) * scaleY,
                  width:  CGFloat(maxX - minX + 1) * scaleX,
                  height: CGFloat(maxY - minY + 1) * scaleY)
}

print("Computing skull bounds...")
let bounds = contentRect(of: sourceImage)
print("Content rect: \(bounds)")

func makeIcon(size: Int) -> NSImage {
    let s = CGFloat(size)
    let padding = s * 0.05          // 5% padding on each side
    let dest = CGRect(x: padding, y: padding,
                      width: s - padding * 2, height: s - padding * 2)
    let out = NSImage(size: NSSize(width: s, height: s))
    out.lockFocus()
    sourceImage.draw(in: dest, from: bounds, operation: .sourceOver, fraction: 1)
    out.unlockFocus()
    return out
}

func savePNG(_ image: NSImage, to path: String) {
    guard let tiff = image.tiffRepresentation,
          let rep  = NSBitmapImageRep(data: tiff),
          let png  = rep.representation(using: .png, properties: [:]) else {
        print("Failed to create PNG for \(path)"); exit(1)
    }
    do { try png.write(to: URL(fileURLWithPath: path)) }
    catch { print("Failed to write \(path): \(error)"); exit(1) }
}

let iconsetPath = "AppIcon.iconset"
try? FileManager.default.createDirectory(atPath: iconsetPath, withIntermediateDirectories: true)

let sizes = [
    (16,   "icon_16x16.png"),
    (32,   "icon_16x16@2x.png"),
    (32,   "icon_32x32.png"),
    (64,   "icon_32x32@2x.png"),
    (128,  "icon_128x128.png"),
    (256,  "icon_128x128@2x.png"),
    (256,  "icon_256x256.png"),
    (512,  "icon_256x256@2x.png"),
    (512,  "icon_512x512.png"),
    (1024, "icon_512x512@2x.png"),
]

for (size, name) in sizes {
    savePNG(makeIcon(size: size), to: "\(iconsetPath)/\(name)")
    print("Generated \(name)")
}

print("Running iconutil...")
let task = Process()
task.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
task.arguments = ["-c", "icns", iconsetPath, "-o", "AppIcon.icns"]
try! task.run()
task.waitUntilExit()

if task.terminationStatus == 0 {
    print("Created AppIcon.icns")
    try? FileManager.default.removeItem(atPath: iconsetPath)
} else {
    print("iconutil failed"); exit(1)
}
