//
//  PixelEQGrid.swift
//  dotdot
//
//  Created by Maral on 17.11.2026.
//

import SwiftUI

/// 16 x 10 LED grid. Column height comes from `PlayerModel.bands`;
/// colors follow the mockup: rows 1-6 green, 7-8 yellow, 9-10 red, unlit #16261A.
struct PixelEQGrid: View {
    let bands: [Float]
    var isActive: Bool

    static let rows = 10
    static let cellHeight: CGFloat = 9
    static let gap: CGFloat = 2

    var body: some View {
        Canvas { context, size in
            let columns = bands.count
            guard columns > 0 else { return }
            let gap = Self.gap
            let cellWidth = (size.width - gap * CGFloat(columns - 1)) / CGFloat(columns)
            for x in 0..<columns {
                let lit = litRows(for: bands[x])
                for y in 0..<Self.rows {
                    let level = Self.rows - y
                    let rect = CGRect(
                        x: CGFloat(x) * (cellWidth + gap),
                        y: CGFloat(y) * (Self.cellHeight + gap),
                        width: cellWidth,
                        height: Self.cellHeight
                    )
                    context.fill(Path(rect), with: .color(color(level: level, lit: level <= lit)))
                }
            }
        }
        .frame(height: CGFloat(Self.rows) * Self.cellHeight + CGFloat(Self.rows - 1) * Self.gap)
        .accessibilityHidden(true)
    }

    private func litRows(for band: Float) -> Int {
        let rows = Int((band * Float(Self.rows)).rounded())
        // Like the mockup, a playing column always shows at least one LED.
        return isActive ? max(1, rows) : rows
    }

    private func color(level: Int, lit: Bool) -> Color {
        guard lit else { return PixelPalette.eqOff }
        if level > 8 { return PixelPalette.eqRed }
        if level > 6 { return PixelPalette.eqYellow }
        return PixelPalette.eqGreen
    }
}
