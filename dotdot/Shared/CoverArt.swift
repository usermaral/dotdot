//
//  CoverArt.swift
//  dotdot
//
//  Created by Maral on 18.11.2026.
//

import AVFoundation
import CoreGraphics
import UIKit

/// Source image for the art-driven skins (Cobalt halftone, ASCII Print), as a square
/// luminance grid (0...1, row-major, top row first): the track's embedded cover,
/// or the dotdot mascot when there is none.
nonisolated enum CoverArt {
    static let resolution = 80

    /// Original fallback character: a round "dot" face. Drawn once.
    static let mascot: [Float] = drawGrid { ctx, n in
        let s = CGFloat(n)
        // CG space is y-up here.
        ctx.setFillColor(gray: 0, alpha: 1)
        ctx.fill(CGRect(x: 0, y: 0, width: s, height: s))

        ctx.setFillColor(gray: 1, alpha: 1)
        ctx.fillEllipse(in: CGRect(x: s * 0.14, y: s * 0.10, width: s * 0.72, height: s * 0.72)) // head
        ctx.fillEllipse(in: CGRect(x: s * 0.20, y: s * 0.70, width: s * 0.16, height: s * 0.20)) // ear
        ctx.fillEllipse(in: CGRect(x: s * 0.64, y: s * 0.70, width: s * 0.16, height: s * 0.20)) // ear

        ctx.setFillColor(gray: 0, alpha: 1)
        ctx.fillEllipse(in: CGRect(x: s * 0.33, y: s * 0.48, width: s * 0.09, height: s * 0.12)) // eyes
        ctx.fillEllipse(in: CGRect(x: s * 0.58, y: s * 0.48, width: s * 0.09, height: s * 0.12))
        ctx.setFillColor(gray: 1, alpha: 1)
        ctx.fillEllipse(in: CGRect(x: s * 0.355, y: s * 0.55, width: s * 0.03, height: s * 0.03)) // eye shine
        ctx.fillEllipse(in: CGRect(x: s * 0.605, y: s * 0.55, width: s * 0.03, height: s * 0.03))

        ctx.setFillColor(gray: 0.55, alpha: 1)
        ctx.fillEllipse(in: CGRect(x: s * 0.24, y: s * 0.38, width: s * 0.10, height: s * 0.06)) // blush
        ctx.fillEllipse(in: CGRect(x: s * 0.66, y: s * 0.38, width: s * 0.10, height: s * 0.06))

        ctx.setStrokeColor(gray: 0, alpha: 1)
        ctx.setLineWidth(s * 0.035)
        ctx.setLineCap(.round)
        ctx.addArc(center: CGPoint(x: s * 0.5, y: s * 0.42), radius: s * 0.08,
                   startAngle: .pi * 1.15, endAngle: .pi * 1.85, clockwise: false) // smile
        ctx.strokePath()

        ctx.setFillColor(gray: 0.8, alpha: 1)
        for (x, y) in [(0.08, 0.86), (0.88, 0.16), (0.90, 0.80), (0.06, 0.24)] { // sparkles
            ctx.fillEllipse(in: CGRect(x: s * x, y: s * y, width: s * 0.04, height: s * 0.04))
        }
    }

    /// Embedded cover art of the file, or nil if it has none.
    static func coverLuminance(for url: URL) async -> [Float]? {
        let asset = AVURLAsset(url: url)
        guard let items = try? await asset.load(.commonMetadata) else { return nil }
        for item in AVMetadataItem.metadataItems(from: items, filteredByIdentifier: .commonIdentifierArtwork) {
            guard let data = try? await item.load(.dataValue),
                  let image = UIImage(data: data)?.cgImage else { continue }
            return luminance(of: image)
        }
        return nil
    }

    /// Luminance at a normalized position (0...1, 0...1 from the top-left).
    static func sample(_ grid: [Float], _ u: Double, _ v: Double) -> Double {
        let n = resolution
        let x = min(max(Int(u * Double(n)), 0), n - 1)
        let y = min(max(Int(v * Double(n)), 0), n - 1)
        return Double(grid[y * n + x])
    }

    /// Cheap deterministic per-cell noise for sparkles and glitches.
    static func hash(_ x: Int, _ y: Int, _ z: Int) -> Int {
        abs((x &* 73_856_093) ^ (y &* 19_349_663) ^ (z &* 83_492_791))
    }

    /// Aspect-fill crop to a square, downsample, stretch contrast.
    private static func luminance(of image: CGImage) -> [Float] {
        var grid = drawGrid { ctx, n in
            let w = CGFloat(image.width), h = CGFloat(image.height)
            let scale = CGFloat(n) / min(w, h)
            ctx.interpolationQuality = .medium
            ctx.draw(image, in: CGRect(x: (CGFloat(n) - w * scale) / 2, y: (CGFloat(n) - h * scale) / 2,
                                       width: w * scale, height: h * scale))
        }
        stretchContrast(&grid)
        return grid
    }

    private static func drawGrid(_ draw: (CGContext, Int) -> Void) -> [Float] {
        let n = resolution
        var pixels = [UInt8](repeating: 0, count: n * n)
        pixels.withUnsafeMutableBytes { buffer in
            guard let ctx = CGContext(data: buffer.baseAddress, width: n, height: n, bitsPerComponent: 8,
                                      bytesPerRow: n, space: CGColorSpaceCreateDeviceGray(),
                                      bitmapInfo: CGImageAlphaInfo.none.rawValue) else { return }
            draw(ctx, n)
        }
        return pixels.map { Float($0) / 255 }
    }

    /// Covers are often low-contrast; map the 3rd...97th percentile to 0...1.
    private static func stretchContrast(_ values: inout [Float]) {
        let sorted = values.sorted()
        let low = sorted[sorted.count * 3 / 100], high = sorted[sorted.count * 97 / 100]
        guard high - low > 0.05 else { return }
        for i in values.indices {
            values[i] = min(max((values[i] - low) / (high - low), 0), 1)
        }
    }
}
