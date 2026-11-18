//
//  AsciiPrintSkin.swift
//  dotdot
//
//  Created by Maral on 18.11.2026.
//

import SwiftUI

/// Light "till receipt" skin (skin-receipt-v2.html): the cover typed out as ASCII art on a
/// white receipt with zigzag edges, dotted-leader track info and checkbox presets.
/// The "[menu]" button (top right) opens the dotdot menu.
struct AsciiPrintSkin: View {
    @Environment(PlayerModel.self) private var player
    @State private var isImporting = false
    @State private var scrubProgress: Double?
    @State private var barWidth: CGFloat = 1

    /// Receipt date: the day the skin was opened.
    private static let printDate: String = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "dd.MM.yyyy"
        return formatter.string(from: .now)
    }()

    var body: some View {
        VStack(spacing: 16) {
            header
            receipt
        }
        .padding(EdgeInsets(top: 8, leading: 24, bottom: 16, trailing: 24))
        .font(.spaceMono(12))
        .foregroundStyle(AsciiPalette.ink)
        .background(AsciiPalette.background.ignoresSafeArea())
        .skinChrome(isImporting: $isImporting)
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .firstTextBaseline, spacing: 0) {
            Text("dotdot")
                .font(.spaceMono(24, bold: true))
            Text(" /ascii print")
                .font(.spaceMono(12))
                .foregroundStyle(AsciiPalette.softInk)
            Spacer()
            SkinMenuButton(isImporting: $isImporting) {
                Text("[menu]")
                    .font(.spaceMono(14, bold: true))
                    .foregroundStyle(AsciiPalette.ink)
                    .padding(.horizontal, 4)
                    .frame(height: 44)
                    .contentShape(Rectangle())
            }
        }
        .frame(height: 44)
    }

    // MARK: - Receipt

    private var receipt: some View {
        VStack(spacing: 0) {
            ZigzagEdge(pointsUp: true).fill(AsciiPalette.paper).frame(height: 10)
            VStack(spacing: 12) {
                receiptHeader
                rule
                AsciiArtView(trackURL: player.currentTrack?.url, bands: player.bands, isPlaying: player.isPlaying)
                    .frame(maxWidth: .infinity, minHeight: 80, maxHeight: 220)
                    .layoutPriority(1)
                rule
                lineItems
                rule
                transport
                presets
                Spacer(minLength: 0)
                rule
                footer
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 20)
            .frame(maxHeight: .infinity)
            .background(AsciiPalette.paper)
            ZigzagEdge(pointsUp: false).fill(AsciiPalette.paper).frame(height: 10)
        }
    }

    private var receiptHeader: some View {
        VStack(spacing: 2) {
            Text("DOTDOT AUDIO")
                .font(.spaceMono(12, bold: true))
                .tracking(12 * 0.2)
            Text("print no. \(String(format: "%04d", player.trackNumber ?? 0)) · \(Self.printDate)")
                .foregroundStyle(AsciiPalette.softInk)
        }
        .frame(maxWidth: .infinity)
    }

    private var footer: some View {
        VStack(spacing: 2) {
            Text("THANK YOU FOR LISTENING")
                .font(.spaceMono(12, bold: true))
                .tracking(12 * 0.12)
            Text("* * * dotdot * * *")
                .foregroundStyle(AsciiPalette.softInk)
        }
        .frame(maxWidth: .infinity)
        .accessibilityHidden(true)
    }

    /// Dashed rule across the receipt.
    private var rule: some View {
        Line()
            .stroke(AsciiPalette.ink, style: StrokeStyle(lineWidth: 1.5, dash: [4.5, 3]))
            .frame(height: 1.5)
            .accessibilityHidden(true)
    }

    // MARK: - Line items: TRACK ........ Night Drive

    private var lineItems: some View {
        VStack(alignment: .leading, spacing: 6) {
            leaderRow("TRACK", player.currentTrack?.title ?? "open from [menu]")
            leaderRow("FX", player.preset?.receiptLabel ?? "none")
            leaderRow("TIME", "\(TimeFormat.lcd(player.currentTime)) / \(TimeFormat.lcd(player.duration))")
            progressBar
        }
    }

    private func leaderRow(_ label: String, _ value: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            Text(label)
            Line()
                .stroke(AsciiPalette.leader, style: StrokeStyle(lineWidth: 1.5, lineCap: .round, dash: [0, 3]))
                .frame(height: 1.5)
                .alignmentGuide(.firstTextBaseline) { $0[.bottom] + 3 }
            Text(value)
                .font(.spaceMono(12, bold: true))
                .lineLimit(1)
                .truncationMode(.middle)
                .layoutPriority(1)
        }
        .accessibilityElement(children: .combine)
    }

    // MARK: - Progress: [=====>.......]

    private var progressBar: some View {
        let shown = min(max(scrubProgress ?? player.progress, 0), 1)
        let cells = 28
        let filled = Int((Double(cells) * shown).rounded())
        let bar = "[" + String(repeating: "=", count: filled) + ">" + String(repeating: ".", count: cells - filled) + "]"
        return Text(bar)
            .font(.spaceMono(12, bold: true))
            .lineLimit(1)
            .fixedSize()
            .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { barWidth = max($0, 1) }
            .frame(minHeight: 24)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { scrubProgress = Double(min(max($0.location.x / barWidth, 0), 1)) }
                    .onEnded { _ in
                        if let fraction = scrubProgress { player.seek(to: fraction * player.duration) }
                        scrubProgress = nil
                    }
            )
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Position")
            .accessibilityValue("\(TimeFormat.clock(player.currentTime)) of \(TimeFormat.clock(player.duration))")
    }

    // MARK: - Transport

    private var transport: some View {
        HStack(spacing: 0) {
            textButton("|<<", label: "Previous") { player.previous() }
            Button {
                Haptics.shared.play(.press)
                player.togglePlayPause()
            } label: {
                Text(player.isPlaying ? "[ PAUSE ]" : "[ PLAY ]")
                    .font(.spaceMono(15, bold: true))
                    .tracking(15 * 0.1)
                    .foregroundStyle(AsciiPalette.paper)
                    .frame(maxWidth: .infinity, minHeight: 48, maxHeight: 48)
                    .background(AsciiPalette.ink)
            }
            .buttonStyle(InkPressStyle())
            .accessibilityLabel(player.isPlaying ? "Pause" : "Play")
            textButton(">>|", label: "Next") { player.next() }
        }
    }

    private func textButton(_ title: String, label: String, action: @escaping () -> Void) -> some View {
        Button {
            Haptics.shared.play(.tap)
            action()
        } label: {
            Text(title)
                .font(.spaceMono(16, bold: true))
                .frame(width: 72, height: 48)
                .contentShape(Rectangle())
        }
        .buttonStyle(InkPressStyle())
        .accessibilityLabel(label)
    }

    // MARK: - Presets: [x] slowed

    private var presets: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 3), spacing: 0) {
            ForEach(AudioPreset.allCases) { preset in
                let isSelected = player.preset == preset
                Button {
                    Haptics.shared.play(.tap)
                    player.setPreset(isSelected ? nil : preset)
                } label: {
                    Text("[\(isSelected ? "x" : " ")] \(preset.receiptLabel)")
                        .font(.spaceMono(12, bold: isSelected))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .frame(maxWidth: .infinity, minHeight: 44, maxHeight: 44, alignment: .leading)
                        .contentShape(Rectangle())
                }
                .buttonStyle(InkPressStyle())
                .accessibilityLabel(preset.title)
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            }
        }
    }
}

