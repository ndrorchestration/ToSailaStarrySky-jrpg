# To Sail the Starry Sky — current Godot implementation and evidence register

**As of October 28, 2026. Status: native Chapter I review; draft, unmerged, pre-alpha.** This register describes what is checked in the **stacked Godot review branch behind [draft README PR #564](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/564)**, **not** the default `main` build or any approved Windows release. Recheck exact branch/head before relying on any CI claims.

## Current playable build

- **Entry:** `godot/project.godot` (Godot **4.7.2**, configured `res://scenes/first_wake_chapter1_player_preview.tscn`).
- **Original configured Chapter I:** remains intact, opt-in revised route entered with **F8** and returned without overwriting its original volatile v1 model. The old scene has its own isolated **F5/F9 save/load** and combat formula review; it is not the new Ionia-first story.
- **Creator-directed revised Chapter I:** Ender seeks work → Ionia employment/recruitment **first** → engineering and controlled first flight → local `RigidBody2D` water contact/berth recovery → safe Lyra/Talen reunion and Lyra recruitment **second** → independently sourced provisional fuel theory → two physically walkable salvage review regions with actual source pickup receipts → manual installation and failed engine restart → Denith shanty and harmonic-analysis **bench-only** candidate. The revised sequence is implemented as connected review scenes; final dialogue/art/canon promotion is separate.
- **Checkpointing:** dedicated isolated **salvage v3** JSON at `user://first_wake_salvage_review_v3.json`. Press **K/L** in the salvage area, or **J** from an untouched revised dock to resume a prior checkpoint. Strict validator, bounded position/area/material receipts and backup recovery are test-covered. **No** v3 save inside flight, engine workshop, failed restart or melody; local user files are not cryptographically authentic. Original v1 and preflight v2 formats remain unchanged.
- **Combat:** a native Ender four-formula subset `staffStrike`, `uncoverTruth`, `hold`, `rest`, constrained by separate `first_wake_party_combat_authority.gd`. The old Crossing party authority still names Ender/Lyra and does **not** grant a Lyra/Ionia turn; it has **not** been silently made into new revised-Chapter-I party authority. The separate deterministic **Guard / Strike / Echo** scene is a review experiment, not the final battle system.
- **Resonance:** design catalog, shared metadata and review-only reservation preflight; the cross-story composite never executes a production Art (`canExecute=false`). Training-lab visuals and trial effects must not be mistaken for real Chapter I spell/roster unlocks.
- **Visuals:** October 28 `docs/reviews/native-evidence/2026-10-28-first-wake/chapter1-six-native-stage-frames.svg` embeds six real 960×640 native-frame PNGs; hashes and capture provenance are archived beside it. Their provisional hull/deck/character materials are **not** approved final cinematic graphics. Earlier October 21 character directional reviews are independently dated.

## Exact-head test and security evidence

| Native / preservation check | Evidence | Outcome and limit |
|---|---|---|
| Godot gameplay, story, v3 checkpoint, original-route isolation | [Godot First Wake run #40649372371](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/actions/runs/40649372371) | **SUCCESS** at prior exact-head `7ae50c697f6e74dc2dee5c36bea881c5d8bdfc1a`; not a production gameplay/visual acceptance or test of future documentation changes. |
| Godot native screenshot capture | [Render run #40649372369](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/actions/runs/40649372369) and [source-hash receipts](reviews/native-evidence/2026-10-28-first-wake/README.md) | **SUCCESS** at prior source head; six full 960×640 frames preserved losslessly in a review contact sheet, not separate packaged PNG player assets. |
| Browser and documentation SSOT | [Aetherwake smoke #40652983096](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/actions/runs/40652983096) | **SUCCESS** at `b37198f7c517d77baceb3350f08043236058eaaf` after stale literal README assertions were corrected. Later branch commits need their own checks. |
| Windows release/security | [Exact Windows QA #40649372357](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/actions/runs/40649372357) | **FAIL / BLOCKED at unchanged Defender custody preflight**. Some functional prerequisites passed; **no current installer approval**. Do not bypass, whitelist, sign or publish as cleared. |

## Current gaps and required gates

1. **Visual fidelity:** the native filmic lighting, environment depth, weather and ocean materials, detailed Aureate Wake 3D/2.5D silhouette and ship modes, Lyra/Talen approved sprites, camera language, original VFX and cohesive cinematic assets are not demonstrated by the real first-wake screenshots. Approve through native render review and uncoached play.
2. **World/exploration:** no verified production planetary globe, layered atmospheric navigation, full sea/submersible/near-exosphere ship transformation, auroral ladder traversal or lunar travel is demonstrated by the local `RigidBody2D` water prototype. These are long-term design scopes.
3. **Narrative:** Denith shanty note/audio, complete later chapters, final fuel specifics, any new story-bound Art unlock and cutscene timing require creator story/canon review. Talen remains noncombat.
4. **Combat/party:** no native five-character production battle UX, fully authorized Lyra/Ionia/Reson/Aepex attacks, school/job/weapon trees, complete shared resource/turn resolver, or live Dual/Triple Arts; keep narrative Lights independent of combat magic.
5. **Progress saves:** the v3 checkpoint is deliberately limited to the two salvage areas; persistent post-installation through melody, full production inventory and reusable versioned slots need separate implementation and QA.
6. **Distribution:** blocked Windows Defender custody gate, installer provenance/signing and real player acceptability remain independent. A passing native render test never clears release.

## Important paths

- [Playable nested Godot project](../godot/project.godot)
- [Creator-directed revised opening contract](../godot/scripts/first_wake_revised_opening_contract.gd)
- [Native four-formula contract](../godot/scripts/first_wake_combat_formula.gd)
- [Separate formula-turn authority](../godot/scripts/first_wake_party_combat_authority.gd)
- [Story→Resonance admission that cannot execute](../godot/scripts/first_wake_resonance_composite_preflight.gd)
- [Distinct v3 checkpoint boundaries](FIRST_WAKE_SALVAGE_V3_CHECKPOINT_PILOT.md)
- [Historical browser-compatibility README](archive/AETHERWAKE_BROWSER_PRESERVATION_README_2026-10-28.md)
- [Project visual authority](VISUAL_BIBLE.md)
- [README](../README.md)

**Control and merging:** documentation corrections can be committed to the existing review branch; no changes to `main`, installer release, story canon, or production combat execution are implied. This is a dated audit, not an automatically updated live dashboard.
