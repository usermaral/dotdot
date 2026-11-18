//
//  PixelDesktopSkin.swift
//  dotdot
//
//  Created by Maral on 17.11.2026.
//

import SwiftUI

/// Main skin, built from design/skin-pixel-desktop.html (390 x 844 mockup).
struct PixelDesktopSkin: View {
    @Environment(PlayerModel.self) private var player
    @State private var isImporting = false

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                window
                    .padding(.horizontal, 14)
                    .padding(.top, 8)
                    .padding(.bottom, 14)
            }
            .scrollBounceBehavior(.basedOnSize)
            PixelTaskbar()
        }
        .background(PixelPalette.desktop.ignoresSafeArea())
        .foregroundStyle(.black)
        .skinChrome(isImporting: $isImporting)
    }

    // MARK: - Window

    private var window: some View {
        VStack(spacing: 10) {
            titleBar
            lcd.padding(.horizontal, 6)
            PixelProgressBar(progress: player.progress) { fraction in
                player.seek(to: fraction * player.duration)
            }
            .padding(.horizontal, 6)
            PixelControlPad()
                .padding(.vertical, 4)
            PixelPresetGroup()
                .padding(.horizontal, 6)
                .padding(.bottom, 6)
            statusBar
                .padding(.horizontal, 2)
                .padding(.bottom, 2)
        }
        .padding(3)
        .win98Bevel(.raised, fill: PixelPalette.face)
    }

    private var titleBar: some View {
        HStack {
            Text("dotdot.exe — \(player.currentTrack?.title ?? "no track")")
                .font(.pixelify(15, semibold: true))
                .lineLimit(1)
            Spacer(minLength: 8)
            menuButton
        }
        .foregroundStyle(.white)
        .padding(.leading, 8)
        .padding(.trailing, 4)
        .frame(height: 30)
        .background(LinearGradient(colors: [PixelPalette.titleStart, PixelPalette.titleEnd], startPoint: .leading, endPoint: .trailing))
    }

    /// The skin's single menu (tracks, skins, music), top right like in every skin.
    /// Sits where the mockup's caption buttons were, in the same raised style.
    private var menuButton: some View {
        SkinMenuButton(isImporting: $isImporting) {
            Text("Menu ▾")
                .font(.pixelify(12, semibold: true))
                .foregroundStyle(.black)
                .padding(.horizontal, 6)
                .frame(height: 18)
                .win98Bevel(.raised, fill: PixelPalette.face)
                .frame(height: 30) // whole title bar height is tappable
                .contentShape(Rectangle())
        }
    }

    // MARK: - LCD

    private var lcd: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(TimeFormat.lcd(player.currentTime))
                Spacer()
                Text(player.preset.map { PixelPresetGroup.label(for: $0).uppercased() } ?? "NORMAL")
            }
            .font(.vt323(20))
            PixelMarquee(text: marqueeText, isScrolling: player.isPlaying)
            PixelEQGrid(bands: player.bands, isActive: player.isPlaying)
        }
        .foregroundStyle(PixelPalette.lcdText)
        .padding(10)
        .win98Bevel(.sunken, fill: PixelPalette.lcdBackground)
    }

    private var marqueeText: String {
        guard let track = player.currentTrack else { return "*** Open a track from the Menu ***" }
        return "*** \(track.title) - \(track.url.lastPathComponent) ***"
    }

    // MARK: - Status bar

    private var statusBar: some View {
        HStack(spacing: 3) {
            statusCell(statusText)
                .frame(maxWidth: .infinity, alignment: .leading)
            statusCell(player.bitrateKbps.map { "\($0) kbps" } ?? "-- kbps")
                .frame(width: 90, alignment: .leading)
        }
        .font(.pixelify(13))
        .frame(height: 24)
    }

    private func statusCell(_ text: String) -> some View {
        Text(text)
            .lineLimit(1)
            .padding(.horizontal, 6)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .win98Bevel(.etched, width: 1)
    }

    private var statusText: String {
        guard let number = player.trackNumber else { return "Ready" }
        let state = player.isPlaying ? "Playing" : "Paused"
        return "\(state) · \(number) of \(player.tracks.count)"
    }
}
