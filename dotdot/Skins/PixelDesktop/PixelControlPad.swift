//
//  PixelControlPad.swift
//  dotdot
//
//  Created by Maral on 17.11.2026.
//

import SwiftUI

/// 210 pt round beveled pad: VOL+ / prev / play / next / VOL-, each with a haptic click.
struct PixelControlPad: View {
    @Environment(PlayerModel.self) private var player

    private let volumeStep: Float = 0.1

    var body: some View {
        Grid(horizontalSpacing: 0, verticalSpacing: 0) {
            GridRow {
                Color.clear
                padButton("VOL+", size: 15, label: "Volume up") { player.changeVolume(by: volumeStep) }
                Color.clear
            }
            GridRow {
                padButton("|<<", size: 18, label: "Previous") { player.previous() }
                playButton
                padButton(">>|", size: 18, label: "Next") { player.next() }
            }
            GridRow {
                Color.clear
                padButton("VOL-", size: 15, label: "Volume down") { player.changeVolume(by: -volumeStep) }
                Color.clear
            }
        }
        .frame(width: 204, height: 204) // 210 minus the 3 pt border on each side
        .win98CircleBevel(.raised, width: 3, fill: PixelPalette.padFace)
        .frame(width: 210, height: 210)
        .foregroundStyle(.black)
    }

    private var playButton: some View {
        Button {
            Haptics.shared.play(.press)
            player.togglePlayPause()
        } label: {
            Text(player.isPlaying ? "||" : ">")
                .font(.pixelify(22, semibold: true))
                .frame(width: 72, height: 72)
                .win98CircleBevel(.raised, width: 3, fill: PixelPalette.face)
        }
        .buttonStyle(PixelPressStyle())
        .accessibilityLabel(player.isPlaying ? "Pause" : "Play")
    }

    private func padButton(_ title: String, size: CGFloat, label: String, action: @escaping () -> Void) -> some View {
        Button {
            Haptics.shared.play(.tap)
            action()
        } label: {
            Text(title)
                .font(.pixelify(size, semibold: true))
                .frame(minWidth: 48, minHeight: 48)
                .contentShape(Rectangle())
        }
        .buttonStyle(PixelPressStyle())
        .accessibilityLabel(label)
    }
}

/// Pressed state: content nudges 1 pt down-right, like a Win98 button.
struct PixelPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .offset(x: configuration.isPressed ? 1 : 0, y: configuration.isPressed ? 1 : 0)
    }
}
