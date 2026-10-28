# VFX prototype → production: Chapter I engine-warning visual pipeline

**Date:** 2026-10-27. **Status:** DOCUMENTATION-ONLY draft for cross-branch production admission, not a working production effect or merged Godot game. No public restricted late-game or celestial-route information. Source of authority: creator-established Ionia-first opening, independent Godot native physics/handoff and VFX review branches, and approved five protagonist *story energies* (distinct from learned combat magic).

## Executive decision

**First realistic production-entry slice: an in-engine Aureate Wake test-flight `warning` visual**. Reuse the deterministic VFX framework, light controls, camera/occlusion/HUD QA and cinematic-phase machinery from [draft VFX #411](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/411) and [admission-bridge #496](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/496), while taking **scene authority exclusively from [First Wake visual handoff #492](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/492)** and [physical landing #447](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/447). The engine cue requires **new, neutral engine-phase-drift art**, not a disguised Ender Spirit spell, a Lyra water spell, a resonance attack or automatic magic affinity unlock.

The actual Chapter I beat: Ender is hired by Capt. Ionia to assist with the Aureate Wake's harmonic levitation engine; Ionia joins first; the short first-flight test develops a phase problem, then controlled descent and splashdown. Lyra is introduced **after** the splashdown; the engine's true fuel and unrevealed specifications remain mysteries. Do not assume a canonical storm or a completed fuel formula. See [storyboard draft #425](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/425) and [native hiring/preflight #430](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/430). No new final dialogue is approved here.

## Exact source/evidence register — scope cannot be transferred between heads

| Claim/evidence | Verified source or tracked draft | Promotion limit |
| --- | --- | --- |
| Godot native target | Public `main` `AGENTS.md`; public `main` SHA `79b48718b0c8b5e7f0ae4d811d5ae12e1a436a09` | `main` is still historical JS/p5; there is no `godot/` on `main` |
| Five-affinity VFX + real Chapter I compositing | [#411](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/411) source `cfcb0d87b2949993ad0cfe17de728bbe9ccddd56`; [native visual evidence](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/actions/runs/40609024498) from executable `5d2fd636ff7cbfddef3402fcd2c063d5aee20800` | Real 960×640 render and 2D UI/Ender pixel QA, not a ship-engine visual or production art acceptance |
| Strict manual VFX request → real Chapter I preview | [#496](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/496) `72732792b553f3299e224f63a74d07791f6e56c5`; [Godot native admission](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/actions/runs/40613819461), [native render](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/actions/runs/40613819288) — **PASS** | Contract accepts only `manual_visual_review`; must **not** be repurposed as battle/story authorization |
| Authored opening and real local splashdown | [#430](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/430), [#447](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/447) | Local Godot 2D water-body/contact proof, not finished planetary-ocean physics or a production cinematic |
| Physical/story phase → camera descriptor | [#492](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/492) `2b9626220894a352925dfc267196f11211073aea`; [native handoff run](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/actions/runs/40612723948) | Review descriptors only, explicitly `executes_visuals=false`; no 3D scene or video playback composed into Chapter I |
| Ship weather/camera look study | [#486](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/486) `36a13d6063235ed2114bb25d2a2cc61d1d4c9f22` | Golden-clear first-flight default; storm is noncanonical opt-in lookdev |
| Resonance study | [#413](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/413) remains draft | No executable combat spell/combination granted by VFX or innate story energies |

**Important:** #492 and #496 are on **different Godot source lineages**. A successful test on each does **not** constitute a tested combined executable. The production seam below is the **next proposed integration** and requires explicit ancestry/diff reconciliation before code staging.

## Architecture to build (PROPOSED)

```text
authoritative First Wake FSM + real local flight contact
     → #492 validated phase descriptor (party Ender+Ionia, actual story_step,
       source camera, golden-clear grade, no invented fuel, no premature Lyra)
     → NEW visual-only engine cue router (accept only phase=warning;
       reject forged state; never mutate FSM, party, save or combat)
     → original neutral ENGINE phase-drift light/material (new art admission)
       using shared VFX budget, deterministic timeline, reduced motion
     → real chapter camera/foreground/HUD and water flight transition
     → native 960x640 A/B render + source-locked validation
```

**Do not** directly feed a #492 `warning` descriptor into #496's `manual_visual_review` contract or widen its channel to `story_energy_auto`; that manual-only interface is intentionally fail-closed. Create a separate, explicitly scoped presentation consumer after the narrative FSM attests to the event. Distinguish engine status illumination from the five protagonist elemental signatures and keep the Five Lights/celestial routes outside public tests.

### Proposed reversible test PW-01 (first combined Godot production-path rehearsal)

1. Select **one** candidate Godot integration ancestor; record PR base/head, commit tree, GDScript import and all transitive VFX + flight/scene assets. Do not merge the existing drafts by implication.
2. Instantiate real [#447] preflight/flight/water scene. Only a *valid* [#492] descriptor at **`warning`** may schedule a noncombat engine visual cue. At `awaiting_launch`, `ascent`, `descent`, `waterborne`, a forged party/contact or any fuel assertion must not trigger that specific warning visual.
3. Render the warning cue beside the Aureate Wake's actual engine/bridge review geometry under **golden-clear first-flight conditions**, using a five-phase deterministic VFX timeline. Do **not** show Lyra or transform the cue into Ender's Spirit casting.
4. Verify **frame-accurate visual onset**, one-shot/repeat safety, pause/skip/reduced-motion fallback, visibility at small/large UI scale and dark/mist optional stress looks. Keep the camera, dialogue UI and foreground readable. Motion-safe preset must remain the default; no mandatory shakes/flashes.
5. On VFX missing/disabled or media/renderer failure, preserve live first-flight warnings, controller input, physics descent and buoyant water contact. Compare Chapter I quest/party/save snapshots and actual `RigidBody2D`/`Area2D` states against the no-VFX baseline.
6. Prove native renderer actual frames, color/light/occlusion deltas, HUD contrast and Ender silhouette, with immutable manifest + SHA-256. Existing **review-only** sample baselines: Ender 1166/1169 silhouette pixels preserved; native HUD median >=4.5:1 and 10th-percentile >=3.5:1 image-space engineering gates across four presets. Those are not formal WCAG or target-device acceptance.
7. Run a representative Windows GPU profile and installed launch, with exact source and performance budgets set/reviewed before deciding PASS. Existing Defender real-time protection failure must remain blocking; do not weaken host custody for convenience.

**Proposed PASS:** genuine single-scene integrated Godot video/scene review, deterministic cue tied to legitimate warning, A/B pixel proof, safe skip and missing-asset fallback, no story/save/combat authorization drift, no character/showcase leakage. **No PASS solely from** schema lint, shader compilation, CI success on separate branches, hash presence, or screenshots not viewed by an independent artist.

## PW-01 first native combined implementation candidate (2026-10-27; stacked review)

[Draft PR #519](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/519) now stages the first **real shared local scene** using a **live #492 flight/physics FSM** with a neutral visual-engine phase-drift overlay attached to the actual 2D ship body. This changes the previous status of PW-01 from *not implemented* to **IMPLEMENTED FOR NATIVE REVIEW, NOT PRODUCTION ADMITTED** on a **separate Godot branch**. It reuses #411's low-cost radial shader and five-phase animation techniques, but **not** the five-character magic catalog, protagonist spell privileges or #496's manual-only interface; the engine glow has a separate visual identity. Its intentionally restricted `warning` trigger comes from real `first_wake_cinematic_handoff.gd` output, not arbitrary scene playback.

- **Source and evidence:** initial #519 commit `81ef6ba89408df7bda25dc04ec79fbd7d45ca9be` passed its real GL capture; its [native contract #40624508325](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/actions/runs/40624508325) **failed** a bad test fixture (`float("nan")` not genuine NaN), not the renderer. The corrected executable source `34b722727e9c69d6b6305beb9aedae674f7780d2` then **PASSED** [Godot 4.7.2 native test #40624631273](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/actions/runs/40624631273) with `TSTSS_PW01_ENGINE_VFX_PASS` and **57 passing checks across 3 full real physics splashdowns** (enabled, disabled, interrupted); [actual native GL capture #40624631246](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/actions/runs/40624631246) passed, logged SHA-256s for all six 960×640 frames, and compared warning-on/off, interruption and HUD regions; [repository smoke #40624631268](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/actions/runs/40624631268) passed. Full-size art remains runner-local under artifact-quota restrictions. Native Linux proofs do not clear Windows security, production 3D flight or art acceptance.
- **Scope:** real local 2D Chapter I Ionia-first launch, legitimate phase-warning visual, on/off/interrupted preview, real controlled descent and Area2D buoyant settlement. Art is provisional, no rendered 3D Aureate Wake model, no calibrated GPU frame-time, no new fuel knowledge, no auto-combat spells or hidden route cues.
- **Next promotion test:** confirm revised native 3× complete physics trials and exact-head GL capture, then independently inspect original-resolution frames, exercise missing-asset fallback, representative Windows GPU profiler, dialogue/camera framing, and completed Chapter I handoff. Existing Windows Defender security hold remains independent. Never merge or release from these isolated receipts alone.

## PW-02 live 3D Aureate Wake camera-inset pilot — 2026-10-28

[Stacked draft PR #529](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/529) now implements an **actual** `Camera3D` + isolated `SubViewport` inside the same Godot PW-01 Ionia-first real physics scene. It reuses the **verbatim procedural 3D hull/wing/stern/HelmGlass *candidate*** from frozen original [Aureate Wake art-study #486](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/486), not an independently invented or accepted production ship. The stern engine ring/OmniLight3D is switched strictly by the original authorized 2D `warning` presentation, OFF when disabled/interrupted, while the real `RigidBody2D`/`Area2D` continues to physically settle in water with unchanged narrative/save authority. This is a **fixed 428×240 3D camera inset in a 960×640 review**, NOT full 3D navigation or 3D splashdown.

**Exact executable SHA** `14139d1d0e149be0e9cd04746f9506b32d71941b`: [real Godot 4.7.2 native integration #40630176921](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/actions/runs/40630176921) **PASS**; [real GL capture #40630176985](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/actions/runs/40630176985) **PASS**, five actual 960×640 frames, local 3D ON/OFF pixels differ, OFF=INTERRUPTED, protected HUD identical; [repository smoke #40630176942](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/actions/runs/40630176942) **PASS**. Full PNG art inspection is still pending. [PW-02 documentation and limits](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/blob/test/first-wake-engine-warning-3d-inset-pw02-20261028/docs/prototypes/FIRST_WAKE_REAL_3D_INSET_PW02_2026-10-28.md).

**Next production frontier:** real 3D bow/bridge/engine composite occupying the actual Chapter I cinematography, provenance-reviewed *geodesic* bridge/dome design (the reused `HelmGlass` is merely a small legacy candidate), occlusion and camera transition tests; original 3D hull physics only if explicitly built and verified. Frame-time, VRAM, representative Windows GPU, accessibility/player and artist acceptance all pending. [Exact Windows QA #40630176919](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/actions/runs/40630176919) still fails its **unchanged Defender real-time-protection security preflight**, no bypass. All branches draft/unmerged, no production/release claim.

## Production admission gates

| Gate | Current evidence | Needed before a production claim |
| --- | --- | --- |
| P0 — isolation and source lineage | #411, #496, #492 individually tested | Shared dependency manifest, diff, one exact combined source head; no staging conflicts |
| P1 — real first-flight cue | **PW-01 native 2D review PASS at 34b72272** | Creator visual QA and an actual production ship/3D review still required; not a finished story cinematic |
| P2 — visual and accessibility | **PW-02 live 3D ship candidate inset/native pixels PASS**; earlier dock VFX/HUD passes | Full-screen scene transitions, actually approved geodesic helm, frame inspection, user accessibility and creator art acceptance are still pending |
| P3 — logic and continuity | **PW-01 enabled/disabled/interrupted physical runs PASS** | Full Chapter I save round-trip, real gameplay handoff, skip/controller/accessibility and 3D ocean integration remain separate |
| P4 — quality/performance | No representative combined-platform measurements | Specific hardware FPS/frame-time, quality tier/VRAM/thermal baseline and GPU-effect budgets; regression tests |
| P5 — Windows/published artifact | Exact Windows security preflight reports Defender disabled | Protected QA runner, installed launch, user playtest, per-commit receipts; no bypass |
| P6 — approval | All referenced PRs draft/unmerged | Creator signoff on canon/art, reviewed Godot migration, explicit merge/release authorization |

## Documentation updates and owner-of-truth

| Destination | Update or reconcile | Authority |
| --- | --- | --- |
| This file | Production pilot `PW-01`, gated handoff, exact PR/source lineage | **DESIGN PROPOSAL** until same-source native scene run |
| `docs/GODOT_MIGRATION_COORDINATION.md` | Add #411 → #496 as visual contract, #447 → #492 as physical/shot contract, note their **separate ancestry** | Verified branch routing |
| `docs/AGENT_HANDOFF_INDEX.md` | Link this production gate and flag read-only versus executable | Routing, not new canon |
| `docs/MAGIC_SYSTEM.md` | Separate **fundamental plot energies** Ender Spirit, Lyra Water + pink spirit-light, Ionia Earth, Reson Fire, Aepex Air from existing magical-domain affinities and magic jobs | **CREATOR CANON** vs historical formal-domain research |
| `docs/CANON_AND_REVEAL_POLICY.md` | Correct **Ionia joins before Lyra** in approved forward First Wake; retain old Lyra-first test as legacy-only | **CREATOR APPROVED** narrative direction; code still migration |
| `docs/CINEMATIC_CLIP_CONTRACT.md` | Distinguish in-engine VFX cues from 5–15s prerenders; media failure must never alter Chapter I physics/story; use 2026 Godot target, not legacy JS manifest as proof | Cinema presentation policy |
| `docs/PREVIEW_0_1_ACCEPTANCE.md` | Mark old JS installer/source binding as **historical**, never evidence of current Godot acceptance; new PW-01 checklist | Acceptance history/QA |
| `docs/NOTION_SOURCE_INDEX.md` + Notion ledger | Add public-safe provenance links, owners, gate states, conflict/hold record | Private Notion = richer working ledger; public repo = sanitized handoff |
| `docs/MAGIC_VFX_CHAPTER1_CAMERA_REVIEW.md`, #411 + #496 | Continue exact-source shader/asset/silhouette/contrast/native render evidence; distinguish 2D dock from engine/ship pilot | Actual VFX test evidence |
| [#492 prototype handoff doc](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/492) | Future PW-01 adapter contract, temporal/fallback gates, optional storm hold | Story/physics/camera descriptor authority |

**No automatic changes** to canonical ability trees, five protagonist jobs, ship hidden configurations, private late-game navigation, globally playable combat or Windows packaging. Reject contradictory/older lore rather than flattening it.
