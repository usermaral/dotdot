//
//  PlayerDebugView.swift
//  dotdot
//
//  Created by Maral on 17.11.2026.
//

import SwiftUI
import UniformTypeIdentifiers

/// Bare-bones screen to exercise import, transport and presets. Not part of the shipped UI.
struct PlayerDebugView: View {
    @Environment(PlayerModel.self) private var player
    @AppStorage(PlayerSkin.storageKey) private var skin: PlayerSkin = .pixelDesktop
    @State private var isImporting = false
    @State private var scrubTime: TimeInterval?

    var body: some View {
        NavigationStack {
            List {
                nowPlayingSection
                spectrumSection
                presetSection
                librarySection
                skinSection
            }
            .navigationTitle("dotdot debug")
            .toolbar {
                Button("Import", systemImage: "plus") { isImporting = true }
            }
            .fileImporter(isPresented: $isImporting, allowedContentTypes: [.audio], allowsMultipleSelection: true) { result in
                switch result {
                case .success(let urls): Task { await player.importFiles(urls) }
                case .failure(let error): player.errorMessage = error.localizedDescription
                }
            }
            .alert("Error", isPresented: errorBinding) {
                Button("OK") {}
            } message: {
                Text(player.errorMessage ?? "")
            }
        }
    }

    private var nowPlayingSection: some View {
        Section("Now playing") {
            Text(player.currentTrack?.title ?? "No track — import a file")
                .font(.headline)
            Slider(
                value: Binding(get: { scrubTime ?? player.currentTime }, set: { scrubTime = $0 }),
                in: 0...max(player.duration, 0.1)
            ) { isEditing in
                if !isEditing, let time = scrubTime {
                    player.seek(to: time)
                    scrubTime = nil
                }
            }
            .disabled(player.currentTrack == nil)
            HStack {
                Text(TimeFormat.clock(scrubTime ?? player.currentTime))
                Spacer()
                Text(TimeFormat.clock(player.duration))
            }
            .font(.caption.monospacedDigit())
            HStack(spacing: 32) {
                Button("Previous", systemImage: "backward.fill") { player.previous() }
                Button(player.isPlaying ? "Pause" : "Play",
                       systemImage: player.isPlaying ? "pause.fill" : "play.fill") { player.togglePlayPause() }
                Button("Next", systemImage: "forward.fill") { player.next() }
            }
            .labelStyle(.iconOnly)
            .buttonStyle(.borderless)
            .font(.title2)
            .frame(maxWidth: .infinity)
            .disabled(player.tracks.isEmpty)
        }
    }

    private var spectrumSection: some View {
        Section("Spectrum (\(PlayerModel.bandCount) bands)") {
            HStack(alignment: .bottom, spacing: 3) {
                ForEach(player.bands.indices, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(.tint)
                        .frame(height: max(2, CGFloat(player.bands[index]) * 80))
                        .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 80, alignment: .bottom)
        }
    }

    private var presetSection: some View {
        Section("Preset") {
            presetRow(title: "off", preset: nil)
            ForEach(AudioPreset.allCases) { presetRow(title: $0.title, preset: $0) }
        }
    }

    private func presetRow(title: String, preset: AudioPreset?) -> some View {
        Button {
            player.setPreset(preset)
        } label: {
            HStack {
                Text(title)
                Spacer()
                if player.preset == preset { Image(systemName: "checkmark") }
            }
        }
    }

    private var librarySection: some View {
        Section("Library (\(player.tracks.count))") {
            ForEach(player.tracks) { track in
                Button { player.select(track) } label: {
                    HStack {
                        Text(track.title)
                        Spacer()
                        if track == player.currentTrack { Image(systemName: "speaker.wave.2.fill") }
                    }
                }
            }
        }
    }

    private var skinSection: some View {
        Section("Skin") {
            Picker("Skin", selection: $skin) {
                ForEach(PlayerSkin.allCases) { Text($0.title).tag($0) }
            }
            NavigationLink("Open skin preview") { SkinHost() }
        }
    }

    private var errorBinding: Binding<Bool> {
        Binding(get: { player.errorMessage != nil }, set: { if !$0 { player.errorMessage = nil } })
    }
}
