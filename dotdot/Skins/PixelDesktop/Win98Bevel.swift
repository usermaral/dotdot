//
//  Win98Bevel.swift
//  dotdot
//
//  Created by Maral on 17.11.2026.
//

import SwiftUI

/// CSS `border-color: <top-left> <bottom-right>` bevels used across the Win98 skin.
enum Win98Bevel {
    /// Raised button / window: white top-left, dark bottom-right.
    case raised
    /// Sunken field / LCD: dark top-left, white bottom-right.
    case sunken
    /// Etched group box and status cells: grey top-left, white bottom-right.
    case etched

    var colors: (topLeading: Color, bottomTrailing: Color) {
        switch self {
        case .raised: (PixelPalette.highlight, PixelPalette.shadow)
        case .sunken: (PixelPalette.shadow, PixelPalette.highlight)
        case .etched: (PixelPalette.etchedShadow, PixelPalette.highlight)
        }
    }
}

private struct RectBevel: ViewModifier {
    let style: Win98Bevel
    let width: CGFloat
    let fill: Color?

    func body(content: Content) -> some View {
        let (light, dark) = style.colors
        content
            .padding(width) // CSS border sits outside the content box
            .background(fill ?? .clear)
            .overlay {
                GeometryReader { geo in
                    let w = geo.size.width, h = geo.size.height
                    Path { p in
                        p.addRect(CGRect(x: 0, y: h - width, width: w, height: width))
                        p.addRect(CGRect(x: w - width, y: 0, width: width, height: h))
                    }
                    .fill(dark)
                    Path { p in
                        p.addRect(CGRect(x: 0, y: 0, width: w - width, height: width))
                        p.addRect(CGRect(x: 0, y: 0, width: width, height: h - width))
                    }
                    .fill(light)
                }
                .allowsHitTesting(false)
            }
    }
}

extension View {
    func win98Bevel(_ style: Win98Bevel, width: CGFloat = 2, fill: Color? = nil) -> some View {
        modifier(RectBevel(style: style, width: width, fill: fill))
    }

    /// Round bevel: the border is split diagonally between the two colors, like CSS on a circle.
    func win98CircleBevel(_ style: Win98Bevel, width: CGFloat, fill: Color) -> some View {
        let (light, dark) = style.colors
        return background(Circle().fill(fill))
            .overlay(
                Circle().strokeBorder(
                    LinearGradient(
                        stops: [.init(color: light, location: 0.5), .init(color: dark, location: 0.5)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: width
                )
                .allowsHitTesting(false)
            )
    }
}
