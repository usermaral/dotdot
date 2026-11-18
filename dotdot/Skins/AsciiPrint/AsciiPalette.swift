//
//  AsciiPalette.swift
//  dotdot
//
//  Created by Maral on 18.11.2026.
//

import SwiftUI

/// Receipt look: navy type on a white till receipt over pale blue (design: skin-receipt-v2.html).
enum AsciiPalette {
    static let background = Color(hex: 0xE9EDF5)
    static let paper = Color.white
    static let ink = Color(hex: 0x1B2466)
    static let softInk = Color(hex: 0x4A527F)
    /// Dotted leaders between a label and its value.
    static let leader = Color(hex: 0x8A91B8)
}