extension AudioPreset {
    /// Receipt label: "slowed", "sped up", "8d".
    var receiptLabel: String { title.lowercased() }
}

private struct Line: Shape {
    func path(in rect: CGRect) -> Path {
        Path { p in
            p.move(to: CGPoint(x: rect.minX, y: rect.midY))
            p.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        }
    }
}

/// Torn receipt edge: a row of 18 pt-wide teeth (mockup: 19 teeth across 342 pt).
private struct ZigzagEdge: Shape {
    let pointsUp: Bool

    func path(in rect: CGRect) -> Path {
        let teeth = max(Int((rect.width / 18).rounded()), 1)
        let step = rect.width / CGFloat(teeth)
        let base = pointsUp ? rect.maxY : rect.minY
        let tip = pointsUp ? rect.minY : rect.maxY
        return Path { p in
            p.move(to: CGPoint(x: rect.minX, y: base))
            for i in 0..<teeth {
                let x = rect.minX + CGFloat(i) * step
                p.addLine(to: CGPoint(x: x + step / 2, y: tip))
                p.addLine(to: CGPoint(x: x + step, y: base))
            }
            p.closeSubpath()
        }
    }
}

/// Pressed state: ink fades a little, like a light keystroke.
private struct InkPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.opacity(configuration.isPressed ? 0.6 : 1)
    }
}
