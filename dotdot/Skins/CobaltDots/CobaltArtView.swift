//
//  CobaltArtView.swift
//  dotdot
//
//  Created by Maral on 18.11.2026.
//

import SwiftUI

/// The Cobalt skin's centerpiece: a pure music visualizer on a tilted 28 x 28 dot card
/// (logic from skin-cobalt-v2.html). Soft blobs of dots each follow a part of the spectrum
/// and drift around the card; a ring sweeps out while playing, every kick sends a yellow
/// ripple, mids sway the grid and highs throw yellow sparkles. No cover art.
struct CobaltArtView: View {
    @Environment(PlayerModel.self) private var player
    let isPlaying: Bool

    @State private var motion = ArtMotion()

    private static let grid = 28

    /// Mockup blobs: home position, base radius, drift speed and phase.
    private static let blobs: [(x: Double, y: Double, r: Double, speed: Double, phase: Double)] = [
        (0.28, 0.32, 0.22, 0.31, 0.0),
        (0.62, 0.55, 0.26, 0.23, 2.1),
        (0.45, 0.82, 0.14, 0.41, 4.0),
        (0.82, 0.20, 0.12, 0.37, 5.3),
    ]

    var body: some View {
        // 30 fps is plenty for dots and halves the drawing cost.
        TimelineView(.animation(minimumInterval: isPlaying ? 1 / 30 : 1 / 20)) { timeline in
            Canvas { context, size in
                let t = timeline.date.timeIntervalSinceReferenceDate
                motion.update(time: t, bands: player.liveBands, isPlaying: isPlaying)
                drawDots(in: &context, size: size, time: t)
            }
        }
        .drawingGroup() // rasterize on the GPU (Metal), not the CPU
        .padding(12)
        .background(CobaltPalette.panel, in: RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(CobaltPalette.ink.opacity(0.55), lineWidth: 1.5))
        .rotationEffect(.degrees(-2))
        .accessibilityElement()
        .accessibilityLabel("Dot visualizer moving with the music")
    }

    private func drawDots(in context: inout GraphicsContext, size: CGSize, time t: Double) {
        let n = Self.grid
        let cell = min(size.width, size.height) / CGFloat(n)
        // Mockup dots are sized in px on a ~11.4 px cell; scale to this cell.
        let px = Double(cell) / 11.36
        let sparkleFrame = Int(t * 10)
        // Mockup: wave = (t * 0.55) % 1.6 — a ring sweeping out from the center (only while playing).
        let wave = (t * 0.55).truncatingRemainder(dividingBy: 1.6)

        // Each blob listens to its own part of the spectrum: big ones to bass/low-mids,
        // small ones to mids/highs. Louder = bigger; mids make them wander further.
        let levels = [motion.bass, motion.lowMid, motion.mid, motion.treble]
        let wander = 0.04 + motion.mid * 0.1
        let blobs = zip(Self.blobs, levels).map { blob, level in
            (x: blob.x + sin(t * blob.speed + blob.phase) * wander,
             y: blob.y + cos(t * blob.speed * 0.8 + blob.phase) * wander,
             r: blob.r * (0.8 + level * 0.9))
        }

        for y in 0..<n {
            for x in 0..<n {
                let u = Double(x) / Double(n - 1), v = Double(y) / Double(n - 1)
                let centerDistance = hypot(u - 0.5, v - 0.5)

                // Mockup field: sum of Gaussian blobs, gamma 1.6.
                var sum = 0.0
                for blob in blobs {
                    let d = hypot(u - blob.x, v - blob.y) / blob.r
                    sum += exp(-d * d * 1.6)
                }
                let l = min(1, pow(min(1, sum), 1.6))

                // Steady ring (mockup) plus kick ripples.
                let steady = isPlaying ? max(0, 1 - abs(centerDistance - wave) / 0.07) : 0
                let ring = max(steady, motion.ripple(at: centerDistance * 2, time: t))

                var width: Double
                var color: Color
                if l < 0.05 {
                    width = ring > 0 ? 3 : 1
                    color = CobaltPalette.ink.opacity(ring > 0 ? 0.6 : 0.25)
                } else {
                    width = min(11, (1 + l * 8 + ring * 3).rounded())
                    color = ring > 0.5 && l > 0.3 ? CobaltPalette.accent : CobaltPalette.ink
                }
                if motion.treble > 0.22, CoverArt.hash(x, y, sparkleFrame) % 47 == 0 {
                    width = 10
                    color = CobaltPalette.accent
                }

                // Mids sway rows and columns in a slow wave.
                let swayX = sin(t * 2.1 + Double(y) * 0.45) * motion.mid * Double(cell) * 0.5
                let swayY = cos(t * 1.7 + Double(x) * 0.40) * motion.mid * Double(cell) * 0.25
                let radius = width * px / 2
                let cx = (Double(x) + 0.5) * Double(cell) + swayX
                let cy = (Double(y) + 0.5) * Double(cell) + swayY
                let rect = CGRect(x: cx - radius, y: cy - radius, width: radius * 2, height: radius * 2)
                context.fill(Path(ellipseIn: rect), with: .color(color))
            }
        }
    }
}
