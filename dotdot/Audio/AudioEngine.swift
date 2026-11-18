//
//  AudioEngine.swift
//  dotdot
//
//  Created by Maral on 17.11.2026.
//

import AVFoundation

/// Owns the AVAudioEngine graph:
///
///     player -> inputMixer -> varispeed -> reverb -> eq -> spatialMixer -> environment -> mainMixer
///     fxPlayer (hiss / crackle loops) ------------------------------------------------> mainMixer
///
/// `inputMixer` converts any file format (mono, 44.1k, 48k...) to the stereo graph format.
/// `spatialMixer` exists because only AVAudioMixing nodes can set the 3D source mode
/// on their connection into the environment node (bypass normally, point source for 8D).
final class AudioEngine {
    enum EngineError: LocalizedError {
        case noTrackLoaded

        var errorDescription: String? { "No track loaded." }
    }

    var onTrackFinished: (() -> Void)?
    /// Called when the engine changed playback state on its own (e.g. output device switch).
    var onStateChange: (() -> Void)?

    private(set) var preset: AudioPreset?
    private(set) var isPlaying = false

    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private let fxPlayer = AVAudioPlayerNode()
    private let inputMixer = AVAudioMixerNode()
    private let varispeed = AVAudioUnitVarispeed()
    private let reverb = AVAudioUnitReverb()
    private let eq = AVAudioUnitEQ(numberOfBands: 2)
    private let spatialMixer = AVAudioMixerNode()
    private let environment = AVAudioEnvironmentNode()

    private let graphFormat: AVAudioFormat
    private let analyzer: SpectrumAnalyzer
    private let hissBuffer: AVAudioPCMBuffer?
    private let crackleBuffer: AVAudioPCMBuffer?
    private var fxBuffer: AVAudioPCMBuffer?

    private var file: AVAudioFile?
    private var segmentStartFrame: AVAudioFramePosition = 0
    private var isSegmentScheduled = false
    private var pausedTime: TimeInterval = 0
    /// Last valid render position; used when the engine stops under us and render time is gone.
    private var lastKnownTime: TimeInterval = 0
    private var scheduleGeneration = 0
    private lazy var modulator = EffectModulator(varispeed: varispeed, spatialMixer: spatialMixer)

    init() {
        let outputRate = engine.outputNode.outputFormat(forBus: 0).sampleRate
        graphFormat = AVAudioFormat(standardFormatWithSampleRate: outputRate > 0 ? outputRate : 48_000, channels: 2)!
        hissBuffer = NoiseBuffers.hiss(format: graphFormat)
        crackleBuffer = NoiseBuffers.crackle(format: graphFormat)
        analyzer = SpectrumAnalyzer(sampleRate: graphFormat.sampleRate, bandCount: PlayerModel.bandCount)

        [player, fxPlayer, inputMixer, varispeed, reverb, eq, spatialMixer, environment].forEach(engine.attach)
        engine.connect(player, to: inputMixer, format: graphFormat)
        engine.connect(inputMixer, to: varispeed, format: graphFormat)
        engine.connect(varispeed, to: reverb, format: graphFormat)
        engine.connect(reverb, to: eq, format: graphFormat)
        engine.connect(eq, to: spatialMixer, format: graphFormat)
        engine.connect(spatialMixer, to: environment, format: graphFormat)
        engine.connect(environment, to: engine.mainMixerNode, format: graphFormat)
        engine.connect(fxPlayer, to: engine.mainMixerNode, format: graphFormat)

        // Spatial setup (must be set after the spatialMixer -> environment connection exists).
        spatialMixer.renderingAlgorithm = .auto
        spatialMixer.pointSourceInHeadMode = .mono
        environment.listenerPosition = AVAudio3DPoint(x: 0, y: 0, z: 0)
        environment.distanceAttenuationParameters.referenceDistance = 5 // no level drop inside the orbit

        // Spectrum is measured after all music effects, before the hiss/crackle layer.
        let analyzer = analyzer
        environment.installTap(onBus: 0, bufferSize: 1024, format: graphFormat) { @Sendable buffer, _ in
            analyzer.process(buffer)
        }

        apply(preset: nil)

        // The engine stops itself when the output changes (headphones, AirPods, sample rate).
        NotificationCenter.default.addObserver(
            forName: .AVAudioEngineConfigurationChange, object: engine, queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            MainActor.assumeIsolated { self.handleConfigurationChange() }
        }
    }

    /// Master output volume, 0...1.
    var volume: Float {
        get { engine.mainMixerNode.outputVolume }
        set { engine.mainMixerNode.outputVolume = min(max(newValue, 0), 1) }
    }

    /// Latest spectrum levels (0...1), unsmoothed.
    var spectrum: [Float] {
        isPlaying ? analyzer.currentBands() : [Float](repeating: 0, count: analyzer.bandCount)
    }

    // MARK: - Time

    var duration: TimeInterval {
        guard let file else { return 0 }
        return Double(file.length) / file.processingFormat.sampleRate
    }

    /// Position in the source file (independent of varispeed rate).
    var currentTime: TimeInterval {
        guard let file, isPlaying else { return pausedTime }
        guard let nodeTime = player.lastRenderTime,
              let playerTime = player.playerTime(forNodeTime: nodeTime) else { return lastKnownTime }
        let start = Double(segmentStartFrame) / file.processingFormat.sampleRate
        let elapsed = Double(playerTime.sampleTime) / playerTime.sampleRate
        let time = min(max(start + elapsed, 0), duration)
        lastKnownTime = time
        return time
    }

    // MARK: - Transport

