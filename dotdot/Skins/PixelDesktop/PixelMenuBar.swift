//
//  PixelMenuBar.swift
//  dotdot
//
//  Created by Maral on 18.11.2026.
//

import SwiftUI

/// Classic Win98 window menu bar under the title bar: "File" and "Skin",
/// with the underlined access-key letter. Not in the mockup; added so the
/// skin switcher is visible without knowing about the taskbar button.
struct PixelMenuBar: View {
    @AppStorage(PlayerSkin.storageKey) private var skin: PlayerSkin = .pixelDesktop
    @Binding var isImporting: Bool
    @Binding var isShowingDebug: Bool

    var body: some View {
        HStack(spacing: 0) {
            Menu {
                Button("Open music…", systemImage: "folder") { isImporting = true }
                Button("Debug panel", systemImage: "ladybug") { isShowingDebug = true }
            } label: {
                title("F", "ile")
            }
            .accessibilityLabel("File menu")

            Menu {
                Picker("Skin", selection: $skin) {
                    ForEach(PlayerSkin.allCases) { Text($0.title).tag($0) }
                }
                .pickerStyle(.inline)
            } label: {
                title("S", "kin")
            }
            .accessibilityLabel("Skin menu")

            Spacer(minLength: 0)
        }
        .simultaneousGesture(TapGesture().onEnded { Haptics.shared.play(.tap) })
        .padding(.horizontal, 4)
    }

    private func title(_ accessKey: String, _ rest: String) -> some View {
        (Text(accessKey).underline() + Text(rest))
            .font(.pixelify(14))
            .foregroundStyle(.black)
            .padding(.horizontal, 8)
            .frame(height: 22)
            .contentShape(Rectangle())
    }
}
