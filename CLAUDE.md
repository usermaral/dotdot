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
- Skins: `enum PlayerSkin { pixelDesktop, cobaltDots, codeRain, asciiPrint }`. Each declares its
  `colorScheme` (light/dark) so the status bar and menus match its background.
  Each skin is a View that only reads/drives `PlayerModel`. Persist with `@AppStorage`.
- Folder layout (under `dotdot/`): `Audio/`, `Model/`, `Skins/PixelDesktop/`, `Skins/CobaltDots/`, `Skins/CodeRain/`, `Skins/AsciiPrint/`, `Shared/`

## Design (source of truth: `/design`)
HTML mockups at 390x844. Copy colors, fonts, sizes, layout and visualizer logic
(see the `<script>` in each file) as closely as possible. UI text is English only.
- `design/skin-pixel-desktop.html` (MAIN): Win98-style window, black LCD with
  green/yellow/red pixel EQ (16 cols x 10 rows), round beveled control pad,
  radio-button presets, status bar, taskbar. Fonts: Pixelify Sans, VT323.
- `skin-cobalt-v2.html` (current source for cobaltDots; v1 `design/skin-cobalt-dots.html` is superseded):
  white ink on #2234C6, yellow #FFE76A accents, tilted 28x28 dot card with a star sticker, dot progress,
  3x2 preset grid. The card (`CobaltArtView`) is a pure music visualizer (no cover art, no characters):
  the mockup's dot blobs, each tied to a spectrum range (bass, low-mid, mid, treble), swell and drift;
  a ring sweeps while playing, kicks send yellow ripples, mids sway the grid, highs sparkle.
- `skin-receipt-v2.html` (source for asciiPrint): white till receipt with zigzag edges on #E9EDF5, navy
  Space Mono, cover typed out as classic ASCII art (`AsciiArtView`, 50 cols, long ~70-glyph ramp, positive print:
  dark = dense letters; user preferred this over the mockup's 10-glyph ramp), dotted-leader
  TRACK/FX/TIME rows, `[====>...]` bar, `[x] preset` checkboxes. Cover loading (`CoverArt`) is used by asciiPrint; audio motion (`ArtMotion`)
  is shared with cobaltDots in `Shared/`.
- App icon: `Assets.xcassets/AppIcon.appiconset/AppIcon.png` (+ grayscale `AppIcon-Tinted.png`),
  flat pixel face + EQ bars in the Pixel LCD palette, rendered at 1024x1024 without alpha.
- `design/skin-code-rain.html`: black + green hex digital rain, column tail
  length/speed driven by band levels, terminal-style presets. Font: Share Tech Mono.
- Fonts: Google Fonts .ttf files live in `dotdot/Resources/Fonts/` and are registered at launch by
  `AppFonts.register()` (CTFontManager), not via Info.plist, because the Info.plist is generated.
  Use `Font.pixelify(_:semibold:)` / `Font.vt323(_:)`; add new fonts the same way.
- Shared Win98 pieces (bevels, palette) live in `Skins/PixelDesktop/`; cross-skin helpers
  (`Haptics`, `SkinMenuItems` + `.skinChrome`, `Color(hex:)`, `TimeFormat`) live in `Shared/`.
- Every skin has exactly one menu (`SkinMenuItems`: tracks, skins, open music), always in the
  top-right corner, styled per skin: pixelDesktop = "Menu ▾" caption button in the title bar
  (taskbar "dotdot" is decorative), codeRain = "> menu", cobaltDots = "•••", asciiPrint = "[menu]". No duplicate entry points.
  Always use `SkinMenuButton` (isolated view, label stored as a value): a `Menu` inside a skin body
  that re-renders at 60 fps makes menu taps unreliable.
- Imported files go through `TrackLibrary.ensurePlayable`: if AVAudioFile can't read a file, or reads a
  length far shorter than AVAsset's duration (mislabeled/odd MP3s), it is re-encoded to .m4a.
  The library is re-checked once per launch.
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
