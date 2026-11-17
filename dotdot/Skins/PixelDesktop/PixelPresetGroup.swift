//
//  PixelPresetGroup.swift
//  dotdot
//
//  Created by Maral on 17.11.2026.
//

import SwiftUI

/// "Sound effects" group box with Win98 radio buttons, two columns.
/// Tapping the selected preset again turns effects off.
struct PixelPresetGroup: View {
    @Environment(PlayerModel.self) private var player

    private let columns = [GridItem(.flexible(), spacing: 2), GridItem(.flexible(), spacing: 2)]

    var body: some View {
        LazyVGrid(columns: columns, alignment: .leading, spacing: 2) {
            ForEach(AudioPreset.allCases) { preset in
                radio(for: preset)
            }
        }
        .padding(EdgeInsets(top: 12, leading: 10, bottom: 8, trailing: 10))
        .win98Bevel(.etched)
        .overlay(alignment: .topLeading) {
            Text("Sound effects")
                .font(.pixelify(14))
                .padding(.horizontal, 4)
                .background(PixelPalette.face)
                .offset(x: 10, y: -9)
        }
    }

    private func radio(for preset: AudioPreset) -> some View {
        let isSelected = player.preset == preset
        return Button {
            Haptics.shared.play(.tap)
            player.setPreset(isSelected ? nil : preset)
        } label: {
            HStack(spacing: 8) {
                Circle()
                    .fill(isSelected ? Color.black : .clear)
                    .frame(width: 6, height: 6)
                    .frame(width: 10, height: 10)
                    .win98CircleBevel(.sunken, width: 2, fill: .white)
                    .frame(width: 14, height: 14)
                Text(Self.label(for: preset))
                    .font(.pixelify(15))
                Spacer(minLength: 0)
            }
            .frame(height: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    /// Mockup capitalization: "Slowed", "Sped up", "8D".
    static func label(for preset: AudioPreset) -> String {
        preset.title.prefix(1).uppercased() + preset.title.dropFirst()
    }
}
