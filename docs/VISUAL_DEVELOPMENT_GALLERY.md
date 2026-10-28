# Native Godot visual development gallery — October 27, 2026

> **EXPERIMENTAL / REVIEW ONLY — NOT APPROVED ART OR A RELEASE.** Every image below is derived from an actual native Godot 4.7.2 rendering, not synthesized concept art. The screenshots come from **separate unmerged candidate branches** and should **not** be represented as one integrated playable build or approved visual baseline.

[Back to main README](../README.md) · [Visual bible](VISUAL_BIBLE.md) · [World/ship direction](WORLD_SHIP_VISUAL_DIRECTION.md) · [Character art authority](CHARACTER_AND_ART_AUTHORITY.md)

## Latest native First Wake → 3D Aureate Wake presentation study

These **four actual Godot 4.7.2 framebuffers**, captured at **960×640** in the separately verified 3D flight study, are now committed for durable review. They come from [draft PR #524](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/524), exact head `d6afcf7a3c94c841e6fd305f8aad5f5fbe603c75`; [Godot native GL workflow #40625082846](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/actions/runs/40625082846) **PASS**. The raw screenshot file identities were separately checked against exact SHA-256 values before importing original PNGs and review JPEGs. See the [new provenance manifest](screenshots/native-2026-10-27/first-wake-cues/provenance.json) and [original full-resolution PNGs](screenshots/native-2026-10-27/first-wake-cues/original/).

| First lift | Controlled descent |
| --- | --- |
| ![Actual native Godot 960×640 3D Aureate Wake first-lift cinematic preview; experimental ship over a synthetic ocean](screenshots/native-2026-10-27/first-wake-cues/first-lift.jpg) | ![Actual native Godot 960×640 3D Aureate Wake controlled-descent lighting preview; not water-physics proof](screenshots/native-2026-10-27/first-wake-cues/controlled-descent.jpg) |
| **Afloat presentation look** | **Shipboard recovery presentation look** |
| ![Actual native Godot 3D ship in provisional ocean-afloat environmental lighting; no production water collision certified](screenshots/native-2026-10-27/first-wake-cues/ocean-afloat-study.jpg) | ![Actual native Godot 3D ship under provisional recovery scene lighting; actual family reunion geography not shown](screenshots/native-2026-10-27/first-wake-cues/recovery-checks.jpg) |

**Visual QA:** The ship's four-wing silhouette and light/grade differences are readable, but it is relatively small in hero framing and the afloat/recovery stages remain visually too similar. No genuine 3D physics-confirmed splashdown, voyage, deck walk, or meeting with Lyra/Talen is visible. The overlay itself identifies this as **CONCEPT-ONLY**. Distinct RGB pixel samples and a passing renderer test are not artistic acceptance.

The 3D scene is an **independent Godot project root** from the forward chapter's tested [story/party/quest cue producer #491](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/491). The two have not yet executed in one production runtime. Weather/time choices are optional look studies, **not established plot weather**. The four newly committed images are from this 2026-10-27 CI run; the historical native screenshots below are from separate **older** drafts and should not be presented as one integrated build.

## Aureate Wake — hero silhouette and weather

The ship below is the **compact Aureate Wake**, not the larger, separate Dragonfly Frigate. Original procedural/native GDScript proposal in the experimental **combined ship + weather** branch, [draft PR #422](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/422) at `0ba35e6bd4e6acd4c5b7e880be1758d17feebab6`. This particular combined branch **does not automatically include later, independently stacked #419 geometry refinements**.

### Bow-quarter
![Real Godot 960 by 640 screenshot of Aureate Wake bow](screenshots/native-2026-10-27/aureate-wake-bow.jpg)

### Stern-quarter and overhead
![Real Godot screenshot of Aureate Wake stern](screenshots/native-2026-10-27/aureate-wake-stern.jpg)
![Real Godot screenshot of Aureate Wake wings viewed from above](screenshots/native-2026-10-27/aureate-wake-wings.jpg)

### Same-ship atmospheric variations
![Real Godot screenshot of Aureate Wake at blue hour in rain](screenshots/native-2026-10-27/aureate-wake-rain.jpg)
![Real Godot screenshot of Aureate Wake in storm and magical sky](screenshots/native-2026-10-27/aureate-wake-storm.jpg)

These images test camera angle, original wing/rig proposal, sky, fog and weather. Visual legibility, transparent-wing sorting, target hardware and creator artistic acceptance remain open.

## Terrain and biomes — native software-GL study

Captured from the **same #422 combined experimental run**, showing sample coast–forest–highland shots. Terrain rendering and contact tests do not certify a finished spherical world map, planetary navigation or final biome art.

### Coast at dusk
![Real Godot coast-at-dusk terrain screenshot](screenshots/native-2026-10-27/coast-dusk.jpg)

### Golden-hour forest
![Real Godot forest and understory review screenshot](screenshots/native-2026-10-27/forest-golden.jpg)

### Highland horizon
![Real Godot highland horizon screenshot](screenshots/native-2026-10-27/highland-horizon.jpg)

### Magical atmosphere
![Real Godot atmospheric night sky screenshot](screenshots/native-2026-10-27/storm-sky.jpg)

## Five Lights character lineup — *separate* native review branch

![Actual Godot character lineup preview, Ionia Ender Aepex Lyra Reson](screenshots/native-2026-10-27/five-lights-lineup.jpg)

From [draft PR #421](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/421), exact head `3ddd36b2c3b46ae7546da60e732905e665773fd9`. This **480×320 JPEG** is the bounded real native Godot renderer thumbnail embedded in the [capture-job log](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/actions/runs/40577322365), derived from an original 960×640 captured scene. It is **not** the unreleased full-resolution character framebuffer. These are unapproved candidate sprites; the game-specific character art and animations still need further development and creator review.

## Source custody and verification

| Evidence | Exact origin | Readiness meaning |
| --- | --- | --- |
| Ship / terrain / sky images | [Godot native CI run 40578319950](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/actions/runs/40578319950), [original 960×640 PNG capture artifact 12768611791](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/actions/runs/40578319950/artifacts/12768611791), [draft #422](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/422) | Native experimental run PASS; original frames retained below as PNG, README JPEGs are optimized derivatives |
| Five Lights lineup | [Godot native capture CI run 40577322365](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/actions/runs/40577322365), [draft #421](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/421) | Captured engine preview only; not accepted appearance or production animation |
| Publishing | **This documentation-only branch** | No gameplay code, canon, merge, executable package, or release authorization |

The accompanying [image provenance manifest](screenshots/native-2026-10-27/provenance.json) records the input PNG and output JPEG SHA-256 values. Full original-resolution **PNG captures** are preserved under [original/](screenshots/native-2026-10-27/original/) for ship and terrain images. The character lineup is preserved at the bounded JPEG preview resolution because the separate full-size image was not published as a reusable artifact.

## Review gates still open

- Creator accepts/rejects individual visuals, including ship identity, silhouette, wing transparency and proportion.
- Target Windows GPU validation, representative frame-time and VRAM profiling, accessibility/reduced-motion visual review.
- Character four-direction completeness, costume/gait/pose quality, approved source-asset provenance.
- Cross-branch integration, Godot gameplay/save/quest parity, player acceptance and any merge/release decision.

**Not a claim of completed cinematic visuals.** To update this gallery, use **new native Godot frames**, preserve exact run and source SHA, and separately record creator aesthetic approval.

## Music is already in the development ecosystem

Five original supplied Chapter One recordings are present as exact governed binary blobs in the historical, closed/unmerged [Chapter One convergence commit `1b1f5180`](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/tree/1b1f51806ea9d013433cb98add260bd9c5be79c0), including *Skyward Arpeggio*, *Amonigio Umulula*, *Nocturnal Resolve*, *Solar Punk Airship*, and *Open Sky Signal*. They are **not** present in the current `main` or yet integrated into the forward Godot music bus. [Read the verified music asset register](AUDIO_ASSET_REGISTER.md) for hashes, source roles and safe migration boundaries. No unlicensed audio player or streamed MP3 is embedded in this visual gallery.
