//
//  PixelMarquee.swift
//  dotdot
//
//  Created by Maral on 18.11.2026.
//

import SwiftUI

/// Single-line LCD text. Scrolls like a Winamp marquee while playing if it overflows;
/// otherwise it sits still and clips, like the mockup's `overflow: hidden`.
struct PixelMarquee: View {
    let text: String
    let isScrolling: Bool

    var font: Font = .vt323(26)
    var height: CGFloat = 26
    /// Points per second.
    var speed: Double = 32
    var gap: CGFloat = 40

    @State private var textWidth: CGFloat = 0
    @State private var boxWidth: CGFloat = 0
    @State private var start = Date()

    private var overflows: Bool { textWidth > boxWidth }

    var body: some View {
        Color.clear
            .frame(height: height)
            .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { boxWidth = $0 }
            .overlay(alignment: .leading) {
                if isScrolling && overflows {
                    TimelineView(.animation(minimumInterval: 1 / 30)) { timeline in
                        let cycle = Double(textWidth + gap)
                        let offset = (timeline.date.timeIntervalSince(start) * speed).truncatingRemainder(dividingBy: cycle)
                        HStack(spacing: gap) {
                            label
                            label
                        }
                        // Snap to whole points so the pixel font doesn't shimmer.
                        .offset(x: -CGFloat(offset).rounded())
                    }
                } else {
                    label
                }
            }
            .clipped()
            .onChange(of: text) { start = Date() }
            .onChange(of: isScrolling) { start = Date() }
            .accessibilityElement()
            .accessibilityLabel(text)
    }

    private var label: some View {
        Text(text)
            .font(font)
            .fixedSize()
            .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { textWidth = $0 }
    }
}
