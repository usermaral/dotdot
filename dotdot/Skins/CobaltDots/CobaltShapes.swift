//
//  CobaltShapes.swift
//  dotdot
//
//  Created by Maral on 17.11.2026.
//

import SwiftUI

/// SVG paths from the mockup, drawn in their 24 x 24 viewBox and scaled to the frame.
private func scaled(_ rect: CGRect, _ build: (inout Path) -> Void) -> Path {
    var path = Path()
    build(&path)
    let scale = min(rect.width, rect.height) / 24
    return path.applying(CGAffineTransform(scaleX: scale, y: scale).concatenating(
        CGAffineTransform(translationX: rect.minX, y: rect.minY)))
}

/// `M12 2l2.6 6.4L21 9l-5 4.4L17.5 20 12 16.6 6.5 20 8 13.4 3 9l6.4-.6z`
struct StarSticker: Shape {
    func path(in rect: CGRect) -> Path {
        scaled(rect) { p in
            p.addLines([
                CGPoint(x: 12, y: 2), CGPoint(x: 14.6, y: 8.4), CGPoint(x: 21, y: 9), CGPoint(x: 16, y: 13.4),
                CGPoint(x: 17.5, y: 20), CGPoint(x: 12, y: 16.6), CGPoint(x: 6.5, y: 20), CGPoint(x: 8, y: 13.4),
                CGPoint(x: 3, y: 9), CGPoint(x: 9.4, y: 8.4),
            ])
            p.closeSubpath()
        }
    }
}

enum TransportIcon {
    case previous, next, play, pause
}

/// Transport glyphs from the mockup (pause is not in the mockup: two strokes in the same style).
struct TransportIconShape: Shape {
    let icon: TransportIcon

    func path(in rect: CGRect) -> Path {
        scaled(rect) { p in
            switch icon {
            case .previous:
                p.addLines([CGPoint(x: 19, y: 5), CGPoint(x: 9, y: 12), CGPoint(x: 19, y: 19)])
                p.closeSubpath()
                p.move(to: CGPoint(x: 5, y: 5)); p.addLine(to: CGPoint(x: 5, y: 19))
            case .next:
                p.addLines([CGPoint(x: 5, y: 5), CGPoint(x: 15, y: 12), CGPoint(x: 5, y: 19)])
                p.closeSubpath()
                p.move(to: CGPoint(x: 19, y: 5)); p.addLine(to: CGPoint(x: 19, y: 19))
            case .play:
                p.addLines([CGPoint(x: 7, y: 4), CGPoint(x: 20, y: 12), CGPoint(x: 7, y: 20)])
                p.closeSubpath()
            case .pause:
                p.move(to: CGPoint(x: 8, y: 5)); p.addLine(to: CGPoint(x: 8, y: 19))
                p.move(to: CGPoint(x: 16, y: 5)); p.addLine(to: CGPoint(x: 16, y: 19))
            }
        }
    }
}
