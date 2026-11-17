//
//  PixelDesktopSkin.swift
//  dotdot
//
//  Created by Maral on 17.11.2026.
//

import SwiftUI

/// Placeholder. Real layout comes from design/skin-pixel-desktop.html.
struct PixelDesktopSkin: View {
    @Environment(PlayerModel.self) private var player

    var body: some View {
        SkinPlaceholder(title: PlayerSkin.pixelDesktop.title)
    }
}
