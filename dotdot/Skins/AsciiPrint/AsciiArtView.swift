//
//  AsciiArtView.swift
//  dotdot
//
//  Created by Maral on 18.11.2026.
//

import SwiftUI

/// The track's cover (or a spinning vinyl record) typed out as classic ASCII art: a long glyph ramp,
/// printed positive (dark cover areas become dense letters, light areas stay paper).
/// Bass swells the ink and zooms in, kicks carve a ring that glitches the characters,
/// mids make the rows drift sideways, highs scatter stray glyphs across the paper.
struct AsciiArtView: View {
    let trackURL: URL?
    @Environment(PlayerModel.self) private var player
    let isPlaying: Bool

    /// Cover luminance; nil = draw the vinyl record.
    @State private var cover: [Float]?
    @State private var motion = ArtMotion()

    /// Light to dense; on paper, dense glyphs read as dark.
    private static let ramp = Array(#" .'`^",:;Il!i><~+_-?][}{1)(|/tfjrxnuvczXYUJCLQ0OZmwqpdbkhao*#MW&8%B@$"#)
        .map(String.init)
    private static let columns = 50

    var body: some View {
        TimelineView(.animation(minimumInterval: isPlaying ? 1 / 30 : 1 / 12)) { timeline in
            Canvas { context, size in
                let t = timeline.date.timeIntervalSinceReferenceDate
                motion.update(time: t, bands: player.liveBands, isPlaying: isPlaying)
                draw(in: &context, size: size, time: t)
            }
        }
        .drawingGroup() // rasterize on the GPU (Metal), not the CPU
        .task(id: trackURL) {
            var loaded: [Float]?
            if let trackURL { loaded = await CoverArt.coverLuminance(for: trackURL) }
            cover = loaded
        }
        .accessibilityElement()
        .accessibilityLabel("Album art typed out in ASCII characters, moving with the music")
    }

    private func draw(in context: inout GraphicsContext, size: CGSize, time t: Double) {
        let columns = Self.columns
        let cellWidth = size.width / CGFloat(columns)
        let cellHeight = cellWidth * 1.55
        let rows = Int(size.height / cellHeight)
        guard rows > 0 else { return }
        let ramp = Self.ramp
        let font = Font.spaceMono(cellWidth * 1.62, bold: true)
        // One Text per row instead of one per glyph (~22 draws a frame instead of ~1100).
        // Space Mono is monospaced; scale each row so its advance matches the cell grid exactly.
        let sample = context.resolve(Text(String(repeating: "M", count: columns)).font(font))
        let rowScale = size.width / max(sample.measure(in: CGSize(width: CGFloat.infinity, height: CGFloat.infinity)).width, 1)
        // The cover is square, the grid is not: show a centered square-pixel crop of it.
        let gridAspect = Double(CGFloat(rows) * cellHeight / size.width)
        let vSpan = min(gridAspect, 1), vStart = (1 - vSpan) / 2
        let glitchFrame = Int(t * 18)
        let originY = (size.height - CGFloat(rows) * cellHeight) / 2
        let top = Double(ramp.count - 1)

        // Bass (idle breathing is ~0.15...0.23): zoom in a little and print darker.
        let punch = max(motion.bass - 0.18, 0)
        let zoom = 1 + punch * 0.2
        let gain = min(0.8 + punch * 0.5, 1.05)
        // The record is round, so it fits the grid's shorter side instead of being cropped.
        let gridHeight = Double(CGFloat(rows) * cellHeight)
        let recordSize = min(Double(size.width), gridHeight)
        let scatter = Int(max(motion.treble - 0.12, 0) * 40) // per-mille of cells

        for y in 0..<rows {
            // Mids: each row drifts sideways, like a misfed printer.
            let drift = sin(t * 2.3 + Double(y) * 0.5) * motion.mid * Double(cellWidth) * 2.2
            var line = ""
            line.reserveCapacity(columns)
            for x in 0..<columns {
                let u = (Double(x) + 0.5) / Double(columns), v = vStart + (Double(y) + 0.5) / Double(rows) * vSpan
                let d = hypot(u * 2 - 1, v * 2 - 1)
                let wave = motion.ripple(at: d, time: t)
                // Positive print: dark cover pixels become dense glyphs.
                let lum: Double
                if let cover {
                    lum = CoverArt.sample(cover, 0.5 + (u - 0.5) / zoom, 0.5 + (v - 0.5) / zoom)
                } else {
                    let ru = ((Double(x) + 0.5) * Double(cellWidth) - Double(size.width) / 2) / recordSize
                    let rv = ((Double(y) + 0.5) * Double(cellHeight) - gridHeight / 2) / recordSize
                    lum = CoverArt.vinyl(0.5 + ru / zoom, 0.5 + rv / zoom, spin: motion.spin)
                }
                let ink = 1 - lum
                var level = ink * top * gain
                // Static dither so flat areas print as a mix of neighbouring glyphs, not "kkkk".
                if ink > 0.08 { level += Double(CoverArt.hash(x, y, 7) % 13) - 6 }
                // Kick ring: light gap through ink, ink through empty paper.
                level += wave * top * (ink > 0.45 ? -0.6 : 0.5)
                if wave > 0.35, CoverArt.hash(x, y, glitchFrame) % 3 == 0 {
                    level = Double(CoverArt.hash(y, x, glitchFrame) % ramp.count) // glitch
                } else if scatter > 0, CoverArt.hash(x, y, glitchFrame / 2) % 1000 < scatter {
                    level = Double(20 + CoverArt.hash(y, x, glitchFrame) % 40) // treble sparkle
                }
                let index = min(max(Int(level.rounded()), 0), ramp.count - 1)
                line += ramp[index] // index 0 is a space
            }
            let text = context.resolve(Text(line).font(font).foregroundStyle(AsciiPalette.ink))
            var row = context
            row.translateBy(x: drift, y: originY + (CGFloat(y) + 0.5) * cellHeight)
            row.scaleBy(x: rowScale, y: 1)
            row.draw(text, at: .zero, anchor: .leading)
        }
    }
}
