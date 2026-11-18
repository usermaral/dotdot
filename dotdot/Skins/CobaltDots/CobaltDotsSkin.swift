//
//  CobaltDotsSkin.swift
//  dotdot
//
//  Created by Maral on 17.11.2026.
//

import SwiftUI

/// Cobalt v2 skin: white ink on cobalt, a tilted dot-matrix card that visualizes the music.
/// Follows skin-cobalt-v2.html. The "•••" button opens the menu.
struct CobaltDotsSkin: View {
    @Environment(PlayerModel.self) private var player
    @State private var isImporting = false
    @State private var scrubProgress: Double?
    @State private var progressWidth: CGFloat = 1

    var body: some View {
        VStack(spacing: 0) {
            header
            CobaltArtView(isPlaying: player.isPlaying)
                .aspectRatio(1, contentMode: .fit)
                .frame(maxWidth: 342, maxHeight: 342)
                .overlay(alignment: .topTrailing) { star }
                .frame(maxWidth: .infinity)
                .padding(.top, 16)
                .layoutPriority(1)
            trackInfo.padding(.top, 24)
            progress.padding(.top, 24)
            transport.padding(.top, 16)
            Spacer(minLength: 16)
            presets
        }
        .padding(EdgeInsets(top: 8, leading: 24, bottom: 24, trailing: 24))
        .font(.spaceMono(12))
        .foregroundStyle(CobaltPalette.ink)
        .background(CobaltPalette.background.ignoresSafeArea())
        .skinChrome(isImporting: $isImporting)
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            // Yellowtail's final "t" overhangs its advance width and Text clips it;
            // a trailing no-break space widens the drawn bounds.
            Text("dotdot\u{00A0}")
                .font(.yellowtail(40))
            Spacer()
            SkinMenuButton(isImporting: $isImporting) {
                HStack(spacing: 3.5) {
                    ForEach(0..<3, id: \.self) { _ in
                        Circle().fill(CobaltPalette.ink).frame(width: 3.4, height: 3.4)
                    }
                }
                .frame(width: 44, height: 44)
                .overlay(Circle().strokeBorder(CobaltPalette.ink.opacity(0.75), lineWidth: 1.5))
                .contentShape(Circle())
            }
        }
        .frame(height: 48)
    }

    // MARK: - Star sticker (pinned to the art's top-right corner)

    private var star: some View {
        LiveBands { bands in
            StarSticker()
                .stroke(CobaltPalette.accent, style: StrokeStyle(lineWidth: 1.5 * 48 / 24, lineJoin: .round))
                .frame(width: 48, height: 48)
                .rotationEffect(.degrees(14))
                .scaleEffect(1 + 0.12 * Double(bands.first ?? 0))
        }
            .offset(x: 10, y: -18)
            .accessibilityHidden(true)
            .allowsHitTesting(false)
    }

    // MARK: - Track info

    private var trackInfo: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(player.currentTrack?.title ?? "No track")
                .font(.spaceMono(26, bold: true))
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            HStack(spacing: 0) {
                Text(player.currentTrack == nil ? "OPEN MUSIC FROM ••• · " : "LOCAL FILE · ")
                Text(player.preset?.stickerLabel ?? "NO FX").foregroundStyle(CobaltPalette.accent)
            }
                .font(.spaceMono(12))
                .tracking(12 * 0.08)
                .foregroundStyle(CobaltPalette.soft)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Progress: 38 dots, the head one larger

    private var progress: some View {
        let shown = min(max(scrubProgress ?? player.progress, 0), 1)
        return VStack(spacing: 8) {
            Canvas { context, size in
                let count = 38
                let head = Int((Double(count) * shown).rounded())
                let pitch = (size.width - 5) / CGFloat(count - 1)
                for i in 0..<count {
                    let radius: CGFloat = i == head ? 5 : 2.5
                    let x = 2.5 + CGFloat(i) * pitch
                    let rect = CGRect(x: x - radius, y: size.height / 2 - radius, width: radius * 2, height: radius * 2)
                    context.fill(Path(ellipseIn: rect),
                                 with: .color(i <= head ? CobaltPalette.ink : CobaltPalette.ink.opacity(0.3)))
                }
            }
            .frame(height: 10)
            .padding(.vertical, 8) // easier to grab
            .contentShape(Rectangle())
            .gesture(seekGesture)
            .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { progressWidth = max($0, 1) }
            .padding(.vertical, -8)
            HStack {
                Text(TimeFormat.lcd(player.currentTime))
                Spacer()
                Text("-" + TimeFormat.lcd(max(player.duration - player.currentTime, 0)))
            }
            .font(.spaceMono(12))
            .foregroundStyle(CobaltPalette.soft)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Position")
        .accessibilityValue("\(TimeFormat.clock(player.currentTime)) of \(TimeFormat.clock(player.duration))")
    }

    private var seekGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { scrubProgress = Double(min(max($0.location.x / progressWidth, 0), 1)) }
            .onEnded { _ in
                if let fraction = scrubProgress { player.seek(to: fraction * player.duration) }
                scrubProgress = nil
            }
    }

    // MARK: - Transport

    private var transport: some View {
        HStack(spacing: 32) {
            roundButton(.previous, label: "Previous") { player.previous() }
            Button {
                Haptics.shared.play(.press)
                player.togglePlayPause()
            } label: {
                TransportIconShape(icon: player.isPlaying ? .pause : .play)
                    .stroke(CobaltPalette.background,
                            style: StrokeStyle(lineWidth: 2.4 * 28 / 24, lineCap: .round, lineJoin: .round))
                    .frame(width: 28, height: 28)
                    .frame(width: 88, height: 88)
                    .background(Circle().fill(CobaltPalette.ink))
                    .frame(width: 104, height: 104)
                    // Outer ring; breathes slightly with the bass.
                    .overlay(
                        LiveBands { bands in
                            Circle()
                                .strokeBorder(CobaltPalette.ink.opacity(0.4), lineWidth: 1.5)
                                .scaleEffect(1 + 0.08 * Double(bands.first ?? 0))
                        }
                    )
                    .contentShape(Circle())
            }
            .buttonStyle(PressStyle())
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
                .stroke(CobaltPalette.ink, style: StrokeStyle(lineWidth: 1.8 * 20 / 24, lineJoin: .round))
                .frame(width: 20, height: 20)
                .frame(width: 56, height: 56)
                .overlay(Circle().strokeBorder(CobaltPalette.ink.opacity(0.75), lineWidth: 1.5))
                .contentShape(Circle())
        }
        .buttonStyle(PressStyle())
        .accessibilityLabel(label)
    }

    // MARK: - Presets: 3 x 2 grid

    private var presets: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
            ForEach(AudioPreset.allCases) { preset in
                let isSelected = player.preset == preset
                Button {
                    Haptics.shared.play(.tap)
                    player.setPreset(isSelected ? nil : preset)
                } label: {
                    Text(preset.stickerLabel)
                        .font(.spaceMono(12, bold: true))
                        .tracking(12 * 0.06)
                        .foregroundStyle(isSelected ? CobaltPalette.background : CobaltPalette.soft)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, minHeight: 44, maxHeight: 44)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(isSelected ? CobaltPalette.ink : CobaltPalette.ink.opacity(0.1))
                        )
                        .contentShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(PressStyle())
                .accessibilityLabel(preset.title)
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            }
        }
        .animation(.easeOut(duration: 0.15), value: player.preset)
    }
}

/// Pressed state: a quick squash.
private struct PressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}
