//
//  SkinMenu.swift
//  dotdot
//
//  Created by Maral on 17.11.2026.
//

import SwiftUI

/// What every skin's menu offers: tracks, skins, open music.
/// Each skin shows it from its own top-right button.
struct SkinMenuItems: View {
    @Environment(PlayerModel.self) private var player
    @AppStorage(PlayerSkin.storageKey) private var skin: PlayerSkin = .pixelDesktop
    @Binding var isImporting: Bool

    var body: some View {
        // The skins have no track list of their own, so the library lives here.
        if !player.tracks.isEmpty {
            Section("Tracks") {
                Picker("Track", selection: trackSelection) {
                    ForEach(player.tracks) { Text($0.title).tag(Optional($0)) }
                }
                .pickerStyle(.inline)
            }
        }
        // Skins listed directly in the menu (checkmark on the current one), not in a submenu.
        Section("Skin") {
            Picker("Skin", selection: $skin) {
                ForEach(PlayerSkin.allCases) { Text($0.title).tag($0) }
            }
            .pickerStyle(.inline)
        }
        Section {
            Button("Open music…", systemImage: "folder") { isImporting = true }
        }
        // Haptic when the menu opens. A tap gesture on the Menu's label would compete
        // with UIKit's menu recognizer and swallow taps, so it lives here instead.
        .onAppear { Haptics.shared.play(.tap) }
    }

    /// Picking a track plays it (picking the current one again restarts nothing).
    private var trackSelection: Binding<Track?> {
        Binding(
            get: { player.currentTrack },
            set: { track in
                guard let track, track != player.currentTrack else { return }
                player.select(track)
            }
        )
    }
}

/// The skin's menu button. A separate view on purpose: skin bodies re-render ~60×/s
/// (spectrum, time), and a `Menu` rebuilt that often makes UIKit refresh the open menu
/// constantly, so taps on its items get lost. This view only depends on its own inputs.
struct SkinMenuButton<Label: View>: View {
    @Binding var isImporting: Bool
    var accessibilityLabel = "Menu: tracks, skins and music"
    /// Stored as a value, not a closure: closures can't be compared, which would make
    /// SwiftUI treat this view as changed on every parent render and defeat the point.
    let label: Label

    init(isImporting: Binding<Bool>, @ViewBuilder label: () -> Label) {
        _isImporting = isImporting
        self.label = label()
    }

    var body: some View {
        Menu {
            SkinMenuItems(isImporting: $isImporting)
        } label: {
            label
        }
        .accessibilityLabel(accessibilityLabel)
    }
}

/// File importer that backs `SkinMenuItems`.
private struct SkinChrome: ViewModifier {
    @Binding var isImporting: Bool

    func body(content: Content) -> some View {
        content
            .musicImporter(isPresented: $isImporting)
    }
}

extension View {
    func skinChrome(isImporting: Binding<Bool>) -> some View {
        modifier(SkinChrome(isImporting: isImporting))
    }
}
