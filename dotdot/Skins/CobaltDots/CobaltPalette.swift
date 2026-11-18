//
//  CobaltPalette.swift
//  dotdot
//
//  Created by Maral on 17.11.2026.
//

import SwiftUI

/// Cobalt v2 look: white ink on cobalt, yellow accents (design: skin-cobalt-v2.html).
enum CobaltPalette {
    static let background = Color(hex: 0x2234C6)
    /// Deeper panel behind the dot art.
    static let panel = Color(hex: 0x1A29A8)
    /// Primary ink.
    static let ink = Color.white
    /// Secondary ink: subtitle, time labels, unselected presets.
    static let soft = Color(hex: 0xE2E7FF)
    /// Accent: star sticker, active FX, wave crest, treble sparkles.
    static let accent = Color(hex: 0xFFE76A)
}

extension AudioPreset {
    /// Preset label: "SLOWED", "SPED UP", "8D".
    var stickerLabel: String { title.uppercased() }
}
