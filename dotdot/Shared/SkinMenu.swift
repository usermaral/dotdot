//
//  SkinMenu.swift
//  dotdot
//
//  Created by Maral on 17.11.2026.
//

import SwiftUI

/// Actions every skin's menu offers: open music, switch skin, debug panel.
/// Each skin decides what opens it (taskbar button, logo, now-playing card).
struct SkinMenuItems: View {
    @AppStorage(PlayerSkin.storageKey) private var skin: PlayerSkin = .pixelDesktop
    @Binding var isImporting: Bool
    @Binding var isShowingDebug: Bool

    var body: some View {
        // Skins listed directly in the menu (checkmark on the current one), not in a submenu.
        Section("Skin") {
            Picker("Skin", selection: $skin) {
                ForEach(PlayerSkin.allCases) { Text($0.title).tag($0) }
            }
            .pickerStyle(.inline)
        }
        Section {
            Button("Open music…", systemImage: "folder") { isImporting = true }
            Button("Debug panel", systemImage: "ladybug") { isShowingDebug = true }
        }
    }
}

/// File importer + debug sheet that back `SkinMenuItems`.
private struct SkinChrome: ViewModifier {
    @Binding var isImporting: Bool
    @Binding var isShowingDebug: Bool

    func body(content: Content) -> some View {
        content
            .musicImporter(isPresented: $isImporting, showsErrors: !isShowingDebug)
            .sheet(isPresented: $isShowingDebug) { PlayerDebugView() }
    }
}

extension View {
    func skinChrome(isImporting: Binding<Bool>, isShowingDebug: Binding<Bool>) -> some View {
        modifier(SkinChrome(isImporting: isImporting, isShowingDebug: isShowingDebug))
    }
}
