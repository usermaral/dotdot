//
//  SpectrumAnalyzer.swift
//  dotdot
//
//  Created by Maral on 17.11.2026.
//

import Accelerate
import AVFoundation
import os

/// Turns audio buffers into `bandCount` log-spaced levels (0...1) with vDSP.
///
/// `process(_:)` runs on the audio tap thread and reuses preallocated buffers;
/// the latest result is published through a lock and read by the UI loop.
nonisolated final class SpectrumAnalyzer: @unchecked Sendable {
    let bandCount: Int

    private let fftSize: Int
    private let log2n: vDSP_Length
    private let fftSetup: FFTSetup
    private let window: [Float]
    private let sampleRate: Double
    private let bandBins: [Range<Int>]
    private let bandTilt: [Float]

    // Scratch buffers, touched only by the tap thread.
    private var mono: [Float]
    private var real: [Float]
    private var imag: [Float]
    private var power: [Float]

    private let latest: OSAllocatedUnfairLock<[Float]>

    /// Display range in dB (after tilt). Below `floorDB` -> 0, at `ceilingDB` -> 1.
    private let floorDB: Float = -62
    private let ceilingDB: Float = -12

    init(sampleRate: Double, bandCount: Int = 16, fftSize: Int = 2048,
         minFrequency: Double = 40, maxFrequency: Double = 16_000) {
        self.bandCount = bandCount
        self.fftSize = fftSize
        self.sampleRate = sampleRate
        log2n = vDSP_Length(log2(Double(fftSize)))
        fftSetup = vDSP_create_fftsetup(log2n, FFTRadix(kFFTRadix2))!
        window = vDSP.window(ofType: Float.self, usingSequence: .hanningDenormalized, count: fftSize, isHalfWindow: false)

        let half = fftSize / 2
        mono = [Float](repeating: 0, count: fftSize)
        real = [Float](repeating: 0, count: half)
        imag = [Float](repeating: 0, count: half)
        power = [Float](repeating: 0, count: half)
        latest = OSAllocatedUnfairLock(initialState: [Float](repeating: 0, count: bandCount))

        // Log-spaced band edges mapped to FFT bins; each band gets at least one bin.
        let binWidth = sampleRate / Double(fftSize)
        let top = min(maxFrequency, sampleRate / 2)
        let ratio = pow(top / minFrequency, 1 / Double(bandCount))
        var bins: [Range<Int>] = []
        var tilt: [Float] = []
        var lower = max(1, Int(minFrequency / binWidth))
        for band in 0..<bandCount {
            let edgeHigh = minFrequency * pow(ratio, Double(band + 1))
            let upper = min(half, max(lower + 1, Int(edgeHigh / binWidth)))
            bins.append(lower..<upper)
            // Music energy falls ~3 dB/octave; lift highs so the bars look balanced.
            let center = minFrequency * pow(ratio, Double(band) + 0.5)
            tilt.append(Float(3 * log2(center / 1_000)))
            lower = upper
        }
        bandBins = bins
        bandTilt = tilt
    }

    deinit {
        vDSP_destroy_fftsetup(fftSetup)
    }

    /// Latest band levels, 0...1. Safe to call from any thread.
    func currentBands() -> [Float] {
        latest.withLock { $0 }
    }

    func reset() {
        latest.withLock { $0 = [Float](repeating: 0, count: bandCount) }
    }

    /// Called from the audio tap thread.
    func process(_ buffer: AVAudioPCMBuffer) {
        guard let channels = buffer.floatChannelData else { return }
        let frames = Int(buffer.frameLength)
        let channelCount = Int(buffer.format.channelCount)
        guard frames > 0, channelCount > 0 else { return }

        // Mix the most recent `fftSize` frames down to mono (zero-padded if short).
        let count = min(frames, fftSize)
        let offset = frames - count
        let gain = 1 / Float(channelCount)
        vDSP.clear(&mono)
        mono.withUnsafeMutableBufferPointer { dst in
            for channel in 0..<channelCount {
                let src = channels[channel] + offset
                vDSP_vsma(src, 1, [gain], dst.baseAddress!, 1, dst.baseAddress!, 1, vDSP_Length(count))
            }
        }
        vDSP.multiply(mono, window, result: &mono)

        // Real FFT (packed split complex), then power per bin.
        let half = fftSize / 2
        real.withUnsafeMutableBufferPointer { realPtr in
            imag.withUnsafeMutableBufferPointer { imagPtr in
                var split = DSPSplitComplex(realp: realPtr.baseAddress!, imagp: imagPtr.baseAddress!)
                mono.withUnsafeBufferPointer { monoPtr in
                    monoPtr.baseAddress!.withMemoryRebound(to: DSPComplex.self, capacity: half) {
                        vDSP_ctoz($0, 2, &split, 1, vDSP_Length(half))
                    }
                }
                vDSP_fft_zrip(fftSetup, &split, 1, log2n, FFTDirection(FFT_FORWARD))
                imagPtr[0] = 0 // packed Nyquist, not a real DC component
                vDSP_zvmags(&split, 1, &power, 1, vDSP_Length(half))
            }
        }

        // A full-scale sine through a Hann window peaks at (fftSize / 2)^2 here -> 0 dB.
        let reference = Float(fftSize * fftSize) / 4
        var bands = [Float](repeating: 0, count: bandCount)
        for band in 0..<bandCount {
            var peak: Float = 0
            for bin in bandBins[band] where power[bin] > peak { peak = power[bin] }
            let db = 10 * log10f(peak / reference + 1e-12) + bandTilt[band]
            bands[band] = min(max((db - floorDB) / (ceilingDB - floorDB), 0), 1)
        }
        let result = bands
        latest.withLock { $0 = result }
    }
}
