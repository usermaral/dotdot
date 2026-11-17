//
//  CobaltDotsSkin.swift
//  dotdot
//
//  Created by Maral on 17.11.2026.
//

import SwiftUI

/// Built from design/skin-cobalt-dots.html. The "•••" button (top right) opens the menu.
struct CobaltDotsSkin: View {
    @Environment(PlayerModel.self) private var player
    @State private var isImporting = false
    @State private var isShowingDebug = false
    @State private var scrubProgress: Double?

    var body: some View {
        VStack(spacing: 16) {
            header
            CobaltDotMatrix(bands: player.bands, isPlaying: player.isPlaying)
                .frame(maxWidth: 300, maxHeight: 300)
                .aspectRatio(1, contentMode: .fit)
                .frame(maxWidth: .infinity)
                .layoutPriority(1)
            trackInfo
            progress
            transport
            Spacer(minLength: 0)
            presets
        }
        .padding(EdgeInsets(top: 8, leading: 22, bottom: 28, trailing: 22))
        .font(.spaceMono(13))
        .foregroundStyle(CobaltPalette.cobalt)
        .background(alignment: .topLeading) { stickers }
        .background(CobaltPalette.background.ignoresSafeArea())
        .skinChrome(isImporting: $isImporting, isShowingDebug: $isShowingDebug)
    }

    // MARK: - Pieces

