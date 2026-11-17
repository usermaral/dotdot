//
//  CobaltPalette.swift
//  dotdot
//
//  Created by Maral on 17.11.2026.
//

import SwiftUI

/// Colors from design/skin-cobalt-dots.html.
enum CobaltPalette {
    static let background = Color.white
    static let cobalt = Color(hex: 0x1E36C8)
    static let softCobalt = Color(hex: 0x3F55D6)
    static let gridBackground = Color(hex: 0xEEF1FF)
}

extension AudioPreset {
    /// Sticker label: "SLOWED", "SPED UP", "8D".
    var stickerLabel: String { title.uppercased() }

    /// Sticker tilt in degrees. First five come from the mockup; reverb (not in the mockup) gets +1.
    var stickerRotation: Double {
        switch self {
        case .slowed: -3
        case .tape: 2
        case .vinyl: -1
        case .spedUp: 3
        case .eightD: -2
        case .reverb: 1
        }
    }
}
