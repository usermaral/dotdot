//
//  NoiseBuffers.swift
//  dotdot
//
//  Created by Maral on 17.11.2026.
//

import AVFoundation

/// Procedurally generated loopable noise layers (no bundled audio assets needed).
nonisolated enum NoiseBuffers {
    /// Soft tape hiss: low-passed white noise.
    static func hiss(format: AVAudioFormat, seconds: Double = 3) -> AVAudioPCMBuffer? {
        guard let buffer = makeBuffer(format: format, seconds: seconds),
              let channels = buffer.floatChannelData else { return nil }
        let frames = Int(buffer.frameLength)
        for channel in 0..<Int(format.channelCount) {
            let data = channels[channel]
            var smoothed: Float = 0
            for i in 0..<frames {
                smoothed += 0.35 * (Float.random(in: -1...1) - smoothed)
                data[i] = smoothed * 0.05
            }
        }
        return buffer
    }

    /// Vinyl crackle: sparse decaying pops over a faint rumble.
    static func crackle(format: AVAudioFormat, seconds: Double = 4) -> AVAudioPCMBuffer? {
        guard let buffer = makeBuffer(format: format, seconds: seconds),
              let channels = buffer.floatChannelData else { return nil }
        let frames = Int(buffer.frameLength)
        let sampleRate = Float(format.sampleRate)
        let popsPerSecond: Float = 9
        let popProbability = popsPerSecond / sampleRate
        let decay = expf(-1 / (0.0015 * sampleRate)) // ~1.5 ms pop tail

        var mono = [Float](repeating: 0, count: frames)
        var rumble: Float = 0
        var pop: Float = 0
        for i in 0..<frames {
            if Float.random(in: 0..<1) < popProbability {
                let strength = Float.random(in: 0.05...0.35)
                pop = Bool.random() ? strength : -strength
            }
            pop *= decay
            rumble += 0.01 * (Float.random(in: -1...1) - rumble)
            mono[i] = pop + rumble * 0.08
        }
        for channel in 0..<Int(format.channelCount) {
            let data = channels[channel]
            for i in 0..<frames { data[i] = mono[i] }
        }
        return buffer
    }

    private static func makeBuffer(format: AVAudioFormat, seconds: Double) -> AVAudioPCMBuffer? {
        let capacity = AVAudioFrameCount(format.sampleRate * seconds)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: capacity) else { return nil }
        buffer.frameLength = capacity
        return buffer
    }
}
