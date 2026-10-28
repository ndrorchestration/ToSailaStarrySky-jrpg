# Audio asset register — To Sail the Starry Sky

**Updated 2026-10-27.** These are **existing audio binaries in a historical GitHub branch**, not speculative future compositions. This page records provenance and current migration boundaries; it does **not** grant public music distribution rights, alter the current Godot runtime, or publish new binaries.

## Source and status

A previous Chapter One convergence review [PR #151](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/151), exact historical head [`1b1f51806ea9d013433cb98add260bd9c5be79c0`](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/tree/1b1f51806ea9d013433cb98add260bd9c5be79c0), contains **five committed MP3 blobs** under `assets/audio/`, the governed manifest `docs/audio-assets.json`, `modules/scene-music.js`, and [`docs/CHAPTER1_AUDIO_HANDOFF.md`](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/blob/1b1f51806ea9d013433cb98add260bd9c5be79c0/docs/CHAPTER1_AUDIO_HANDOFF.md). That historical branch is **closed/unmerged** and follows the previous *Aetherwake* and Lyra-first narrative layout.

The **public `main`** and the newer independent native 2D / 3D Godot study branches **do not currently contain these MP3s or a verified music-player integration**. The 2026-09-24 source manifest records admitted SHA-256/byte identities and source-authorized title/menu behavior for that older branch; its readiness checks do not automatically transfer to any new branch or renamed Windows package.

| Existing recording | Historical intended use | Historical Git object / bytes |
| --- | --- | --- |
| **Skyward Arpeggio** | Title / menu; stop on gameplay start | `assets/audio/aetherwake-skyward-arpeggio-main-title.mp3` · 4,233,081 |
| **Amonigio Umulula** | Opening / cinematic progression | `assets/audio/amonigio-umulula.mp3` · 5,364,037 |
| **Nocturnal Resolve** | Combat / Crossing hazards | `assets/audio/nocturnal-resolve.mp3` · 6,500,031 |
| **Solar Punk Airship** | Exploration / airship travel | `assets/audio/solar-punk-airship.mp3` · 4,432,217 |
| **Open Sky Signal** | Ender's character theme / First Note recurring motif | `assets/audio/open-sky-signal.mp3` · 4,171,250 |

The authoritative **historical verification hashes** are in the exact-commit [audio manifest](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/blob/1b1f51806ea9d013433cb98add260bd9c5be79c0/docs/audio-assets.json). The SHA-256 values are **file identities**, not authorship, license, public marketing clearance, or proof of playback in a future Godot build.

## How to bring the audio into the new native game safely

1. Verify **licensed/public usage and creator soundtrack selection** before distributing complete recordings or enabling a public audio player. Public source filenames do not establish a public-reuse license.
2. Preserve the five exact source hashes and track IDs in an audio migration fixture; copy/migrate original binaries only within a designated authorized project/branch after verifying exact bytes. Do not silently attach binary MP3 blobs to README PRs.
3. Implement a small Godot `AudioStreamPlayer` / music-bus adapter that accepts **title, opening, travel, combat, Ender theme** cue identities independent of cutscene/quest authority. Include user music volume, mute, no-auto-play until user intent, loop rules, reduced-sensory overload, and nonfatal missing-asset behavior.
4. Re-audit all scene routing against the newer creator order **Ender's employment flyer → Ionia recruitment → first flight → ocean splashdown → recovery → later Lyra/Talen reunion → provisional shared fuel theory**. Historical Lyra-first, Crossing and epilogue triggers are **not** the new scene timeline.
5. Keep Ionia's **former captain's shanty / a specific alignment melody** as a separate **story-music integration requirement**. It is a creator-approved narrative event, **not** evidence that one of these five existing recordings contains that melody. Test timed interactive melody/engine response only after composition and story timing are approved.
6. Bind the actual Godot audio stream/resource load, track change, clean looping, pause/mute accessibility and package-file hash in **exact-head native tests**, then capture actual build and listening QA. Neither historical JS audio tests nor text documentation alone proves this.

## Publication boundaries

- **Allowed now:** document the five historically admitted recordings, their archival branch, file paths and intended roles; link the current project gallery and tests.
- **Not claimed:** music is committed to `main`, audio is integrated in the native Godot branch, all recordings are publicly redistributable, an audio player is shipped, or the legacy *Aetherwake* titles are final new-game score names.
- **Still required:** copyright/source/reuse rights, soundtrack creative approval, native exact-binary import and music routing tests, platform audio performance, mixer accessibility and final narrative placement.

[Return to project overview](../README.md) · [Native Godot screenshot gallery](VISUAL_DEVELOPMENT_GALLERY.md) · [Current story integration work](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/491).
