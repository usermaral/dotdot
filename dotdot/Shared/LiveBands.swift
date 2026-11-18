//
//  LiveBands.swift
//  dotdot
//
//  Created by Maral on 18.11.2026.
//

import SwiftUI

/// Reads `PlayerModel.bands` (updated ~60×/s) in its own tiny view, so only the visualizer
/// re-renders every frame, not the whole skin. Use instead of reading `player.bands`
/// in a skin's body: `LiveBands { bands in SomeVisualizer(bands: bands) }`.
struct LiveBands<Content: View>: View {
    @Environment(PlayerModel.self) private var player
    @ViewBuilder let content: ([Float]) -> Content

    var body: some View {
        content(player.bands)
    }
}
