//
//  AudioPreset.swift
//  dotdot
//
//  Created by Maral on 17.11.2026.
//

import Foundation

/// Sound presets applied by `AudioEngine`. `nil` preset means a clean signal.
nonisolated enum AudioPreset: String, CaseIterable, Identifiable, Sendable {
    case slowed
    case tape
    case bassBoost
    case spedUp
    case eightD
    case reverb

    var id: String { rawValue }

    var title: String {
        switch self {
        case .slowed: "slowed"
        case .tape: "tape"
        case .bassBoost: "bass boost"
        case .spedUp: "sped up"
        case .eightD: "8D"
        case .reverb: "reverb"
        }
    }
}
