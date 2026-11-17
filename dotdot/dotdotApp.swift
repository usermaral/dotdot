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

    init() {
        AppFonts.register()
    }

    var body: some Scene {
        WindowGroup {
            SkinHost()
                .environment(player)
        }
    }
}
