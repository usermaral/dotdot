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
        ZStack {
            Group {
                switch skin {
                case .pixelDesktop: PixelDesktopSkin()
                case .cobaltDots: CobaltDotsSkin()
                case .codeRain: CodeRainSkin()
                case .asciiPrint: AsciiPrintSkin()
                }
            }
            // Status bar and menus match the skin's background, whatever the system theme.
            .preferredColorScheme(skin.colorScheme)
            .id(skin)
            .transition(.opacity)
        }
        .animation(.easeInOut(duration: 0.35), value: skin)
        .onChange(of: skin) { Haptics.shared.play(.press) }
    }
}
