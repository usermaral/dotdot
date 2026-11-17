//
//  TrackLibrary.swift
//  dotdot
//
//  Created by Maral on 17.11.2026.
//

import Foundation

/// Persists imported files in Documents/Tracks so they survive relaunches and
/// security-scoped access from the file picker is only needed once (at import).
nonisolated enum TrackLibrary {
    static let supportedExtensions: Set<String> = ["mp3", "m4a", "aac", "wav", "aiff", "aif", "caf", "flac"]

    static var directory: URL {
        URL.documentsDirectory.appending(path: "Tracks", directoryHint: .isDirectory)
    }

    static func loadTracks() -> [Track] {
        let urls = (try? FileManager.default.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: nil,
            options: .skipsHiddenFiles
        )) ?? []
        return urls
            .filter { supportedExtensions.contains($0.pathExtension.lowercased()) }
            .sorted { $0.lastPathComponent.localizedStandardCompare($1.lastPathComponent) == .orderedAscending }
            .map(Track.init(url:))
    }

    /// Copies a picked file into the library. Returns the existing copy if already imported.
    static func importFile(at source: URL) throws -> Track {
        let isScoped = source.startAccessingSecurityScopedResource()
        defer { if isScoped { source.stopAccessingSecurityScopedResource() } }

        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let destination = directory.appending(path: source.lastPathComponent)
        if !FileManager.default.fileExists(atPath: destination.path(percentEncoded: false)) {
            try FileManager.default.copyItem(at: source, to: destination)
        }
        return Track(url: destination)
    }
}
