//
//  CodeRainField.swift
//  dotdot
//
//  Created by Maral on 17.11.2026.
//

import SwiftUI

/// Port of the mockup's rain script: 26 columns x 26 rows of hex glyphs.
/// A column's tail length and fall speed follow the spectrum band under it.
final class RainSimulation {
    static let columns = 26
    static let rows = 26
    /// The mockup advances one step every 90 ms; speeds below are in rows per step.
    static let step: TimeInterval = 0.09

    private(set) var heads: [Double]
    private(set) var tails: [Int]
    /// Step counter (`n` in the mockup), drives glyph flicker.
    private(set) var clock: Double = 0
    private var lastDate: Date?

    init() {
        heads = (0..<Self.columns).map { Double($0 * 11 % (Self.rows + 4)) }
        tails = Array(repeating: 4, count: Self.columns)
    }

    func advance(to date: Date, bands: [Float]) {
        let elapsed = lastDate.map { min(max(date.timeIntervalSince($0), 0), 0.25) } ?? 0
        lastDate = date
        let steps = elapsed / Self.step
        clock += steps

        for i in 0..<Self.columns {
            let level = Double(Self.level(column: i, bands: bands))
            let tail = Int((4 + level * 16).rounded())
            let speed = 0.35 + Double((i * 37) % 10) / 20 + level * 0.4
            tails[i] = tail
            heads[i] = (heads[i] + speed * steps).truncatingRemainder(dividingBy: Double(Self.rows + tail))
        }
    }

    /// Spreads 16 bands across 26 columns.
    static func level(column: Int, bands: [Float]) -> Float {
        guard !bands.isEmpty else { return 0 }
        return bands[min(column * bands.count / columns, bands.count - 1)]
    }
}

struct CodeRainField: View {
    let bands: [Float]

    @State private var simulation = RainSimulation()

    private static let glyphs = Array("0123456789ABCDEF").map(String.init)
    private static let colors = [
        CodeRainPalette.dimGreen, CodeRainPalette.head, CodeRainPalette.green,
        CodeRainPalette.midGreen, CodeRainPalette.darkGreen,
    ]
    private let columnWidth: CGFloat = 15
    private let rowHeight: CGFloat = 16

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 30)) { timeline in
            Canvas { context, size in
                simulation.advance(to: timeline.date, bands: bands)
                draw(in: &context, size: size)
            }
        }
        .accessibilityHidden(true)
    }

    private func draw(in context: inout GraphicsContext, size: CGSize) {
        // Resolve each glyph/color pair once per frame (16 x 5) instead of per cell.
        let resolved = Self.colors.map { color in
            Self.glyphs.map { context.resolve(Text($0).font(.shareTechMono(14)).foregroundStyle(color)) }
        }
        let originX = (size.width - columnWidth * CGFloat(RainSimulation.columns)) / 2
        let step = Int(simulation.clock)

        for i in 0..<RainSimulation.columns {
            let head = Int(simulation.heads[i])
            let tail = simulation.tails[i]
            for j in 0..<RainSimulation.rows {
                let glyph = (i * 31 + j * 17 + (step + i * 3) / 6) % 16
                let distance = head - j
                let colorIndex: Int
                if distance == 0 {
                    colorIndex = 1
                } else if distance > 0, distance < tail {
                    let ratio = Double(distance) / Double(tail)
                    colorIndex = ratio < 0.35 ? 2 : ratio < 0.7 ? 3 : 4
                } else {
                    colorIndex = 0
                }
                let point = CGPoint(
                    x: originX + (CGFloat(i) + 0.5) * columnWidth,
                    y: (CGFloat(j) + 0.5) * rowHeight
                )
                context.draw(resolved[colorIndex][glyph], at: point)
            }
        }
    }
}
