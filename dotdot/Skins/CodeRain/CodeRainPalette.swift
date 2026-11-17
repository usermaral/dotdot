//
//  CodeRainPalette.swift
//  dotdot
//
//  Created by Maral on 17.11.2026.
//

import SwiftUI

/// Colors from design/skin-code-rain.html.
enum CodeRainPalette {
    static let background = Color.black
    static let green = Color(hex: 0x00FF66)
    static let midGreen = Color(hex: 0x00B347)
    static let darkGreen = Color(hex: 0x00602A)
    static let dimGreen = Color(hex: 0x0B2A15)
    static let head = Color(hex: 0xD8FFE0)
}

extension AudioPreset {
    /// Terminal-style label: "slowed", "sped_up", "8d".
    var terminalLabel: String {
        title.lowercased().replacingOccurrences(of: " ", with: "_")
    }
}
