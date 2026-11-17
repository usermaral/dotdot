//
//  CodeRainSkin.swift
//  dotdot
//
//  Created by Maral on 17.11.2026.
//

import SwiftUI

/// Placeholder. Real layout comes from design/skin-code-rain.html.
struct CodeRainSkin: View {
    @Environment(PlayerModel.self) private var player

    var body: some View {
        SkinPlaceholder(title: PlayerSkin.codeRain.title)
    }
}
