#!/usr/bin/env swift

import Foundation
import AppKit
import CoreGraphics

func createStillMarkerIcon(size: CGFloat) -> NSImage? {
    let image = NSImage(size: NSSize(width: size, height: size))

    image.lockFocus()

    // Clear the entire canvas to transparent
    NSColor.clear.setFill()
    NSRect(x: 0, y: 0, width: size, height: size).fill()

    // Natural warm white background with rounded corners (Japanese paper aesthetic)
    let cornerRadius = size * 0.225 // macOS Big Sur style rounded corners
    let backgroundPath = NSBezierPath(roundedRect: NSRect(x: 0, y: 0, width: size, height: size),
                                      xRadius: cornerRadius, yRadius: cornerRadius)
    NSColor(red: 0xFE/255.0, green: 0xF9/255.0, blue: 0xF0/255.0, alpha: 1.0).setFill()
    backgroundPath.fill()

    // Clip to rounded corners for everything that follows
    backgroundPath.addClip()

    // Light grey-blue color for graph paper lines
    let graphColor = NSColor(red: 0xD8/255.0, green: 0xE0/255.0, blue: 0xE8/255.0, alpha: 1.0)
    graphColor.setStroke()

    // Draw graph paper grid - extreme close-up with hand-drawn texture
    let gridSpacing = size / 3.0 // 3x3 grid (very close-up view)
    let baseLineWidth = size * 0.006

    // Vertical lines with imperfections
    for i in 1..<3 {
        let x = gridSpacing * CGFloat(i)
        let path = NSBezierPath()

        // Draw line in segments with varying thickness for hand-drawn look
        var currentY: CGFloat = 0
        let segments = 12
        let segmentHeight = size / CGFloat(segments)

        for seg in 0..<segments {
            let segY = currentY
            let nextY = currentY + segmentHeight

            // Vary thickness slightly (±15%)
            let thicknessVariation = CGFloat.random(in: 0.85...1.15)
            let segmentWidth = baseLineWidth * thicknessVariation

            // Slight horizontal wiggle for imperfection
            let xOffset = CGFloat.random(in: -size * 0.0005...size * 0.0005)

            let segPath = NSBezierPath()
            segPath.move(to: NSPoint(x: x + xOffset, y: segY))
            segPath.line(to: NSPoint(x: x + xOffset, y: nextY))
            segPath.lineWidth = segmentWidth
            segPath.stroke()

            currentY = nextY
        }
    }

    // Horizontal lines with imperfections
    for i in 1..<3 {
        let y = gridSpacing * CGFloat(i)

        var currentX: CGFloat = 0
        let segments = 12
        let segmentWidth = size / CGFloat(segments)

        for seg in 0..<segments {
            let segX = currentX
            let nextX = currentX + segmentWidth

            // Vary thickness slightly
            let thicknessVariation = CGFloat.random(in: 0.85...1.15)
            let segmentHeight = baseLineWidth * thicknessVariation

            // Slight vertical wiggle
            let yOffset = CGFloat.random(in: -size * 0.0005...size * 0.0005)

            let segPath = NSBezierPath()
            segPath.move(to: NSPoint(x: segX, y: y + yOffset))
            segPath.line(to: NSPoint(x: nextX, y: y + yOffset))
            segPath.lineWidth = segmentHeight
            segPath.stroke()

            currentX = nextX
        }
    }

    // Large "SM" text - extremely condensed and tall with non-traditional spacing
    let smFontSize = size * 0.70 // Larger to fill more vertical space
    // Try ultra-condensed fonts first for tall, narrow letters
    let smFont = NSFont(name: "Impact", size: smFontSize)
              ?? NSFont(name: "HelveticaNeue-CondensedBlack", size: smFontSize)
              ?? NSFont(name: "HelveticaNeue-CondensedBold", size: smFontSize)
              ?? NSFont(name: "Futura-CondensedExtraBold", size: smFontSize)
              ?? NSFont.systemFont(ofSize: smFontSize, weight: .heavy)

    // Soft charcoal color instead of harsh black
    let charcoalColor = NSColor(red: 0x2D/255.0, green: 0x31/255.0, blue: 0x35/255.0, alpha: 1.0)

    // Draw S and M separately with wide horizontal spacing
    let sAttrs: [NSAttributedString.Key: Any] = [
        .font: smFont,
        .foregroundColor: charcoalColor,
        .expansion: -0.5
    ]
    let mAttrs: [NSAttributedString.Key: Any] = [
        .font: smFont,
        .foregroundColor: charcoalColor,
        .expansion: -0.5
    ]

    let sSize = "S".size(withAttributes: sAttrs)
    let mSize = "M".size(withAttributes: mAttrs)

    // Non-traditional positioning - wide horizontal spacing like | S   M |
    let spacing = size * 0.25 // Wide gap between letters
    let totalWidth = sSize.width + spacing + mSize.width
    let sX = (size - totalWidth) / 2
    let mX = sX + sSize.width + spacing
    let centerY = (size - sSize.height) / 2 // Vertically centered

    "S".draw(at: NSPoint(x: sX, y: centerY), withAttributes: sAttrs)
    "M".draw(at: NSPoint(x: mX, y: centerY), withAttributes: mAttrs)

    // Scrapbook elements - add before the loupe for layering

    // Washi tape piece in top-right corner (translucent, pastel)
    let tapeWidth = size * 0.12
    let tapeHeight = size * 0.06
    let tapeRect = NSRect(x: size * 0.80, y: size * 0.88, width: tapeWidth, height: tapeHeight)
    let tapePath = NSBezierPath(rect: tapeRect)
    NSColor(red: 0xE8/255.0, green: 0xD5/255.0, blue: 0xC4/255.0, alpha: 0.6).setFill()
    tapePath.fill()
    // Tape edge detail
    NSColor(red: 0xD0/255.0, green: 0xBD/255.0, blue: 0xAC/255.0, alpha: 0.3).setStroke()
    tapePath.lineWidth = size * 0.001
    tapePath.stroke()

    // Paper clip in top-left corner (simple wire aesthetic)
    let clipPath = NSBezierPath()
    let clipX = size * 0.12
    let clipY = size * 0.85
    let clipSize = size * 0.08
    // Simple paperclip shape
    clipPath.move(to: NSPoint(x: clipX, y: clipY))
    clipPath.line(to: NSPoint(x: clipX + clipSize * 0.3, y: clipY))
    clipPath.curve(to: NSPoint(x: clipX + clipSize * 0.3, y: clipY + clipSize * 0.4),
                   controlPoint1: NSPoint(x: clipX + clipSize * 0.5, y: clipY),
                   controlPoint2: NSPoint(x: clipX + clipSize * 0.5, y: clipY + clipSize * 0.4))
    clipPath.line(to: NSPoint(x: clipX + clipSize * 0.1, y: clipY + clipSize * 0.4))
    NSColor(red: 0xA8/255.0, green: 0xAC/255.0, blue: 0xB0/255.0, alpha: 0.7).setStroke()
    clipPath.lineWidth = size * 0.004
    clipPath.stroke()

    // Glassmorphic loupe lens - positioned as completely separate element with no overlap
    let loupeRadius = size * 0.15
    // Position in bottom center/right, in the open space away from both S and M
    let loupeCenter = NSPoint(x: size * 0.50, y: size * 0.20)

    // Multiple shadow/blur layers for enhanced depth and blur effect
    let shadowCircle1 = NSBezierPath()
    shadowCircle1.appendArc(withCenter: NSPoint(x: loupeCenter.x + size * 0.012,
                                                y: loupeCenter.y - size * 0.012),
                           radius: loupeRadius,
                           startAngle: 0, endAngle: 360)
    NSColor(red: 0x2A/255.0, green: 0x2D/255.0, blue: 0x34/255.0, alpha: 0.20).setFill()
    shadowCircle1.fill()

    // Second blur layer for more depth
    let shadowCircle2 = NSBezierPath()
    shadowCircle2.appendArc(withCenter: NSPoint(x: loupeCenter.x + size * 0.008,
                                                y: loupeCenter.y - size * 0.008),
                           radius: loupeRadius,
                           startAngle: 0, endAngle: 360)
    NSColor(red: 0x2A/255.0, green: 0x2D/255.0, blue: 0x34/255.0, alpha: 0.15).setFill()
    shadowCircle2.fill()

    // Outer blur ring for glassmorphic effect
    let blurRing = NSBezierPath()
    blurRing.appendArc(withCenter: NSPoint(x: loupeCenter.x + size * 0.006,
                                           y: loupeCenter.y - size * 0.006),
                      radius: loupeRadius + size * 0.015,
                      startAngle: 0, endAngle: 360)
    NSColor(red: 0x2A/255.0, green: 0x2D/255.0, blue: 0x34/255.0, alpha: 0.12).setFill()
    blurRing.fill()

    // Loupe glass circle with 3D gradient (glassmorphic effect)
    let loupeCircle = NSBezierPath()
    loupeCircle.appendArc(withCenter: loupeCenter, radius: loupeRadius,
                          startAngle: 0, endAngle: 360)

    // 3D glass gradient with enhanced blur effect (more frosted/blurred)
    let glassGradient = NSGradient(colors: [
        NSColor(white: 0.98, alpha: 0.65),
        NSColor(white: 0.92, alpha: 0.58),
        NSColor(white: 0.88, alpha: 0.52)
    ])
    glassGradient?.draw(in: loupeCircle, angle: 135)

    // Chromatic aberration effect (RGB color fringing around edge)
    // Red fringe
    let redAberration = NSBezierPath()
    redAberration.appendArc(withCenter: NSPoint(x: loupeCenter.x - size * 0.002, y: loupeCenter.y),
                           radius: loupeRadius - size * 0.008,
                           startAngle: 45, endAngle: 135)
    NSColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 0.08).setStroke()
    redAberration.lineWidth = size * 0.012
    redAberration.stroke()

    // Blue fringe (opposite side)
    let blueAberration = NSBezierPath()
    blueAberration.appendArc(withCenter: NSPoint(x: loupeCenter.x + size * 0.002, y: loupeCenter.y),
                            radius: loupeRadius - size * 0.008,
                            startAngle: 225, endAngle: 315)
    NSColor(red: 0.0, green: 0.4, blue: 1.0, alpha: 0.08).setStroke()
    blueAberration.lineWidth = size * 0.012
    blueAberration.stroke()

    // Loupe rim (charcoal with subtle depth)
    let rimColor = NSColor(red: 0x2A/255.0, green: 0x2D/255.0, blue: 0x34/255.0, alpha: 0.9)
    rimColor.setStroke()
    loupeCircle.lineWidth = size * 0.024
    loupeCircle.stroke()

    // Outer glow (3D glass effect)
    let outerGlow = NSBezierPath()
    outerGlow.appendArc(withCenter: loupeCenter, radius: loupeRadius + size * 0.014,
                       startAngle: 0, endAngle: 360)
    NSColor(white: 1.0, alpha: 0.25).setStroke()
    outerGlow.lineWidth = size * 0.008
    outerGlow.stroke()

    // Top-left highlight arc (3D glass edge)
    let topHighlight = NSBezierPath()
    topHighlight.appendArc(withCenter: loupeCenter, radius: loupeRadius - size * 0.018,
                          startAngle: 45, endAngle: 225)
    NSColor(white: 1.0, alpha: 0.7).setStroke()
    topHighlight.lineWidth = size * 0.008
    topHighlight.stroke()

    // Bottom-right shadow arc (3D depth)
    let bottomShadow = NSBezierPath()
    bottomShadow.appendArc(withCenter: loupeCenter, radius: loupeRadius - size * 0.018,
                          startAngle: 225, endAngle: 45)
    NSColor(red: 0x2A/255.0, green: 0x2D/255.0, blue: 0x34/255.0, alpha: 0.15).setStroke()
    bottomShadow.lineWidth = size * 0.008
    bottomShadow.stroke()

    // Primary glint with blur effect (frosted glass look)
    let glint1 = NSBezierPath()
    let glintCenter1 = NSPoint(x: loupeCenter.x - loupeRadius * 0.35,
                              y: loupeCenter.y + loupeRadius * 0.35)
    glint1.appendArc(withCenter: glintCenter1, radius: loupeRadius * 0.22,
                    startAngle: 0, endAngle: 360)
    NSColor(white: 1.0, alpha: 0.45).setFill()
    glint1.fill()

    // Secondary blur/glint layer for depth
    let glint1b = NSBezierPath()
    glint1b.appendArc(withCenter: glintCenter1, radius: loupeRadius * 0.28,
                     startAngle: 0, endAngle: 360)
    NSColor(white: 1.0, alpha: 0.15).setFill()
    glint1b.fill()

    // Smaller glint for realism
    let glint2 = NSBezierPath()
    let glintCenter2 = NSPoint(x: loupeCenter.x + loupeRadius * 0.30,
                              y: loupeCenter.y - loupeRadius * 0.35)
    glint2.appendArc(withCenter: glintCenter2, radius: loupeRadius * 0.10,
                    startAngle: 0, endAngle: 360)
    NSColor(white: 1.0, alpha: 0.35).setFill()
    glint2.fill()

    image.unlockFocus()

    return image
}

