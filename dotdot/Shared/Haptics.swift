//
//  Haptics.swift
//  dotdot
//
//  Created by Maral on 17.11.2026.
//

import CoreHaptics

/// Short Core Haptics clicks for skin controls. Silently does nothing on devices without haptics.
final class Haptics {
    enum Kind {
        /// Light, crisp click (small buttons, radio buttons).
        case tap
        /// Heavier press (play/pause).
        case press
    }

    static let shared = Haptics()

    private var engine: CHHapticEngine?
    private var needsStart = true

    private init() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        do {
            let engine = try CHHapticEngine()
            engine.playsHapticsOnly = true // never touches the audio session
            engine.resetHandler = { @Sendable [weak self] in
                guard let self else { return }
                Task { @MainActor in self.needsStart = true }
            }
            engine.stoppedHandler = { @Sendable [weak self] _ in
                guard let self else { return }
                Task { @MainActor in self.needsStart = true }
            }
            self.engine = engine
        } catch {
            print("Haptics unavailable: \(error)")
        }
    }

    func play(_ kind: Kind) {
        guard let engine else { return }
        let (intensity, sharpness): (Float, Float) = switch kind {
        case .tap: (0.55, 0.9)
        case .press: (1.0, 0.55)
        }
        do {
            if needsStart {
                try engine.start()
                needsStart = false
            }
            let event = CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness),
                ],
                relativeTime: 0
            )
            let pattern = try CHHapticPattern(events: [event], parameters: [])
            try engine.makePlayer(with: pattern).start(atTime: CHHapticTimeImmediate)
        } catch {
            needsStart = true
        }
    }
}
