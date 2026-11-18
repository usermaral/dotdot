//
//  NowPlaying.swift
//  dotdot
//
//  Created by Maral on 18.11.2026.
//

import MediaPlayer

/// Lock screen / Control Center integration: shows the current track and routes the
/// system play, pause, next, previous and scrub commands to `PlayerModel`.
enum NowPlaying {
    static func connect(to player: PlayerModel) {
        let center = MPRemoteCommandCenter.shared()
        center.playCommand.addTarget { [weak player] _ in
            player?.play()
            return .success
        }
        center.pauseCommand.addTarget { [weak player] _ in
            player?.pause()
            return .success
        }
        center.togglePlayPauseCommand.addTarget { [weak player] _ in
            player?.togglePlayPause()
            return .success
        }
        center.nextTrackCommand.addTarget { [weak player] _ in
            player?.next()
            return .success
        }
        center.previousTrackCommand.addTarget { [weak player] _ in
            player?.previous()
            return .success
        }
        center.changePlaybackPositionCommand.addTarget { [weak player] event in
            guard let event = event as? MPChangePlaybackPositionCommandEvent else { return .commandFailed }
            player?.seek(to: event.positionTime)
            return .success
        }
    }

    /// Call when the track, play state or position jumps (not every frame: the system
    /// extrapolates elapsed time from the playback rate).
    static func update(title: String?, duration: TimeInterval, elapsed: TimeInterval, isPlaying: Bool) {
        let info = MPNowPlayingInfoCenter.default()
        guard let title else {
            info.nowPlayingInfo = nil
            return
        }
        info.nowPlayingInfo = [
            MPMediaItemPropertyTitle: title,
            MPMediaItemPropertyArtist: "dotdot",
            MPMediaItemPropertyPlaybackDuration: duration,
            MPNowPlayingInfoPropertyElapsedPlaybackTime: elapsed,
            MPNowPlayingInfoPropertyPlaybackRate: isPlaying ? 1.0 : 0.0,
        ]
    }
}
