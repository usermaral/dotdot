//
//  ArtMotion.swift
//  dotdot
//
//  Created by Maral on 18.11.2026.
//

import Foundation

/// Audio-reactive state for the art-driven skins (Cobalt dots, ASCII Print).
/// Bass breathes the image, each kick launches a ripple from the center,
/// mids sway the grid, highs throw sparkles.
final class ArtMotion {
    private(set) var bass = 0.0
    private(set) var lowMid = 0.0
    private(set) var mid = 0.0
    private(set) var treble = 0.0

    /// Record rotation in radians: 33⅓ rpm while playing, holds still when paused.
    private(set) var spin = 0.0
    private var lastTime: Double?

    private var bassAverage = 0.0
    private var lastKick = 0.0
    private var ripples: [(start: Double, strength: Double)] = []

    static let rippleLife = 1.3

    func update(time t: Double, bands: [Float], isPlaying: Bool) {
        if isPlaying, let lastTime { spin += min(t - lastTime, 0.1) * 2 * .pi * (100.0 / 3 / 60) }
        lastTime = t
        func average(_ range: Range<Int>) -> Double {
            let slice = bands.indices.clamped(to: range)
            guard !slice.isEmpty else { return 0 }
            return Double(slice.reduce(Float(0)) { $0 + bands[$1] }) / Double(slice.count)
        }
        // Paused: slow idle breathing instead of a frozen picture.
        let rawBass = isPlaying ? average(0..<3) : 0.15 + 0.08 * sin(t * 1.4)
        bass += (rawBass - bass) * 0.4
        lowMid += ((isPlaying ? average(3..<6) : 0.1 + 0.06 * sin(t * 1.1 + 1)) - lowMid) * 0.3
        mid += ((isPlaying ? average(4..<10) : 0) - mid) * 0.2
        treble += ((isPlaying ? average(11..<16) : 0) - treble) * 0.3

        if isPlaying, rawBass > bassAverage * 1.18 + 0.06, t - lastKick > 0.22 {
            ripples.append((t, min(1, 0.55 + (rawBass - bassAverage) * 2.5)))
            lastKick = t
        }
        bassAverage += (rawBass - bassAverage) * 0.04
        ripples.removeAll { t - $0.start > Self.rippleLife }
    }

    /// 0...1 ripple intensity at normalized distance `d` from the center (0 = center, ~1.4 = corner).
    func ripple(at d: Double, time t: Double) -> Double {
        var value = 0.0
        for ripple in ripples {
            let age = t - ripple.start
            let offset = d - age * 1.25
            value += ripple.strength * exp(-offset * offset / 0.008) * (1 - age / Self.rippleLife)
        }
        return min(value, 1)
    }
}
