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

/// Temporary stand-in until each skin is built from its HTML mockup.
struct SkinPlaceholder: View {
    let title: String
    @Environment(PlayerModel.self) private var player

    var body: some View {
        VStack(spacing: 12) {
            Text(title).font(.title2.bold())
            Text(player.currentTrack?.title ?? "No track")
            Button(player.isPlaying ? "Pause" : "Play") { player.togglePlayPause() }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
