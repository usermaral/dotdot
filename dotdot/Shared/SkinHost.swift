//
//  SkinHost.swift
//  dotdot
//
//  Created by Maral on 17.11.2026.
//

import SwiftUI

/// Shows the selected skin. Skins never own state; they all read the shared `PlayerModel`.
struct SkinHost: View {
    @AppStorage(PlayerSkin.storageKey) private var skin: PlayerSkin = .pixelDesktop

    var body: some View {
        switch skin {
        case .pixelDesktop: PixelDesktopSkin()
        case .cobaltDots: CobaltDotsSkin()
        case .codeRain: CodeRainSkin()
        }
    }
}
