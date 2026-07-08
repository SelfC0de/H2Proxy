#!/usr/bin/env swift

import Foundation
import CoreGraphics
import CoreText
import ImageIO
import UniformTypeIdentifiers

func createIcon(size: Int) -> CGImage? {
    let w = size
    let h = size
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    guard let ctx = CGContext(
        data: nil, width: w, height: h,
        bitsPerComponent: 8, bytesPerRow: 0,
        space: colorSpace,
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    ) else { return nil }

    let rect = CGRect(x: 0, y: 0, width: w, height: h)

    // Background gradient: deep navy to dark teal
    let gradientColors = [
        CGColor(red: 0.05, green: 0.08, blue: 0.18, alpha: 1.0),
        CGColor(red: 0.02, green: 0.15, blue: 0.25, alpha: 1.0),
        CGColor(red: 0.04, green: 0.22, blue: 0.35, alpha: 1.0)
    ] as CFArray
    let gradientLocations: [CGFloat] = [0.0, 0.5, 1.0]
    if let gradient = CGGradient(colorsSpace: colorSpace, colors: gradientColors, locations: gradientLocations) {
        ctx.drawLinearGradient(gradient,
            start: CGPoint(x: 0, y: CGFloat(h)),
            end: CGPoint(x: CGFloat(w), y: 0),
            options: [])
    }

    // Subtle grid pattern
    ctx.setStrokeColor(CGColor(red: 0.2, green: 0.4, blue: 0.6, alpha: 0.06))
    ctx.setLineWidth(CGFloat(size) / 512.0)
    let gridStep = CGFloat(size) / 16.0
    for i in 0...16 {
        let pos = CGFloat(i) * gridStep
        ctx.move(to: CGPoint(x: pos, y: 0))
        ctx.addLine(to: CGPoint(x: pos, y: CGFloat(h)))
        ctx.move(to: CGPoint(x: 0, y: pos))
        ctx.addLine(to: CGPoint(x: CGFloat(w), y: pos))
    }
    ctx.strokePath()

    // Glowing orb in center
    let cx = CGFloat(w) / 2
    let cy = CGFloat(h) / 2
    let orbRadius = CGFloat(size) * 0.28

    let orbColors = [
        CGColor(red: 0.0, green: 0.7, blue: 0.9, alpha: 0.4),
        CGColor(red: 0.0, green: 0.5, blue: 0.8, alpha: 0.15),
        CGColor(red: 0.0, green: 0.3, blue: 0.6, alpha: 0.0)
    ] as CFArray
    let orbLocations: [CGFloat] = [0.0, 0.5, 1.0]
    if let orbGradient = CGGradient(colorsSpace: colorSpace, colors: orbColors, locations: orbLocations) {
        ctx.drawRadialGradient(orbGradient,
            startCenter: CGPoint(x: cx, y: cy), startRadius: 0,
            endCenter: CGPoint(x: cx, y: cy), endRadius: orbRadius * 1.8,
            options: [])
    }

    // Shield shape
    let s = CGFloat(size)
    let shieldW = s * 0.42
    let shieldH = s * 0.48
    let shieldX = cx - shieldW / 2
    let shieldY = cy - shieldH / 2 - s * 0.02

    let shieldPath = CGMutablePath()
    shieldPath.move(to: CGPoint(x: cx, y: shieldY))
    shieldPath.addLine(to: CGPoint(x: shieldX + shieldW, y: shieldY + shieldH * 0.15))
    shieldPath.addQuadCurve(
        to: CGPoint(x: cx, y: shieldY + shieldH),
        control: CGPoint(x: shieldX + shieldW, y: shieldY + shieldH * 0.7)
    )
    shieldPath.addQuadCurve(
        to: CGPoint(x: shieldX, y: shieldY + shieldH * 0.15),
        control: CGPoint(x: shieldX, y: shieldY + shieldH * 0.7)
    )
    shieldPath.closeSubpath()

    // Shield fill with gradient
    ctx.saveGState()
    ctx.addPath(shieldPath)
    ctx.clip()
    let shieldColors = [
        CGColor(red: 0.0, green: 0.65, blue: 0.95, alpha: 0.85),
        CGColor(red: 0.0, green: 0.45, blue: 0.85, alpha: 0.7),
        CGColor(red: 0.1, green: 0.3, blue: 0.7, alpha: 0.6)
    ] as CFArray
    let shieldLocations: [CGFloat] = [0.0, 0.5, 1.0]
    if let shieldGrad = CGGradient(colorsSpace: colorSpace, colors: shieldColors, locations: shieldLocations) {
        ctx.drawLinearGradient(shieldGrad,
            start: CGPoint(x: cx, y: shieldY),
            end: CGPoint(x: cx, y: shieldY + shieldH),
            options: [])
    }
    ctx.restoreGState()

    // Shield border glow
    ctx.setStrokeColor(CGColor(red: 0.3, green: 0.8, blue: 1.0, alpha: 0.8))
    ctx.setLineWidth(s / 200.0)
    ctx.addPath(shieldPath)
    ctx.strokePath()

    // "H2" text
    let fontSize = s * 0.18
    let fontName = "HelveticaNeue-Bold" as CFString
    guard let font = CTFontCreateWithName(fontName, fontSize, nil) as CTFont? else { return ctx.makeImage() }

    let textAttrs: [NSAttributedString.Key: Any] = [
        .font: font,
        .foregroundColor: CGColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.95)
    ]
    let attrStr = NSAttributedString(string: "H2", attributes: textAttrs)
    let line = CTLineCreateWithAttributedString(attrStr)
    let textBounds = CTLineGetBoundsWithOptions(line, .useOpticalBounds)

    let textX = cx - textBounds.width / 2 - textBounds.origin.x
    let textY = cy - textBounds.height / 2 - textBounds.origin.y - s * 0.02

    ctx.saveGState()
    ctx.textPosition = CGPoint(x: textX, y: textY)
    CTLineDraw(line, ctx)
    ctx.restoreGState()

    // Small "PROXY" subtitle
    let subSize = s * 0.065
    guard let subFont = CTFontCreateWithName("HelveticaNeue-Medium" as CFString, subSize, nil) as CTFont? else { return ctx.makeImage() }
    let subAttrs: [NSAttributedString.Key: Any] = [
        .font: subFont,
        .foregroundColor: CGColor(red: 0.6, green: 0.85, blue: 1.0, alpha: 0.8)
    ]
    let subStr = NSAttributedString(string: "PROXY", attributes: subAttrs)
    let subLine = CTLineCreateWithAttributedString(subStr)
    let subBounds = CTLineGetBoundsWithOptions(subLine, .useOpticalBounds)
    let subX = cx - subBounds.width / 2 - subBounds.origin.x
    let subY = cy - s * 0.15

    ctx.saveGState()
    ctx.textPosition = CGPoint(x: subX, y: subY)
    CTLineDraw(subLine, ctx)
    ctx.restoreGState()

    // Top highlight arc
    ctx.setStrokeColor(CGColor(red: 0.5, green: 0.9, blue: 1.0, alpha: 0.15))
    ctx.setLineWidth(s / 180.0)
    ctx.addArc(center: CGPoint(x: cx, y: cy + s * 0.05), radius: s * 0.35,
               startAngle: .pi * 0.2, endAngle: .pi * 0.8, clockwise: false)
    ctx.strokePath()

    return ctx.makeImage()
}

