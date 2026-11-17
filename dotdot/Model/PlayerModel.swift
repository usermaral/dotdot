//
//  PlayerModel.swift
//  dotdot
//
//  Created by Maral on 17.11.2026.
//

import AVFoundation
import Observation

/// Single source of truth for every skin. Skins only read this state and call its methods.
@Observable
final class PlayerModel {
    static let bandCount = 16
    private static let attack: Float = 0.55
    private static let release: Float = 0.12

    private(set) var tracks: [Track] = []
    private(set) var currentTrack: Track?
    private(set) var isPlaying = false
    private(set) var currentTime: TimeInterval = 0
    private(set) var duration: TimeInterval = 0
    private(set) var preset: AudioPreset?
    /// 16 spectrum bands, 0...1, smoothed, updated ~60 times/sec while playing.
    private(set) var bands = [Float](repeating: 0, count: PlayerModel.bandCount)
    var errorMessage: String?

    @ObservationIgnored private let engine: AudioEngine
    @ObservationIgnored private var displayTask: Task<Void, Never>?

    init() {
        Self.configureAudioSession()
        engine = AudioEngine()
        engine.onTrackFinished = { [weak self] in self?.trackFinished() }
        tracks = TrackLibrary.loadTracks()
    }

    var progress: Double {
        duration > 0 ? currentTime / duration : 0
    }

    // MARK: - Library

    func importFiles(_ urls: [URL]) async {
        for url in urls {
            do {
                let track = try await Task.detached { try TrackLibrary.importFile(at: url) }.value
                if !tracks.contains(track) { tracks.append(track) }
                if currentTrack == nil { load(track, autoplay: false) }
            } catch {
                errorMessage = "Import failed: \(error.localizedDescription)"
            }
        }
    }

    func select(_ track: Track) {
        load(track, autoplay: true)
    }

    func next() {
        guard let index = currentIndex, !tracks.isEmpty else { return }
        load(tracks[(index + 1) % tracks.count], autoplay: isPlaying)
    }

    func previous() {
        if currentTime > 3 { seek(to: 0); return }
        guard let index = currentIndex, !tracks.isEmpty else { return }
        load(tracks[(index - 1 + tracks.count) % tracks.count], autoplay: isPlaying)
    }

    // MARK: - Transport

    func togglePlayPause() {
        isPlaying ? pause() : play()
    }

    func play() {
        if currentTrack == nil, let first = tracks.first {
            load(first, autoplay: true)
            return
        }
        do {
            try engine.play()
            syncState()
            startDisplayLoop()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func pause() {
        engine.pause()
        syncState() // display loop keeps running until the bars have fallen
    }

    func seek(to time: TimeInterval) {
        engine.seek(to: time)
        syncState()
    }

    func setPreset(_ preset: AudioPreset?) {
        engine.apply(preset: preset)
        self.preset = engine.preset
    }

    // MARK: - Private

    private var currentIndex: Int? {
        currentTrack.flatMap { tracks.firstIndex(of: $0) }
    }

    private func load(_ track: Track, autoplay: Bool) {
        do {
            try engine.load(url: track.url)
            currentTrack = track
            syncState()
            if autoplay { play() }
        } catch {
            errorMessage = "Cannot open \(track.title): \(error.localizedDescription)"
        }
    }

    private func trackFinished() {
        syncState()
        if tracks.count > 1 {
            next()
            play()
        }
    }

    private func syncState() {
        isPlaying = engine.isPlaying
        currentTime = engine.currentTime
        duration = engine.duration
    }

    /// ~60 fps loop: playback time + smoothed spectrum. Stops itself once paused and silent.
    private func startDisplayLoop() {
        guard displayTask == nil else { return }
        displayTask = Task { [weak self] in
            while let self, !Task.isCancelled, self.tick() {
                try? await Task.sleep(for: .milliseconds(16))
            }
            self?.displayTask = nil
        }
    }

    /// Returns false when there is nothing left to animate.
    private func tick() -> Bool {
        currentTime = engine.currentTime
        let target = engine.spectrum
        var smoothed = bands
        for i in smoothed.indices {
            // Fast attack, slow release: punchy but readable bars.
            let k: Float = target[i] > smoothed[i] ? Self.attack : Self.release
            smoothed[i] += (target[i] - smoothed[i]) * k
        }
        let isSilent = smoothed.allSatisfy { $0 < 0.002 }
        bands = isSilent && !isPlaying ? [Float](repeating: 0, count: Self.bandCount) : smoothed
        return isPlaying || !isSilent
    }

    private static func configureAudioSession() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playback, mode: .default)
            try session.setActive(true)
        } catch {
            print("Audio session setup failed: \(error)")
        }
    }
}
