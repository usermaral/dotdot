//
//  CodeRainSkin.swift
//  dotdot
//
//  Created by Maral on 17.11.2026.
//

import SwiftUI

/// Built from design/skin-code-rain.html: hex rain on top, terminal controls below.
/// Tapping the now_playing card opens the dotdot menu (music, skins, debug).
struct CodeRainSkin: View {
    @Environment(PlayerModel.self) private var player
    @State private var isImporting = false
    @State private var isShowingDebug = false
    @State private var scrubProgress: Double?

    private let barLength = 24

    var body: some View {
        VStack(spacing: 0) {
            rainArea
                .frame(minHeight: 220, maxHeight: 426)
                .layoutPriority(1)
            controls
        }
        .font(.shareTechMono(14))
        .foregroundStyle(CodeRainPalette.green)
        .background(CodeRainPalette.background.ignoresSafeArea())
        .skinChrome(isImporting: $isImporting, isShowingDebug: $isShowingDebug)
    }

    // MARK: - Rain + now playing card

    private var rainArea: some View {
        CodeRainField(bands: player.bands)
            .clipped()
            .overlay(alignment: .bottom) {
                nowPlayingCard
                    .padding(.horizontal, 22)
                    .padding(.bottom, 22)
            }
            .overlay(alignment: .topTrailing) {
                menuButton
                    .padding(.trailing, 22)
                    .padding(.top, 8)
            }
    }

    /// Visible way into the dotdot menu (skins, music, debug).
    private var menuButton: some View {
        Menu {
            SkinMenuItems(isImporting: $isImporting, isShowingDebug: $isShowingDebug)
        } label: {
            Text("> menu")
                .font(.shareTechMono(13))
                .foregroundStyle(CodeRainPalette.green)
                .padding(.horizontal, 10)
                .frame(height: 30)
                .background(CodeRainPalette.background)
                .overlay(Rectangle().strokeBorder(CodeRainPalette.green, lineWidth: 1))
                .padding(.vertical, 7) // 44 pt touch target
                .contentShape(Rectangle())
        }
        .simultaneousGesture(TapGesture().onEnded { Haptics.shared.play(.tap) })
        .accessibilityLabel("Menu: skins and music")
    }

    private var nowPlayingCard: some View {
        Menu {
            SkinMenuItems(isImporting: $isImporting, isShowingDebug: $isShowingDebug)
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                Text("> now_playing --fx \(player.preset?.terminalLabel ?? "none")")
                    .font(.shareTechMono(12))
                    .foregroundStyle(CodeRainPalette.midGreen)
                Text(player.currentTrack?.title ?? "no track")
                    .font(.shareTechMono(26))
                    .foregroundStyle(CodeRainPalette.head)
                    .lineLimit(1)
                Text(player.currentTrack?.url.lastPathComponent ?? "tap to open music")
                    .font(.shareTechMono(13))
                    .foregroundStyle(CodeRainPalette.midGreen)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 12)
            .padding(.horizontal, 14)
            .background(CodeRainPalette.background)
            .overlay(Rectangle().strokeBorder(CodeRainPalette.green, lineWidth: 1))
            .contentShape(Rectangle())
        }
        .simultaneousGesture(TapGesture().onEnded { Haptics.shared.play(.tap) })
    }

    // MARK: - Controls

    private var controls: some View {
        VStack(spacing: 16) {
            progress
            transport
            Spacer(minLength: 0)
            presetGrid
        }
        .padding(EdgeInsets(top: 18, leading: 22, bottom: 28, trailing: 22))
    }

    private var progress: some View {
        let shown = min(max(scrubProgress ?? player.progress, 0), 1)
        let filled = Int((shown * Double(barLength)).rounded())
        let bar = String(repeating: "#", count: filled) + String(repeating: ".", count: barLength - filled)
        return VStack(spacing: 6) {
            Text("[\(bar)]")
                .tracking(1)
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
                .gesture(seekGesture)
            HStack {
                Text(TimeFormat.lcd(player.currentTime))
                Spacer()
                Text("-" + TimeFormat.lcd(max(player.duration - player.currentTime, 0)))
            }
            .font(.shareTechMono(13))
            .foregroundStyle(CodeRainPalette.midGreen)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Position")
        .accessibilityValue("\(TimeFormat.clock(player.currentTime)) of \(TimeFormat.clock(player.duration))")
    }

    private var seekGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                // One "#" cell is ~9.4 pt in Share Tech Mono 14 + 1 pt tracking; skip the "[".
                let cell: CGFloat = 9.4
                let fraction = (value.location.x - cell) / (cell * CGFloat(barLength))
                scrubProgress = Double(min(max(fraction, 0), 1))
            }
            .onEnded { _ in
                if let fraction = scrubProgress { player.seek(to: fraction * player.duration) }
                scrubProgress = nil
            }
    }

    private var transport: some View {
        HStack(spacing: 16) {
            terminalButton("<<", label: "Previous", width: 64) { player.previous() }
            Button {
                Haptics.shared.play(.press)
                player.togglePlayPause()
            } label: {
                Text(player.isPlaying ? "PAUSE" : "PLAY")
                    .font(.shareTechMono(20))
                    .foregroundStyle(CodeRainPalette.background)
                    .frame(width: 104, height: 52)
                    .background(CodeRainPalette.green)
            }
            .buttonStyle(TerminalPressStyle())
            .accessibilityLabel(player.isPlaying ? "Pause" : "Play")
            terminalButton(">>", label: "Next", width: 64) { player.next() }
        }
    }

    private func terminalButton(_ title: String, label: String, width: CGFloat, action: @escaping () -> Void) -> some View {
        Button {
            Haptics.shared.play(.tap)
            action()
        } label: {
            Text(title)
                .font(.shareTechMono(18))
                .frame(width: width, height: 52)
                .overlay(Rectangle().strokeBorder(CodeRainPalette.green, lineWidth: 1))
                .contentShape(Rectangle())
        }
        .buttonStyle(TerminalPressStyle())
        .accessibilityLabel(label)
    }

    private var presetGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 3), spacing: 6) {
            ForEach(AudioPreset.allCases) { preset in
                let isSelected = player.preset == preset
                Button {
                    Haptics.shared.play(.tap)
                    player.setPreset(isSelected ? nil : preset)
                } label: {
                    Text("> \(preset.terminalLabel)")
                        .font(.shareTechMono(14))
                        .foregroundStyle(isSelected ? CodeRainPalette.background : CodeRainPalette.green)
                        .lineLimit(1)
                        .padding(.horizontal, 10)
                        .frame(maxWidth: .infinity, minHeight: 44, maxHeight: 44, alignment: .leading)
                        .background(isSelected ? CodeRainPalette.green : CodeRainPalette.background)
                        .overlay(Rectangle().strokeBorder(CodeRainPalette.midGreen, lineWidth: 1))
                        .contentShape(Rectangle())
                }
                .buttonStyle(TerminalPressStyle())
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            }
        }
        .animation(.easeOut(duration: 0.12), value: player.preset)
    }
}

/// Pressed state: dim the button like a terminal cursor blink.
private struct TerminalPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.opacity(configuration.isPressed ? 0.6 : 1)
    }
}
