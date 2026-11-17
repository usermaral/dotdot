//
//  dotdotApp.swift
//  dotdot
//
//  Created by Maral on 17.11.2026.
//

import SwiftUI

@main
struct dotdotApp: App {
    @State private var player = PlayerModel()

    var body: some Scene {
        WindowGroup {
            // Milestone 1: debug screen is the root. Switch to SkinHost once skins exist.
            PlayerDebugView()
                .environment(player)
        }
    }
}
