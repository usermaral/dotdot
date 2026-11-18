//
//  PlayerSkin.swift
//  dotdot
//
//  Created by Maral on 17.11.2026.
//

import SwiftUI

nonisolated enum PlayerSkin: String, CaseIterable, Identifiable, Sendable {
    // Order here is the order in the skin menu.
    case pixelDesktop
    case codeRain
    case asciiPrint
    case cobaltDots

    static let storageKey = "selectedSkin"

    var id: String { rawValue }

    /// Light skins get dark status-bar text; dark skins get light text.
    var colorScheme: ColorScheme {
        switch self {
        case .pixelDesktop, .asciiPrint: .light
        case .cobaltDots, .codeRain: .dark
        }
    }

    var title: String {
        switch self {
        case .pixelDesktop: "Pixel Desktop"
        case .cobaltDots: "Cobalt Dots"
        case .codeRain: "Code Rain"
        case .asciiPrint: "ASCII Print"
        }
    }
}