    /// Doodles positioned like the mockup (top offsets minus its 44 pt status bar).
    private var stickers: some View {
        ZStack(alignment: .topLeading) {
            StarSticker()
                .stroke(CobaltPalette.cobalt, lineWidth: 1.4 * 44 / 24)
                .frame(width: 44, height: 44)
                .rotationEffect(.degrees(12))
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.trailing, 26)
                .offset(y: 112 - 44)
            HeartSticker()
                .stroke(CobaltPalette.cobalt, lineWidth: 1.4 * 36 / 24)
                .frame(width: 36, height: 36)
                .rotationEffect(.degrees(-14))
                .padding(.leading, 20)
                .offset(y: 440 - 44)
        }
        .accessibilityHidden(true)
        .allowsHitTesting(false)
    }

    private var header: some View {
        HStack {
            // Yellowtail's final "t" overhangs its advance width and Text clips it;
            // a trailing no-break space widens the drawn bounds.
            Text("dotdot\u{00A0}")
                .font(.yellowtail(36))
                .foregroundStyle(CobaltPalette.cobalt)
            Spacer()
            Text(player.isPlaying ? "NOW PLAYING" : "PAUSED")
                .font(.spaceMono(12, bold: true))
                .padding(.vertical, 4)
                .padding(.horizontal, 10)
                .overlay(Capsule().strokeBorder(CobaltPalette.cobalt, lineWidth: 1.5))
            menuButton
        }
    }

    /// Visible way into the dotdot menu: a round "•••" button in the sticker style.
    private var menuButton: some View {
        Menu {
            SkinMenuItems(isImporting: $isImporting, isShowingDebug: $isShowingDebug)
        } label: {
            HStack(spacing: 3) {
                ForEach(0..<3, id: \.self) { _ in
                    Circle().fill(CobaltPalette.cobalt).frame(width: 4, height: 4)
                }
            }
            .frame(width: 32, height: 32)
            .background(Circle().fill(CobaltPalette.background))
            .overlay(Circle().strokeBorder(CobaltPalette.cobalt, lineWidth: 1.5))
            .frame(width: 44, height: 44) // touch target
            .contentShape(Rectangle())
        }
        .simultaneousGesture(TapGesture().onEnded { Haptics.shared.play(.tap) })
        .accessibilityLabel("Menu: skins and music")
    }

    private var trackInfo: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(player.currentTrack?.title ?? "No track")
                .font(.spaceMono(24, bold: true))
                .lineLimit(1)
            Text(subtitle)
                .font(.spaceMono(13))
                .foregroundStyle(CobaltPalette.softCobalt)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var subtitle: String {
        let fx = player.preset?.stickerLabel ?? "NO FX"
        guard let track = player.currentTrack else { return "open music from ••• · \(fx)" }
        return "\(track.url.lastPathComponent) · \(fx)"
    }

    private var progress: some View {
        let shown = min(max(scrubProgress ?? player.progress, 0), 1)
        return VStack(spacing: 6) {
            GeometryReader { geo in
                Capsule()
                    .fill(CobaltPalette.cobalt)
                    .frame(width: geo.size.width * shown)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { scrubProgress = Double(min(max($0.location.x / geo.size.width, 0), 1)) }
                            .onEnded { _ in
                                if let fraction = scrubProgress { player.seek(to: fraction * player.duration) }
                                scrubProgress = nil
                            }
                    )
            }
            .frame(height: 10)
            .clipShape(Capsule())
            .overlay(Capsule().strokeBorder(CobaltPalette.cobalt, lineWidth: 1.5))
            HStack {
                Text(TimeFormat.lcd(player.currentTime))
                Spacer()
                Text("-" + TimeFormat.lcd(max(player.duration - player.currentTime, 0)))
            }
            .font(.spaceMono(12))
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Position")
        .accessibilityValue("\(TimeFormat.clock(player.currentTime)) of \(TimeFormat.clock(player.duration))")
    }

    private var transport: some View {
        HStack(spacing: 22) {
            roundButton(.previous, label: "Previous") { player.previous() }
            Button {
                Haptics.shared.play(.press)
                player.togglePlayPause()
            } label: {
                TransportIconShape(icon: player.isPlaying ? .pause : .play)
                    .stroke(.white, style: StrokeStyle(lineWidth: 2.2 * 32 / 24))
                    .frame(width: 32, height: 32)
                    .frame(width: 84, height: 84)
                    .background(Circle().fill(CobaltPalette.cobalt))
            }
            .buttonStyle(StickerPressStyle())
            .accessibilityLabel(player.isPlaying ? "Pause" : "Play")
            roundButton(.next, label: "Next") { player.next() }
        }
    }

    private func roundButton(_ icon: TransportIcon, label: String, action: @escaping () -> Void) -> some View {
        Button {
            Haptics.shared.play(.tap)
            action()
        } label: {
            TransportIconShape(icon: icon)
                .stroke(CobaltPalette.cobalt, style: StrokeStyle(lineWidth: 2 * 22 / 24))
                .frame(width: 22, height: 22)
                .frame(width: 56, height: 56)
                .background(Circle().fill(CobaltPalette.background))
                .overlay(Circle().strokeBorder(CobaltPalette.cobalt, lineWidth: 1.5))
        }
        .buttonStyle(StickerPressStyle())
        .accessibilityLabel(label)
    }

    private var presets: some View {
        FlowLayout(spacing: 8) {
            ForEach(AudioPreset.allCases) { preset in
                let isSelected = player.preset == preset
                Button {
                    Haptics.shared.play(.tap)
                    player.setPreset(isSelected ? nil : preset)
                } label: {
                    Text(preset.stickerLabel)
                        .font(.spaceMono(12, bold: true))
                        .foregroundStyle(isSelected ? CobaltPalette.background : CobaltPalette.cobalt)
                        .padding(.horizontal, 14)
                        .frame(height: 44)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(isSelected ? CobaltPalette.cobalt : CobaltPalette.background)
                        )
                        .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(CobaltPalette.cobalt, lineWidth: 1.5))
                }
                .buttonStyle(StickerPressStyle())
                .rotationEffect(.degrees(preset.stickerRotation))
                // Selected sticker "pops" a little.
                .scaleEffect(isSelected ? 1.06 : 1)
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.55), value: player.preset)
    }
}

/// Pressed state: a quick squash, like pressing a sticker.
private struct StickerPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}
