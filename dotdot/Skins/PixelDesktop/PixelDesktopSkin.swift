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
    @State private var isShowingDebug = false

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                window
                    .padding(.horizontal, 14)
                    .padding(.top, 8)
                    .padding(.bottom, 14)
            }
            .scrollBounceBehavior(.basedOnSize)
            PixelTaskbar(isImporting: $isImporting, isShowingDebug: $isShowingDebug)
        }
        .background(PixelPalette.desktop.ignoresSafeArea())
        .foregroundStyle(.black)
        .musicImporter(isPresented: $isImporting, showsErrors: !isShowingDebug)
        .sheet(isPresented: $isShowingDebug) { PlayerDebugView() }
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
            HStack(spacing: 3) {
                titleButton("_")
                titleButton("x")
            }
        }
        .foregroundStyle(.white)
        .padding(.leading, 8)
        .padding(.trailing, 4)
        .frame(height: 30)
        .background(LinearGradient(colors: [PixelPalette.titleStart, PixelPalette.titleEnd], startPoint: .leading, endPoint: .trailing))
    }

    /// Decorative caption buttons (the app has a single window).
    private func titleButton(_ glyph: String) -> some View {
        Text(glyph)
            .font(.pixelify(12, semibold: true))
            .foregroundStyle(.black)
            .frame(width: 20, height: 18)
            .win98Bevel(.raised, fill: PixelPalette.face)
            .accessibilityHidden(true)
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
            // CSS `white-space: nowrap; overflow: hidden`: the line must not widen the window.
            Color.clear
                .frame(height: 26)
                .overlay(alignment: .leading) {
                    Text(marqueeText)
                        .font(.vt323(26))
                        .fixedSize()
                }
                .clipped()
            PixelEQGrid(bands: player.bands, isActive: player.isPlaying)
        }
        .foregroundStyle(PixelPalette.lcdText)
        .padding(10)
        .win98Bevel(.sunken, fill: PixelPalette.lcdBackground)
    }

    private var marqueeText: String {
        guard let track = player.currentTrack else { return "*** Open a track from the dotdot menu ***" }
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
