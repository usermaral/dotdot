//
//  PixelPalette.swift
//  dotdot
//
//  Created by Maral on 17.11.2026.
//

import SwiftUI

/// Colors from design/skin-pixel-desktop.html.
enum PixelPalette {
    static let desktop = Color(hex: 0x2B8C8C)
    static let face = Color(hex: 0xC3C3C3)
    static let padFace = Color(hex: 0xD9D9D9)
    static let field = Color(hex: 0xD4D4D4)
    static let highlight = Color.white
    static let shadow = Color(hex: 0x404040)
    static let etchedShadow = Color(hex: 0x808080)
    static let titleStart = Color(hex: 0x00087A)
    static let titleEnd = Color(hex: 0x1A7FD4)
    static let progress = Color(hex: 0x00087A)

    static let lcdBackground = Color(hex: 0x0A0F0A)
    static let lcdText = Color(hex: 0x7CFF6B)
    static let eqGreen = Color(hex: 0x7CFF6B)
    static let eqYellow = Color(hex: 0xFFD84A)
    static let eqRed = Color(hex: 0xFF5A4A)
    static let eqOff = Color(hex: 0x16261A)
}
