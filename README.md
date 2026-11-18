# dotdot

A retro skinnable music player for iOS. Plays local audio files with real-time effects and music-reactive visuals.

## Features

- **Skins:** Pixel Desktop, Code Rain, ASCII Print, Cobalt Dots
- **Presets:** slowed, sped up, tape, bass boost, 8D, reverb
- Live 16-band spectrum drives every skin's visualizer
- Background and lock-screen playback with Now Playing controls
- Haptic feedback

## Tech

- SwiftUI, Swift Concurrency, Observation
- AVAudioEngine: varispeed, reverb, EQ and HRTF spatial audio
- Accelerate (vDSP) for FFT
- Core Haptics
- No third-party dependencies

## Requirements

- iOS 17.0+
- Xcode 26+

## Build

```bash
xcodebuild -project dotdot.xcodeproj -scheme dotdot -destination 'platform=iOS Simulator,name=iPhone 17' build
```

Import music via the menu → Open music.

## Fonts

Pixelify Sans, VT323, Share Tech Mono, Space Mono and Yellowtail from Google Fonts, under the SIL Open Font License (see `dotdot/Resources/Fonts/Licenses`).
