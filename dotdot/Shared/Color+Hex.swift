//
//  Color+Hex.swift
//  dotdot
//
//  Created by Maral on 17.11.2026.
//

import SwiftUI

extension Color {
    /// `Color(hex: 0x2B8C8C)` — matches the hex values in the HTML mockups.
    init(hex: UInt32, opacity: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: opacity
        )
    }
}