func savePNG(_ image: CGImage, to path: String) {
    let url = URL(fileURLWithPath: path)
    guard let dest = CGImageDestinationCreateWithURL(url as CFURL, "public.png" as CFString, 1, nil) else {
        print("Failed to create destination for \(path)")
        return
    }
    CGImageDestinationAddImage(dest, image, nil)
    if !CGImageDestinationFinalize(dest) {
        print("Failed to write \(path)")
    }
}

let outputDir = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] :
    "H2Proxy/Sources/Resources/Assets.xcassets/AppIcon.appiconset"

let sizes: [(name: String, pixels: Int)] = [
    ("icon-20", 20),
    ("icon-20@2x", 40),
    ("icon-20@3x", 60),
    ("icon-29", 29),
    ("icon-29@2x", 58),
    ("icon-29@3x", 87),
    ("icon-40", 40),
    ("icon-40@2x", 80),
    ("icon-40@3x", 120),
    ("icon-60@2x", 120),
    ("icon-60@3x", 180),
    ("icon-76", 76),
    ("icon-76@2x", 152),
    ("icon-83.5@2x", 167),
    ("icon-1024", 1024)
]

for entry in sizes {
    if let image = createIcon(size: entry.pixels) {
        let path = "\(outputDir)/\(entry.name).png"
        savePNG(image, to: path)
        print("Generated \(entry.name).png (\(entry.pixels)x\(entry.pixels))")
    }
}
print("Done! Generated \(sizes.count) icons.")
