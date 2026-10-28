# Existing soundtrack → forward Godot First Wake cue preflight

**Classification:** read-only prototype contract, **NOT playback**; existing five original files are not copied into the native Godot project or public `main`.

## Source evidence
[Closed/unmerged historical Chapter I PR #151](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/151) at exact commit `1b1f51806ea9d013433cb98add260bd9c5be79c0` contains real Git blobs for five original MP3 recordings and a `docs/audio-assets.json` hash/byte manifest. The existing roles and checksums are copied into `godot/data/first_wake_existing_music_sources_v1.json` as **reference metadata only**:

| Track | Source role | Forward scene note |
| --- | --- | --- |
| Skyward Arpeggio | Title/menu | never automatically continue into Ionia's engine room |
| Amonigio Umulula | First Wake opening/cinematics | candidate context for job notice/engineering, no approved new placement |
| Nocturnal Resolve | Combat and danger | **not** triggered by story movement/quest cues; combat authority separate |
| Solar Punk Airship | Airship and travel | candidate for actual flight context, not proof of navigation |
| Open Sky Signal | Ender's First Note character leitmotif | must be explicitly cued by character event, never a generic ship/phase or Denith song |

These are **historical music roles**, not creator approvals of the revised Ionia-first screenplay. The late emotional shanty, sung by Ionia from Captain Denith's memory and recognized by Ender as an alignment sequence, remains a **distinct uncomposed/unverified music-story requirement**. Do not replace or spoil that reveal by claiming it equals an existing track.

## Smallest executable test

The `first_wake_existing_music_cue_contract.gd` reads the exact archival metadata and accepts only the `tstss.review.first_wake_pipeline.v1` **read-only prototype cue** produced by the actual Godot [First Wake #491](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/491). It guards against mixed story party order, unapproved live authority, unsupported scene/track matches, premature combat or Ender focus, and unknown source hashes. Its outputs contain source identities and explicit flags: `may_autoplay=false`, `native_audio_playback_proven=false`, `scene_placement_approved=false`, `public_streaming_authorized=false`, `story_shanty_composition_verified=false`.

A separate `verify_local_audio` preflight checks the anticipated future `res://audio/` path's **actual byte size and SHA-256** if present; missing files are `missing_in_forward_godot` and corrupt/forged paths are rejected. Even exact bytes do **not** grant playback/redistribution by themselves.

Native test `godot/tests/first_wake_existing_music_cue_test.gd` executes the real Ionia-first `first_wake_job_preview.tscn` and shared projection, checks all five real archive identities, the title-to-opening handoff proposal, fail-closed invalid story cues, denied combat/Ender/shanty shortcuts, and the absence of migrated MP3s in the new Godot root. Pinned Godot 4.7.2 hosted workflow invokes this with strict PASS receipt.

## Next admission gates
- [ ] Native exact-head CI **PASS** with no script errors.
- [ ] Decide creator-approved reuse/distribution/streaming rights and track placements for revised Chapter I.
- [ ] Migrate *exact* original binaries by SHA-256 and bytes, to a governed native Godot `res://audio` directory with resource import.
- [ ] Implement real `AudioStreamPlayer` bus, mute/volume/ducking, title stop-on-start, track transitions, subtitle/sensory accessibility and graceful missing-file fallback.
- [ ] Executed audio decoding, in-game actual audible playback, package copy and player/creator listening QA.
- [ ] Resolve the shanty's exact musical composition, sequence timing, engine response and relationship reveal **later** with creator oversight.

No JS-to-Godot route continuity or current downloadable game audio is implied by a passing data-contract test.
