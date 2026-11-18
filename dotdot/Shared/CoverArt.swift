//
//  CoverArt.swift
//  dotdot
//
//  Created by Maral on 18.11.2026.
//

import AVFoundation
import CoreGraphics
import UIKit

/// Source image for ASCII Print, as a square luminance grid (0...1, row-major, top row
/// first): the track's embedded cover, or a procedural vinyl record when there is none.
nonisolated enum CoverArt {
    static let resolution = 80

    /// Fallback when a track has no cover: a vinyl record, drawn procedurally so it stays
    /// sharp at any size and can spin. `spin` (radians) turns the label; the sheen stays put,
    /// like light on a real record. Returns luminance 0...1 (paper around it is white).
    static func vinyl(_ u: Double, _ v: Double, spin: Double) -> Double {
        let dx = u - 0.5, dy = v - 0.5
        let r = hypot(dx, dy)
        let angle = atan2(dy, dx)
        if r > 0.47 { return 1 }                       // paper
        if r < 0.018 { return 0 }                      // spindle hole
        if r < 0.16 {                                  // label, two-tone so the spin shows
            if r > 0.145 { return 0.5 }
            return sin(angle + spin) > 0.35 ? 0.62 : 0.95
        }
        // Black vinyl with fine grooves and two lighter gaps between "tracks".
        var lum = 0.04 + 0.2 * pow(0.5 + 0.5 * sin(r * 120), 3)
        if abs(r - 0.29) < 0.008 || abs(r - 0.38) < 0.008 { lum += 0.45 }
        // Fixed sheen: two opposite soft wedges.
        lum += 0.6 * pow(max(0, cos(2 * (angle + 0.75))), 10) * (r / 0.47)
        return min(lum, 1)
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
