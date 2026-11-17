# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

# dotdot — retro skinnable music player (iOS)

## Goal
Portfolio piece for the Higgsfield Soul Camp application. Deadline: ~1 day.
Quality over quantity: one polished flow, then a short demo video.

## Stack
- SwiftUI, Swift Concurrency, `@Observable`
- AVAudioEngine (no third-party audio libraries)
- Accelerate (vDSP) for FFT
- Core Haptics
- No backend. Music = local files imported via `fileImporter`.
  No Apple Music: DRM-protected tracks cannot go through AVAudioEngine effects.

## Build & run
Single app target and scheme, both named `dotdot`. No shared scheme is committed (it lives in `xcuserdata`), so Xcode/xcodebuild auto-generates it.

```bash
xcodebuild -project dotdot.xcodeproj -scheme dotdot -destination 'platform=iOS Simulator,name=iPhone 17' build
```

List simulators with `xcrun simctl list devices available`. No test target or linters yet; once tests exist, run one with `xcodebuild test ... -only-testing:<Target>/<Class>/<method>`.

## Project configuration that affects code
- **Deployment target: iOS 17.0** (built with the iOS 26 SDK). Don't use APIs newer than iOS 17 without `#available`; verify on the iOS 17 simulator (iPhone 15 Pro). iPhone + iPad.
- **Swift 5 mode with `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`** and approachable concurrency: every type is implicitly `@MainActor`. Mark audio-thread / DSP code (tap callbacks, FFT, `AudioEngine` internals) `nonisolated` explicitly, and hop to main only to publish `bands`.
- **File-system-synchronized groups**: any file under `dotdot/` joins the target automatically. Create folders/files on disk; don't edit `project.pbxproj` for sources.

## Architecture
- `PlayerModel` (`@Observable`): engine, playback state, current preset,
  `bands: [Float]` (16 FFT bands, 0...1, ~60 updates/sec), current time, duration
- `AudioEngine`: PlayerNode -> Varispeed -> Reverb -> EQ -> EnvironmentNode (8D) -> mainMixer
- Presets: slowed, tape, vinyl, spedUp, eightD, reverb
  - slowed: varispeed 0.8 + reverb; spedUp: varispeed 1.25
  - tape: EQ cuts lows/highs, slight rate wobble (±0.5%), hiss layer
  - vinyl: looping crackle on a second PlayerNode
  - eightD: mono source orbiting the listener via EnvironmentNode (HRTF)
  - reverb: large hall, wetDryMix ~40
- Skins: `enum PlayerSkin { pixelDesktop, cobaltDots, codeRain }`.
  Each skin is a View that only reads/drives `PlayerModel`. Persist with `@AppStorage`.
- Folder layout (under `dotdot/`): `Audio/`, `Model/`, `Skins/PixelDesktop/`, `Skins/CobaltDots/`, `Skins/CodeRain/`, `Shared/`

## Design (source of truth: `/design`)
HTML mockups at 390x844. Copy colors, fonts, sizes, layout and visualizer logic
(see the `<script>` in each file) as closely as possible. UI text is English only.
- `design/skin-pixel-desktop.html` (MAIN): Win98-style window, black LCD with
  green/yellow/red pixel EQ (16 cols x 10 rows), round beveled control pad,
  radio-button presets, status bar, taskbar. Fonts: Pixelify Sans, VT323.
- `design/skin-cobalt-dots.html`: white + cobalt #1E36C8, 22x22 halftone dot
  grid pulsing to bass, sticker doodles, tilted preset tags. Fonts: Yellowtail, Space Mono.
- `design/skin-code-rain.html`: black + green hex digital rain, column tail
  length/speed driven by band levels, terminal-style presets. Font: Share Tech Mono.
- Fonts: Google Fonts .ttf files live in `dotdot/Resources/Fonts/` and are registered at launch by
  `AppFonts.register()` (CTFontManager), not via Info.plist, because the Info.plist is generated.
  Use `Font.pixelify(_:semibold:)` / `Font.vt323(_:)`; add new fonts the same way.
- Shared Win98 pieces (bevels, palette) live in `Skins/PixelDesktop/`; cross-skin helpers
  (`Haptics`, `SkinMenuItems` + `.skinChrome`, `FlowLayout`, `Color(hex:)`, `TimeFormat`) live in `Shared/`.
- Every skin must expose the dotdot menu (open music, skin picker, debug panel), since the
  mockups have no other navigation: pixelDesktop = taskbar "dotdot" button,
  codeRain = "> menu" button (top right) + now_playing card, cobaltDots = "•••" button + logo.
- `design/` is git-ignored (mockups are kept locally only).
- Simulator check of a specific skin: `xcrun simctl launch <device> com.maral.dotdot -selectedSkin codeRain`
  (launch argument overrides @AppStorage). Caveat: while launched this way the skin is pinned and
  the in-app skin picker appears broken; relaunch without the argument before testing switching.

## Milestones
1. AudioEngine + PlayerModel + file import + presets + debug screen
2. FFT bands
3. pixelDesktop skin + haptics
4. Skin switching (taskbar "dotdot" button menu) + codeRain + cobaltDots
5. Polish for demo video

## Rules
- Code, names, comments in English
- Small files, one skin per folder
- Build after each milestone and fix all errors and warnings
- Do not add third-party dependencies without asking
