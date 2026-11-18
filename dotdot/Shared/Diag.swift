//
//  Diag.swift
//  dotdot
//
//  Created by Maral on 18.11.2026.
//

import os

/// Diagnostic logs for audio dropouts. Shown in Xcode's console and Console.app;
/// filter by subsystem `com.maral.dotdot`.
nonisolated enum Diag {
    static let audio = Logger(subsystem: "com.maral.dotdot", category: "audio")
    static let ui = Logger(subsystem: "com.maral.dotdot", category: "ui")
}
