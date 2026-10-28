# First Wake Native Music Bus — synthetic playback prototype

**Scope: opt-in development-lab audio mechanics only.** No original recorded music bytes, source license inference, final composition, Ionia/Denith shanty or full-game integration.

## Why this exists

The archived five supplied original recordings—**Skyward Arpeggio**, **Amonigio Umulula**, **Nocturnal Resolve**, **Solar Punk Airship**, and **Open Sky Signal**—are real files on historical unmerged Chapter One source [`1b1f5180`](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/tree/1b1f51806ea9d013433cb98add260bd9c5be79c0). The native story-cue preflight on [#527](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/527) passed [Godot CI #40629748880](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/actions/runs/40629748880) but does not yet load or play the actual archived audio in the forward engine.

The smallest reversible next step is to verify **Godot audio mixer mechanics and transition sequencing** against the real creator-directed First Wake state using only a *new original synthetic test signal*, not music that has not been re-admitted to the runtime.

## Native player proof

`godot/scripts/first_wake_synthetic_music_bus_review.gd` owns two **real AudioStreamPlayer** objects with one lightweight generated mono `AudioStreamWAV` per active channel (a single low-amplitude sine test waveform; no historical composition, lyrics, melody or MP3 samples). The bus has explicit `start_synthetic_preview`, `transition_synthetic`, `advance_fade`, `stop_preview`, `set_volume_percent`, `set_muted` and `set_preview_paused`.

- A track-candidate **selection** from the actual [forward story cue `tstss.review.first_wake_pipeline.v1`](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/491) loads **no sound**.
- Starting synthetic QA requires an exact named `isolated_godot_synthetic_music_fixture`, explicit start and `synthetic_only=true`; unexpected license flags or malformed proof are rejected. Only then a test WAV is created and played.
- The first stage uses the historical **Skyward Arpeggio title** track ID as a *data label*, without playing Skyward Arpeggio. Ionia's recruitment and engineering allow a fade to historical **Amonigio Umulula opening** ID, without playing Amonigio Umulula. The sounds are generic generated test signals with different frequencies solely so both channels can be distinguished.
- The bus uses a bounded linear gain crossfade with actual `AudioStreamPlayer.volume_db` levels, preserved user volume (0–100%), immediate mute, pause, deterministic fade progression and cleanup after completion.
- All producer/candidate restrictions from #527 remain: no unauthorized title music in engineering, no combat music from story presence, no automatic Ender leitmotif, no presumed Denith shanty, no save writes, and no audio-publication rights.
- The bus never loads MP3 resources and every snapshot explicitly flags `historical_mp3_loaded=false`, `real_recording_playback_verified=false`, `public_streaming_authorized=false`, `denith_shanty_verified=false`.

## Executable acceptance

`godot/tests/first_wake_synthetic_music_bus_test.gd` loads real `first_wake_job_preview.tscn`, the native story projection and five-track governed metadata; creates the bus in the scene tree and checks the **real engine** player/stream types, rejection of premature/invalid input, title-to-Ionia-engineering cue transition, exact half-way gain balance, mute/unmute, pause/unpause, no mid-transition reentry, termination, and lack of combat/canon/save/rights authority.

The pinned Godot 4.7.2 native workflow invokes the test and requires `TSTSS_FIRST_WAKE_SYNTH_MUSIC_BUS_PASS`. **Exact-head CI pending at document creation.** A headless Godot success will prove in-engine audio node and routing mechanics, **not real human-audible performance**, original MP3 playback or soundtrack editorial quality.

## Further admissions needed before actual game audio

1. Creator confirms rights/usage scope and approves the five recordings' **new** scene placements and any arrangement/mix transitions.
2. Import original archival MP3 **exact bytes** into a designated native Godot asset branch after SHA-256 and file-length verification. Do not copy them into a public README or preview build by default.
3. Replace synthetic stream factory with a separate resource loader that checks the governed file hashes before use and cleanly handles missing/invalid imports; add explicit title-on-gesture policy and real volume/music settings.
4. Verify real Godot MP3 decode, seek/loop/fade, scene reload, output-device routing, accessibility and packaging on Windows/Linux; test ears/speakers on actual target hardware.
5. Integrate Ender/Ionia/Lyra dialogue and scenes **after** a creator-approved safe post-splashdown recovery route. Preserve the later independent Ionia/Denith shanty harmony solution and story-energy/combat-magic separation.
6. Independently resolve unchanged Windows Defender custody preflight; no release or installer packaging from this review.

No change to public `main`, default Godot entry scene, canonical story, score binaries, native Windows release or reserved celestial lore.
