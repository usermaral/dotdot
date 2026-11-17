//
//  PixelTaskbar.swift
//  dotdot
//
//  Created by Maral on 17.11.2026.
//

import SwiftUI

/// Bottom taskbar: "dotdot" start button (decorative; the menu lives in the title bar),
/// task field with the track title, clock.
struct PixelTaskbar: View {
    @Environment(PlayerModel.self) private var player

    var body: some View {
        HStack(spacing: 6) {
            startMenu
            Text(player.currentTrack?.title ?? "No track")
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 8)
                .frame(height: 28)
                .win98Bevel(.sunken, fill: PixelPalette.field)
            TimelineView(.everyMinute) { context in
                Text(Self.clockFormatter.string(from: context.date))
                    .padding(.horizontal, 8)
                    .frame(height: 30)
                    .win98Bevel(.etched, width: 1)
            }
        }
        .font(.pixelify(14))
        .foregroundStyle(.black)
        .padding(.horizontal, 6)
        .frame(height: 44)
        .frame(maxWidth: .infinity)
        .background(alignment: .top) {
            VStack(spacing: 0) {
                PixelPalette.highlight.frame(height: 2)
                PixelPalette.face
            }
            .ignoresSafeArea(edges: .bottom)
        }
        .padding(.top, 2)
    }

    /// Always "3:09 PM", like the mockup. POSIX locale ignores the device 24-hour setting.
    private static let clockFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "h:mm a"
        return formatter
    }()

    private var startMenu: some View {
        Text("dotdot")
            .font(.pixelify(15, semibold: true))
            .foregroundStyle(.black)
            .padding(.horizontal, 12)
            .frame(height: 32)
            .win98Bevel(.raised, fill: PixelPalette.face)
            .accessibilityHidden(true)
    }
}
