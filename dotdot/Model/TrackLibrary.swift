//
//  TrackLibrary.swift
//  dotdot
//
//  Created by Maral on 17.11.2026.
//

import AVFoundation

/// Persists imported files in Documents/Tracks so they survive relaunches and
/// security-scoped access from the file picker is only needed once (at import).
nonisolated enum TrackLibrary {
    static let supportedExtensions: Set<String> = ["mp3", "m4a", "aac", "wav", "aiff", "aif", "caf", "flac"]

    enum LibraryError: LocalizedError {
        case notPlayable(String)

        var errorDescription: String? {
            switch self {
            case .notPlayable(let name):
                "“\(name)” isn't a playable audio file. It may be damaged or only partly downloaded — try downloading it again."
            }
        }
    }

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

    /// Removes a track's file from the library.
    static func delete(_ track: Track) throws {
        try FileManager.default.removeItem(at: track.url)
    }

    /// Copies a picked file into the library and makes sure the engine can read it.
    /// Unreadable copies are removed so they don't clutter the track list.
    static func importFile(at source: URL) async throws -> Track {
        let copy = try copyIntoLibrary(source)
        do {
            return Track(url: try await ensurePlayable(copy))
        } catch {
            try? FileManager.default.removeItem(at: copy)
            throw error
        }
    }

    /// Returns a URL `AVAudioFile` can open: the file itself if it already works, otherwise
    /// an AAC .m4a re-encode that replaces it. AVAudioFile is strict (e.g. a .m4a/.webm
    /// saved as .mp3, odd MP3 headers); AVAsset's parser is more forgiving.
    static func ensurePlayable(_ url: URL) async throws -> URL {
        let name = url.lastPathComponent
        let asset = AVURLAsset(url: url)
        let assetSeconds = (try? await asset.load(.duration)).map(CMTimeGetSeconds) ?? 0

        // "Opens" isn't enough: a mislabeled file can open as MP3 yet report a few ms of
        // audio, so the track would end instantly. Trust it only if its length matches.
        if let file = try? AVAudioFile(forReading: url) {
            let fileSeconds = Double(file.length) / file.processingFormat.sampleRate
            if !assetSeconds.isFinite || assetSeconds <= 0 || fileSeconds >= assetSeconds * 0.9 {
                return url
            }
        }

        guard let audioTracks = try? await asset.loadTracks(withMediaType: .audio), !audioTracks.isEmpty,
              let session = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetAppleM4A)
        else { throw LibraryError.notPlayable(name) }

        let temp = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString + ".m4a")
        defer { try? FileManager.default.removeItem(at: temp) }
        do {
            if #available(iOS 18, *) {
                try await session.export(to: temp, as: .m4a)
            } else {
                session.outputURL = temp
                session.outputFileType = .m4a
                await session.export()
                guard session.status == .completed else { throw LibraryError.notPlayable(name) }
            }
        } catch {
            throw LibraryError.notPlayable(name)
        }
        guard (try? AVAudioFile(forReading: temp)) != nil else { throw LibraryError.notPlayable(name) }

        // Same title, .m4a extension, original removed.
        let fixed = directory.appending(path: url.deletingPathExtension().lastPathComponent + ".m4a")
        try? FileManager.default.removeItem(at: url)
        try? FileManager.default.removeItem(at: fixed)
        try FileManager.default.moveItem(at: temp, to: fixed)
        return fixed
    }

    /// Copies a picked file into the library. Returns the existing copy if already imported.
    private static func copyIntoLibrary(_ source: URL) throws -> URL {
        let isScoped = source.startAccessingSecurityScopedResource()
        defer { if isScoped { source.stopAccessingSecurityScopedResource() } }

        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let destination = directory.appending(path: source.lastPathComponent)
        if !FileManager.default.fileExists(atPath: destination.path(percentEncoded: false)) {
            try FileManager.default.copyItem(at: source, to: destination)
        }
        return destination
    }
}
