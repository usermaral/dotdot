//
//  CobaltDotMatrix.swift
//  dotdot
//
//  Created by Maral on 17.11.2026.
//

import SwiftUI

/// 22 x 22 halftone grid from the mockup: a ring + core that breathe with the bass,
/// plus scattered sparks while music plays.
struct CobaltDotMatrix: View {
    let bands: [Float]
    let isPlaying: Bool

    static let count = 22

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 30, paused: !isPlaying)) { timeline in
            Canvas { context, size in
                draw(in: &context, size: size, time: timeline.date.timeIntervalSinceReferenceDate)
            }
        }
        .padding(7)
        .background(CobaltPalette.gridBackground, in: RoundedRectangle(cornerRadius: 22))
        .rotationEffect(.degrees(-1.5))
        .accessibilityHidden(true)
    }

    /// Mockup: bass swings 0.55...1.0. Here it follows the three lowest bands.
    private var bass: Double {
        let low = bands.prefix(3)
        let level = low.isEmpty ? 0 : Double(low.reduce(0, +)) / Double(low.count)
        return 0.55 + 0.45 * level
    }

    private func draw(in context: inout GraphicsContext, size: CGSize, time: TimeInterval) {
        let n = Self.count
        let cell = min(size.width, size.height) / CGFloat(n)
        let center = Double(n - 1) / 2
        let bass = bass
        let sparkStep = Int(time * 6) // mockup: floor(t * 6), t in seconds
        let scale = cell / 13 // dot sizes are specified for 13 pt cells

        for y in 0..<n {
            for x in 0..<n {
                let dx = (Double(x) - center) / center
                let dy = (Double(y) - center) / center
                let d = (dx * dx + dy * dy).squareRoot()
                let ring = max(0, 1 - abs(d - bass * 0.75) * 3.2)
                let core = max(0, 1 - d / (0.35 * bass))
                let spark = isPlaying && (x * 7 + y * 13 + sparkStep) % 23 == 0 ? 0.6 : 0
                let value = min(1, max(ring, core) + spark)
                let diameter = (1.5 + value * 10).rounded() * scale
                let rect = CGRect(
                    x: (CGFloat(x) + 0.5) * cell - diameter / 2,
                    y: (CGFloat(y) + 0.5) * cell - diameter / 2,
                    width: diameter,
                    height: diameter
                )
                context.fill(Path(ellipseIn: rect), with: .color(CobaltPalette.cobalt))
            }
        }
    }
}
