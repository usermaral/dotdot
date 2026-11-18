//
//  FileStreamer.swift
//  dotdot
//
//  Created by Maral on 18.11.2026.
//

import os
import AVFoundation

/// Feeds a player node from a file in decoded 2-second chunks, keeping ~8 s queued ahead.
///
/// Scheduling the whole file as one segment lets AVAudioPlayerNode read it on demand; when the
/// device is briefly overloaded (skin switch: new views, GPU setup, cover decoding) that reader
/// falls behind and the music drops out, then stutters back. With chunks decoded ahead into
/// memory, short spikes are not audible. All file access happens on `queue`.
nonisolated final class FileStreamer: @unchecked Sendable {
    private static let chunkSeconds = 2.0
    private static let chunksAhead = 4

    private let player: AVAudioPlayerNode
    private let queue = DispatchQueue(label: "dotdot.file-streamer", qos: .userInitiated)

    // Only touched on `queue`.
    private var file: AVAudioFile?
    private var nextFrame: AVAudioFramePosition = 0
    private var queuedChunks = 0
    private var generation = 0
    private var onFinished: (@Sendable () -> Void)?

    init(player: AVAudioPlayerNode) {
        self.player = player
    }

    /// Starts feeding `file` from `frame`. The first chunks are decoded before this returns,
    /// so playback can start right away. `onFinished` runs (on a background queue) after the
    /// last frame has played.
    func start(file: AVAudioFile, from frame: AVAudioFramePosition, onFinished: @escaping @Sendable () -> Void) {
        queue.sync {
            generation += 1
            self.file = file
            nextFrame = frame
            queuedChunks = 0
            self.onFinished = onFinished
            fill(generation: generation)
        }
    }

    /// Stops feeding. Call before `player.stop()`, so callbacks of dropped chunks are ignored.
    func cancel() {
        queue.sync {
            generation += 1
            file = nil
            onFinished = nil
        }
    }

    private func fill(generation: Int) {
        while queuedChunks < Self.chunksAhead, let file, nextFrame < file.length {
            let format = file.processingFormat
            let count = AVAudioFrameCount(min(AVAudioFramePosition(format.sampleRate * Self.chunkSeconds),
                                              file.length - nextFrame))
            guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: count) else { return }
            do {
                file.framePosition = nextFrame
                try file.read(into: buffer, frameCount: count)
            } catch {
                // Damaged tail: end the track here instead of looping on the error.
                nextFrame = file.length
            }
            guard buffer.frameLength > 0 else {
                nextFrame = file.length
                if queuedChunks == 0 { onFinished?() }
                return
            }
            nextFrame += AVAudioFramePosition(buffer.frameLength)
            let isLast = nextFrame >= file.length
            queuedChunks += 1
            player.scheduleBuffer(buffer, completionCallbackType: .dataPlayedBack) { [weak self] _ in
                guard let self else { return }
                queue.async {
                    guard generation == self.generation else { return }
                    self.queuedChunks -= 1
                    if self.queuedChunks == 0, !isLast {
                        Diag.audio.error("stream buffer ran dry: reading fell behind playback")
                    }
                    if isLast {
                        self.onFinished?()
                    } else {
                        self.fill(generation: generation)
                    }
                }
            }
        }
    }
}
