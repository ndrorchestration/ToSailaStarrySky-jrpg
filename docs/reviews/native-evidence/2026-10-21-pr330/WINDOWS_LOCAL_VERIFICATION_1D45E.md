# PR #330 — consolidated Windows verification at code head 1d45e7c
**Date:** 2026-10-21 · **Status:** operator-local engineering evidence, not release or creator acceptance

## Subject and environment
- Verified code head: `1d45e7cdf5f67785deaeedd9cfefa53319ab8efe`
- Authorized host: `neontic` (Windows)
- Disposable checkout: `C:\Temp\aetherwake-pr330-verify`
- Engine: Godot `4.7.2.stable.official.ed1daf0bf`
- Renderer capture: OpenGL 3.3 Compatibility, Intel Iris Xe
- Official Godot ZIP SHA-512 matched the release `SHA512-SUMS.txt`:
  `83decd58fdf67b9d657958a1ae6bf1929c20785315a81effe245874cdc57acb709bf868e00778a96984338c1b29dafdb453c6847747694621c6ecf5da2259993`

A fresh disposable checkout initially lacked a populated `.godot/imported` cache. After an editor filesystem/import scan, scene resources loaded normally. That initial failure was an import-cache/environment issue and is not counted as a gameplay failure.

## Exact-head native contracts — PASS
All commands exited 0 at the code head above:
- `AETHERWAKE_CHOICE_STATE_PASS` — gated, exclusive deterministic consequences
- `AETHERWAKE_ECHO_ENCOUNTER_PASS` — guard on warned pulse builds echo; quiet strike cashes it; blind attacking fails
- `AETHERWAKE_PROMPT_MODEL_PASS` — objectives and nearby actions are explicit and binding-aware
- `AETHERWAKE_INPUT_POLICY_PASS` — keyboard/controller defaults exist; custom remaps are preserved
- `AETHERWAKE_SIGNAL_AUDIO_PASS` — original procedural question/answer PCM is generated; no external melody/audio asset
- `AETHERWAKE_ACCESSIBILITY_PASS` — text sizing, reduced motion, trace opt-out, dialogue cancel and safe retry
- `AETHERWAKE_VERTICAL_SLICE_PASS` — real scene, both paths, encounter pause/resume and both payoff states

Headless scene QA intentionally disables playback because Godot's dummy audio driver retains WAV playback objects until process shutdown; audio generation is tested separately. The real renderer path retains audio-enabled scene construction. With this separation, headless scene tests complete without ObjectDB leak warnings.

## Exact-head native renderer — PASS
Real 960×640 OpenGL captures:
| State | SHA-256 |
| --- | --- |
| Discovery | `26bb80c09d8140ce74a0a39cfae1749e6f4523f2c8eca2806b85ee6e9d159734` |
| Ionia choice | `6ff8ec317367dd56089fafac4b18e0157d70b65304a6c225386bb10d29bb908e` |
| Encounter warning | `32e8c2214c955ebbdcefa56e9aca41b1f753f833af4b08d3b4fb1a8a60cd652a` |
| Echo ready | `f6cfc098ed5d55d2c4d51ea5e021245fb633a5d538d6c7dd4a61535ffc77fd07` |
| Beacon payoff | `97782defc9b839a947977982f5ca0e153b5e8dc6a8a918534d5f91e266337e56` |

Renderer assertion: `AETHERWAKE_SLICE_NATIVE_RENDER_PASS: discovery, dialogue, guard warning, echo-ready and payoff are visually distinct 960x640 frames`.

Direct inspection confirms:
- warning now visibly says **GUARD** and uses a distinct warm pulse ring;
- after guarding, **ECHO / STRIKE** has a separate ring and text state;
- beacon payoff adds layered glow plus a distant responding vessel/light;
- optional post-payoff Ionia interaction is signposted without blocking completion;
- UI remains readable at 960×640 and no essential cue relies on color or sound alone.

These are engineering/visual-review observations, not creator artistic acceptance.

## Hosted CI status — blocked before execution
GitHub check annotations at the review branch explicitly state that jobs were not started because recent account payments failed or the Actions spending limit needs to be increased. This is an account/billing execution block, not a hosted test result. The Ubuntu runner migration notice is informational.

**Hosted exact-head verification remains NOT ESTABLISHED** until billing/limit is resolved and the jobs actually execute.

## Research-guided changes now represented
- stage-aware interaction prompts;
- named keyboard/controller actions that preserve later remapping;
- short guard→echo→strike loop instead of decorative warning;
- original two-note call/answer signal motif with mute-safe visuals;
- visible return-state world response;
- optional companion reaction after payoff;
- five-state native renderer evidence.

Interim evidence synthesis: `docs/research/AETHERWAKE_JRPG_EXCELLENCE_INTERIM_2026-10-21.md`. Exhaustive Deep Research remains pending.

## Boundaries
No merge, production migration, creator art/canon approval, field-pack admission, Defender #293 clearance, independent player validation or release authorization is claimed. #326 art/dialogue and #328/#329 gait evidence remain separate.
