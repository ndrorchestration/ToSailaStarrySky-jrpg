# Chapter 1 Audio Handoff

Chapter 1 uses five governed user-owned music assets. All five must be admitted from exact verified source files before a standalone candidate can be produced.

## Governed tracks

1. **Aetherwake — Skyward Arpeggio Main Title**
   - role: title / menu
   - canonical path: `assets/audio/aetherwake-skyward-arpeggio-main-title.mp3`
   - SHA-256: `7ac5fe9c2ee0bc8d0cbfa36441dbb7783dbe2ef0cc5e2ee665086a527a7bc350`

2. **Amonigio Umulula**
   - role: First Wake opening / cinematic progression
   - canonical path: `assets/audio/amonigio-umulula.mp3`
   - SHA-256: `bce86fc575323b99573e420dcb6c0d19bfe1eb8e6ba637edc2b72c1edf20cd98`

3. **Nocturnal Resolve**
   - role: combat / Crossing hazards
   - canonical path: `assets/audio/nocturnal-resolve.mp3`
   - SHA-256: `c8a35d42762705011f8a9eeefebea91736b333677a9b1117087490bbf0dbc65c`

4. **Solar Punk Airship**
   - role: world exploration / airship travel
   - canonical path: `assets/audio/solar-punk-airship.mp3`
   - SHA-256: `d5d1561c1ef056978342732e363df5411860611739fb485bb707c6e98800335c`

5. **Open Sky Signal**
   - role: Ender character theme / First Note leitmotif
   - canonical path: `assets/audio/open-sky-signal.mp3`
   - SHA-256: `831a195d060e22107c9b38ac1655b0ae879485e87eba601d41d3af46d8518484`

## Preferred Windows admission

From a clean checkout on the Chapter 1 convergence branch:

```powershell
npm run admit:chapter1-audio:windows -- `
  -Title "C:\path\Aetherwake - Skyward Arpeggio Main Title.mp3" `
  -Amonigio "C:\path\Amonigio Umulula.mp3" `
  -Nocturnal "C:\path\Nocturnal Resolve.mp3" `
  -Solar "C:\path\Solar Punk Airship.mp3" `
  -OpenSky "C:\path\Open Sky Signal.mp3" `
  -Commit
```

The wrapper:
- requires a named branch and clean tracked/staged state;
- verifies every source hash and byte count before mutating the repository;
- copies only verified files to governed canonical paths;
- stages only the five audio files plus `docs/audio-assets.json`;
- runs strict title-audio readiness, soundtrack readiness, and audio-routing tests;
- commits the exact admitted set when `-Commit` is supplied;
- prints the resulting admission commit and the next command: `npm run build:chapter1:windows`.

No mismatched or partially admitted soundtrack should be used as Chapter 1 closure evidence.