func saveIconAsset(image: NSImage, size: Int, path: String) {
    // Create bitmap with alpha channel to preserve transparency
    guard let tiffData = image.tiffRepresentation,
          let bitmap = NSBitmapImageRep(data: tiffData) else {
        print("❌ Failed to create bitmap from image")
        return
    }

    // Ensure alpha channel is preserved in PNG
    guard let pngData = bitmap.representation(using: .png, properties: [.compressionFactor: 1.0]) else {
        print("❌ Failed to convert image to PNG")
        return
    }

    try? pngData.write(to: URL(fileURLWithPath: path))
    print("✅ Created \(size)x\(size) icon")
}

// Main execution
print("🎨 Creating custom Still Marker icon...")

let iconDir = "Still Marker/Assets.xcassets/AppIcon.appiconset"
let sizes = [16, 32, 128, 256, 512, 1024]

// Create only single-size icons (no @2x retina versions)
for size in sizes {
    if let icon = createStillMarkerIcon(size: CGFloat(size)) {
        saveIconAsset(image: icon, size: size, path: "\(iconDir)/icon_\(size)x\(size).png")
    }
}

print("✅ Icon generation complete!")
print("📐 macOS-style rounded icon with warm paper background, graph grid, and glassmorphic loupe")
print("📝 Generated single-size icons only (no @2x versions)")
