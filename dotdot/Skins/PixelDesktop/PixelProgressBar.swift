//
//  PixelProgressBar.swift
//  dotdot
//
//  Created by Maral on 17.11.2026.
//

import SwiftUI

/// Win98 block progress bar (9 pt blocks, 2 pt gaps). Tap or drag to seek.
struct PixelProgressBar: View {
    let progress: Double
    let onSeek: (Double) -> Void

    @State private var dragProgress: Double?
    @State private var trackWidth: CGFloat = 1

    private let blockWidth: CGFloat = 9
    private let gap: CGFloat = 2

    var body: some View {
        // Mockup: 16 pt tall, border-box with a 2 pt sunken border and 2 pt padding.
        Canvas { context, size in
            let capacity = Int((size.width + gap) / (blockWidth + gap))
            let shown = min(max(dragProgress ?? progress, 0), 1)
            let filled = Int((Double(capacity) * shown).rounded())
            for index in 0..<filled {
                let rect = CGRect(x: CGFloat(index) * (blockWidth + gap), y: 0, width: blockWidth, height: size.height)
                context.fill(Path(rect), with: .color(PixelPalette.progress))
            }
        }
        .frame(height: 8)
        .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { trackWidth = max($0, 1) }
        .padding(2)
        .win98Bevel(.sunken, fill: .white)
        .contentShape(Rectangle())
        .gesture(seekGesture)
        .accessibilityElement()
        .accessibilityLabel("Position")
        .accessibilityValue("\(Int(progress * 100)) percent")
    }

    private var seekGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                // 4 pt = border + padding before the block track starts.
                dragProgress = Double(min(max((value.location.x - 4) / trackWidth, 0), 1))
            }
            .onEnded { _ in
                if let fraction = dragProgress { onSeek(fraction) }
                dragProgress = nil
            }
    }
}
