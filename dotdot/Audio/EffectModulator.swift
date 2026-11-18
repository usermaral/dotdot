//
//  EffectModulator.swift
//  dotdot
//
//  Created by Maral on 18.11.2026.
//

import AVFoundation

/// Drives time-based effects (tape wow/flutter, 8D orbit) from a high-priority background
/// timer. Running this on the main thread made the effects stutter whenever the UI was busy
/// (scrolling, gestures, skin animations).
nonisolated final class EffectModulator: @unchecked Sendable {
    enum Mode: Sendable {
        case tape
        case orbit
    }

    private let queue = DispatchQueue(label: "dotdot.effect-modulator", qos: .userInteractive)
    private let varispeed: AVAudioUnitVarispeed
    private let spatialMixer: AVAudioMixerNode
    /// Only touched on `queue`.
    private var timer: DispatchSourceTimer?

    init(varispeed: AVAudioUnitVarispeed, spatialMixer: AVAudioMixerNode) {
        self.varispeed = varispeed
        self.spatialMixer = spatialMixer
    }

    func start(_ mode: Mode) {
        queue.sync {
            timer?.cancel()
            let start = DispatchTime.now().uptimeNanoseconds
            let source = DispatchSource.makeTimerSource(queue: queue)
            source.schedule(deadline: .now(), repeating: .milliseconds(10), leeway: .milliseconds(1))
            source.setEventHandler { [unowned self] in
                let seconds = Double(DispatchTime.now().uptimeNanoseconds - start) / 1_000_000_000
                apply(mode, at: seconds)
            }
            source.resume()
            timer = source
        }
    }

    /// Synchronous, so a late tick can't overwrite the values reset right after stopping.
    func stop() {
        queue.sync {
            timer?.cancel()
            timer = nil
        }
    }

    private func apply(_ mode: Mode, at t: Double) {
        switch mode {
        case .tape:
            // ±0.5% wow (slow) with a touch of flutter (fast).
            let wow = 0.004 * sin(2 * .pi * 0.55 * t)
            let flutter = 0.001 * sin(2 * .pi * 6.0 * t)
            varispeed.rate = Float(1 + wow + flutter)
        case .orbit:
            let angle = 2 * .pi * t / 8 // one orbit per 8 s
            let radius = 2.0
            spatialMixer.position = AVAudio3DPoint(
                x: Float(radius * sin(angle)),
                y: 0,
                z: Float(-radius * cos(angle))
            )
        }
    }
}
