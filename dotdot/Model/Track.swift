//
//  Track.swift
//  dotdot
//
//  Created by Maral on 17.11.2026.
//

import Foundation

/// A local audio file copied into the app's library.
nonisolated struct Track: Identifiable, Hashable, Sendable {
    let url: URL

    var id: URL { url }
    var title: String { url.deletingPathExtension().lastPathComponent }
}
