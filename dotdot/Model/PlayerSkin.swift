//
//  PlayerSkin.swift
//  dotdot
//
//  Created by Maral on 17.11.2026.
//

import Foundation

nonisolated enum PlayerSkin: String, CaseIterable, Identifiable, Sendable {
    case pixelDesktop
    case cobaltDots
    case codeRain

    static let storageKey = "selectedSkin"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .pixelDesktop: "Pixel Desktop"
        case .cobaltDots: "Cobalt Dots"
        case .codeRain: "Code Rain"
        }
    }
}
