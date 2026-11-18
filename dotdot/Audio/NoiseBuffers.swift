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

    private static func makeBuffer(format: AVAudioFormat, seconds: Double) -> AVAudioPCMBuffer? {
        let capacity = AVAudioFrameCount(format.sampleRate * seconds)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: capacity) else { return nil }
        buffer.frameLength = capacity
        return buffer
    }
}
