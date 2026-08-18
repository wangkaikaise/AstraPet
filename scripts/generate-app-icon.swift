#!/usr/bin/env swift

import AppKit

guard CommandLine.arguments.count == 2 else {
    fputs("Usage: generate-app-icon.swift OUTPUT.png\n", stderr)
    exit(2)
}

let canvasSize = NSSize(width: 1024, height: 1024)
let image = NSImage(size: canvasSize, flipped: false) { _ in
    NSGraphicsContext.saveGraphicsState()
    defer { NSGraphicsContext.restoreGraphicsState() }

    // A quiet, neutral macOS tile replaces the previous saturated blue field.
    let tile = NSBezierPath(
        roundedRect: NSRect(x: 54, y: 54, width: 916, height: 916),
        xRadius: 214,
        yRadius: 214
    )
    NSColor(calibratedRed: 0.945, green: 0.948, blue: 0.946, alpha: 1).setFill()
    tile.fill()

    let tileBorder = NSBezierPath(
        roundedRect: NSRect(x: 57, y: 57, width: 910, height: 910),
        xRadius: 211,
        yRadius: 211
    )
    tileBorder.lineWidth = 6
    NSColor(calibratedWhite: 0.82, alpha: 0.54).setStroke()
    tileBorder.stroke()

    // Eva is represented only by her head: white shell, black visor, blue eyes.
    let shellShadow = NSShadow()
    shellShadow.shadowColor = NSColor.black.withAlphaComponent(0.16)
    shellShadow.shadowBlurRadius = 34
    shellShadow.shadowOffset = NSSize(width: 0, height: -18)
    shellShadow.set()

    let shell = NSBezierPath(
        roundedRect: NSRect(x: 112, y: 208, width: 800, height: 608),
        xRadius: 304,
        yRadius: 304
    )
    NSColor.white.setFill()
    shell.fill()

    NSGraphicsContext.restoreGraphicsState()
    NSGraphicsContext.saveGraphicsState()

    shell.lineWidth = 12
    NSColor(calibratedWhite: 0.78, alpha: 0.72).setStroke()
    shell.stroke()

    let visor = NSBezierPath(
        roundedRect: NSRect(x: 184, y: 302, width: 656, height: 404),
        xRadius: 202,
        yRadius: 202
    )
    NSColor(calibratedRed: 0.035, green: 0.043, blue: 0.052, alpha: 1).setFill()
    visor.fill()

    // Restrained highlights keep the visor legible without returning to a blue icon.
    let visorHighlight = NSBezierPath()
    visorHighlight.move(to: NSPoint(x: 282, y: 620))
    visorHighlight.curve(
        to: NSPoint(x: 474, y: 672),
        controlPoint1: NSPoint(x: 330, y: 660),
        controlPoint2: NSPoint(x: 412, y: 680)
    )
    visorHighlight.lineWidth = 15
    visorHighlight.lineCapStyle = .round
    NSColor.white.withAlphaComponent(0.16).setStroke()
    visorHighlight.stroke()

    let eyeColor = NSColor(calibratedRed: 0.16, green: 0.72, blue: 0.92, alpha: 1)
    for centerX in [360.0, 664.0] {
        let eye = NSBezierPath()
        eye.move(to: NSPoint(x: centerX - 82, y: 472))
        eye.curve(
            to: NSPoint(x: centerX + 82, y: 472),
            controlPoint1: NSPoint(x: centerX - 54, y: 558),
            controlPoint2: NSPoint(x: centerX + 54, y: 558)
        )
        eye.lineWidth = 38
        eye.lineCapStyle = .round

        let glow = NSShadow()
        glow.shadowColor = eyeColor.withAlphaComponent(0.52)
        glow.shadowBlurRadius = 24
        glow.shadowOffset = .zero
        glow.set()
        eyeColor.setStroke()
        eye.stroke()
    }

    return true
}

guard
    let tiff = image.tiffRepresentation,
    let bitmap = NSBitmapImageRep(data: tiff),
    let png = bitmap.representation(using: .png, properties: [:])
else {
    fputs("Unable to render app icon\n", stderr)
    exit(1)
}

do {
    try png.write(to: URL(fileURLWithPath: CommandLine.arguments[1]), options: .atomic)
} catch {
    fputs("Unable to write app icon: \(error)\n", stderr)
    exit(1)
}
