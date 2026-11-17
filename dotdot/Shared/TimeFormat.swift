//
//  TimeFormat.swift
//  dotdot
//
//  Created by Maral on 17.11.2026.
//

import Foundation

nonisolated enum TimeFormat {
    /// 0:00 style, as shown on player displays.
    static func clock(_ seconds: TimeInterval) -> String {
        guard seconds.isFinite, seconds > 0 else { return "0:00" }
        let total = Int(seconds)
        return String(format: "%d:%02d", total / 60, total % 60)
    }

    /// 01:42 style, zero-padded minutes for LCD displays.
    static func lcd(_ seconds: TimeInterval) -> String {
        let total = seconds.isFinite ? max(Int(seconds), 0) : 0
        return String(format: "%02d:%02d", total / 60, total % 60)
    }
}