    func load(url: URL) throws {
        let newFile = try AVAudioFile(forReading: url)
        stopPlayer()
        engine.disconnectNodeOutput(player)
        engine.connect(player, to: inputMixer, format: newFile.processingFormat)
        file = newFile
        pausedTime = 0
        lastKnownTime = 0
        try startEngineIfNeeded()
        schedule(from: 0)
    }

    /// Stops playback and releases the file (e.g. before deleting it).
    func unload() {
        stopPlayer()
        fxPlayer.stop()
        file = nil
        pausedTime = 0
        lastKnownTime = 0
    }

    func play() throws {
        guard file != nil else { throw EngineError.noTrackLoaded }
        try startEngineIfNeeded()
        if pausedTime >= duration { pausedTime = 0 }
        if !isSegmentScheduled { schedule(from: frame(for: pausedTime)) }
        player.play()
        isPlaying = true
        startFx()
    }

    func pause() {
        guard isPlaying else { return }
        pausedTime = currentTime
        player.pause()
        fxPlayer.stop()
        isPlaying = false
    }

    /// Pause for an audio session interruption: the system may stop the engine,
    /// so drop the scheduled segment and resume from the saved position later.
    func suspend() {
        pause()
        stopPlayer()
    }

    func seek(to time: TimeInterval) {
        guard file != nil else { return }
        let wasPlaying = isPlaying
        let target = min(max(time, 0), duration)
        stopPlayer()
        pausedTime = target
        lastKnownTime = target
        schedule(from: frame(for: target))
        if wasPlaying {
            player.play()
            isPlaying = true
        }
    }

    // MARK: - Presets

    func apply(preset: AudioPreset?) {
        self.preset = preset
        modulator.stop()
        resetEffects()

        switch preset {
        case .slowed:
            varispeed.rate = 0.8
            setReverb(.mediumHall, wetDryMix: 25)
        case .spedUp:
            varispeed.rate = 1.25
        case .tape:
            setBandPass(highPass: 120, lowPass: 5_000)
            fxBuffer = hissBuffer
            modulator.start(.tape)
        case .vinyl:
            setBandPass(highPass: 40, lowPass: 9_000)
            fxBuffer = crackleBuffer
        case .eightD:
            spatialMixer.sourceMode = .pointSource
            modulator.start(.orbit)
        case .reverb:
            setReverb(.largeHall, wetDryMix: 40)
        case nil:
            break
        }

        if isPlaying { startFx() }
    }

    // MARK: - Private

    private func startEngineIfNeeded() throws {
        guard !engine.isRunning else { return }
        engine.prepare()
        try engine.start()
    }

    private func frame(for time: TimeInterval) -> AVAudioFramePosition {
        guard let file else { return 0 }
        return AVAudioFramePosition(time * file.processingFormat.sampleRate)
    }

    private func stopPlayer() {
        scheduleGeneration += 1 // invalidates the completion of the stopped segment
        player.stop()
        isSegmentScheduled = false
        isPlaying = false
    }

    private func schedule(from startFrame: AVAudioFramePosition) {
        guard let file else { return }
        let start = min(max(startFrame, 0), file.length)
        let remaining = file.length - start
        segmentStartFrame = start
        guard remaining > 0 else { return }

        scheduleGeneration += 1
        let generation = scheduleGeneration
        player.scheduleSegment(
            file,
            startingFrame: start,
            frameCount: AVAudioFrameCount(remaining),
            at: nil,
            completionCallbackType: .dataPlayedBack
        ) { @Sendable [weak self] _ in
            guard let self else { return }
            Task { @MainActor in self.segmentFinished(generation: generation) }
        }
        isSegmentScheduled = true
    }

    private func handleConfigurationChange() {
        let wasPlaying = isPlaying
        let resumeAt = currentTime
        stopPlayer()
        fxPlayer.stop()
        pausedTime = resumeAt
        lastKnownTime = resumeAt
        guard file != nil else { return }
        do {
            try startEngineIfNeeded()
            schedule(from: frame(for: resumeAt))
            if wasPlaying {
                player.play()
                isPlaying = true
                startFx()
            }
        } catch {
            print("Engine restart failed: \(error)")
        }
        onStateChange?()
    }

    private func segmentFinished(generation: Int) {
        guard generation == scheduleGeneration, isPlaying else { return }
        stopPlayer()
        fxPlayer.stop()
        pausedTime = duration
        onTrackFinished?()
    }

    private func resetEffects() {
        varispeed.rate = 1
        reverb.wetDryMix = 0
        reverb.bypass = true
        eq.bypass = true
        spatialMixer.sourceMode = .bypass
        spatialMixer.position = AVAudio3DPoint(x: 0, y: 0, z: 0)
        fxPlayer.stop()
        fxBuffer = nil
    }

    private func setReverb(_ preset: AVAudioUnitReverbPreset, wetDryMix: Float) {
        reverb.loadFactoryPreset(preset)
        reverb.wetDryMix = wetDryMix
        reverb.bypass = false
    }

    private func setBandPass(highPass: Float, lowPass: Float) {
        let low = eq.bands[0]
        low.filterType = .highPass
        low.frequency = highPass
        low.bypass = false
        let high = eq.bands[1]
        high.filterType = .lowPass
        high.frequency = lowPass
        high.bypass = false
        eq.bypass = false
    }

    private func startFx() {
        guard let fxBuffer else { return }
        try? startEngineIfNeeded()
        fxPlayer.stop()
        fxPlayer.scheduleBuffer(fxBuffer, at: nil, options: .loops)
        fxPlayer.play()
    }
}
