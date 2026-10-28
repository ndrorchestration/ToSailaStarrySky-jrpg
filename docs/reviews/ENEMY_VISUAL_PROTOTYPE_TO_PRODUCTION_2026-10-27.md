# Enemy visuals — prototype → production admission (2026-10-27)

**Authority:** public-safe engineering/QA handoff. **Status:** PROPOSED integration contract + evidence inventory, **not** canon, enemy-placement approval, a Godot migration merge, or art/release acceptance. The forward engine is Godot 4.7.2/GDScript; `main` still preserves the historical JS playable baseline.

## 1. What can be carried forward

| Candidate | Existing evidence | Portable production-facing output | Status |
|---|---|---|---|
| Original Wind Shear/“Harmonic Shear Elemental” graphics | [Draft PR #410](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/410): original v1 4-state and v2 4-pose 80×92 RGBA atlases, editable Pillow authoring sources and SHA receipts | Versioned `EnemyVisualDefinition`: asset IDs, frame rects, animation clocks, provenance/licence, fallback; **no enemy species added** | Prototype source **VERIFIED**, visual approval **PENDING** |
| Presentation-only state machine | #410 uses `windShear` ID, observed HP changes, analyzed flag, Gale Force turn counter, cleared flag; reduced motion | Reusable `EnemyVisualPresenter` that consumes **read-only resolved combat events**; never owns battle math or save/quest writes | Existing implementation **VERIFIED** in its legacy scene; cross-scene adapter **NOT BUILT** |
| Coherent battle staging | #410 flat-vs-lit A/B: low-alpha teal atmosphere, depth rails, hover horizon, separate HP meter, no adjoining UI pixels changed | Reusable scene layer slots: background, environmental depth, enemy, VFX, HP/status, commands, cinematic overlay | Native A/B **VERIFIED**; environment-lighting production generalization **PROPOSAL** |
| Response choreography | Real HP loss → 0.24 s impact; already-resolved Gale → 0.34 s post-hit effect; no fabricated anticipation | Generic finite-state VFX queue with event identity, no replay of damage, no projected hits | **VERIFIED** for existing Wind Shear formula action |
| Screenshot/QA harness | #410 10 native 960×640 captures, static/reduced-motion parity, actual post-hit image hash, exact protected-UI crop comparison; bounded log-only previews | Parameterized source-hashed capture manifest and comparison harness for every representative foe and benchmark scene | **VERIFIED** for one enemy, generalization **PROPOSAL** |
| Staff-attack visual integration | [Draft PR #493](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/493) proves actual `staffStrike` consumed as read-only visual test-sidecar | A **single authoritative combat resolution** can drive weapon impact and enemy VFX without a second turn | Prototype **VERIFIED** in #493; no runtime event bus or approved sprite installed |
| Story–party–ship projections | [Draft PR #491](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/491) exposes read-only revised First Wake story/party/ship/visual cues | Only attach an enemy to a forward quest/scene after creator-approved encounter placement and party-authority checks | Projection **VERIFIED** on its draft; no combat-placement approval |

The enemy's pixel art, shaders/depth cues and test infrastructure can be **extracted independently**. Do **not** cherry-pick #410's old `first_wake_chapter1_review.gd`, `first_wake_chapter1_state.gd` or `first_wake_party_combat_authority.gd` wholesale into the new opening. The old preview visibly labels `ACTIVE ENDER + LYRA`; [creator-directed #425](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/425) and [native #430](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/430) instead recruit **Ionia first**, and **Lyra only after splashdown**.

## 2. Smallest reversible architecture test

**P0: Isolated enemy-art viewer, no story.** Instantiate only `godot/scripts/first_wake_wind_shear_visual.gd`, import both atlases, and exercise idle 0–3, analyzed, genuine-damage callback, already-resolved Gale, cleared, reduced motion and reset. No `ChapterState`, roster, ship or saves may be loaded. [PR #410](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/410) now includes `godot/tests/wind_shear_visual_portability_test.gd` and a native hosted CI step; **verify that exact commit's run before calling it PASS**.

**P1: Neutral Battle Lab.** A new Godot review-only scene mounts the presenter beside the existing formula/weapon animation contract, with an **existing authorized** opponent fixture. Consume immutable *post-resolution* snapshots, not button presses. Retain the original player command/status UI; log the one accepted battle transition and matching one visual receipt. This is **NOT IMPLEMENTED** by P0 and should not be described as playable Chapter I combat placement.

**Suggested read-only event envelope (PROPOSAL)**

```text
CombatResolutionVisualCueV1 {
  source_scene_id, encounter_id, resolution_id, enemy_id,
  actor_id, authorized_action_id, enemy_hp_before, enemy_hp_after,
  enemy_turns_before, enemy_turns_after,
  analyzed_before, analyzed_after, cleared,
  presentation_sequence, reduced_motion
}
```

Guards: exact version and IDs, monotonically unique `resolution_id`, numeric HP bounds, no `damage` inference when HP does not fall, no retaliation effect without a recorded enemy turn, no replay after cancel/load, and explicit fallback when animation artwork is missing. **No visuals may grant, reroll, change, delay, or retroactively erase a combat result.** This envelope is an interface design, not a claim that the production event bus exists.

**P2: True revised-story vertical slice.** After the new Ender → Ionia → engineering → first-flight/splashdown → Lyra sequence and party/save gates exist, bind an approved encounter to a deliberate story location. Whether Wind Shear belongs in Chapter I is **OPEN**. Avoid implicit combat magic for story-only Five Lights/elemental energies; character affinities are not class/skill permissions.

**P3: Production candidate.** Port the reviewed scene+assets into the selected Godot main integration branch with an asset manifest, deterministic replay tests, controller/keyboard/text accessibility, target-hardware performance and creator signoff. Merge/release are separate human authorization gates.

## 3. CI and evidence gates (do not collapse categories)

| Gate | Pass evidence | Present result |
|---|---|---|
| Source & art provenance | Exact head, source PNG/GDScript hashes, original layered/editable art, attribution, reproducible import, asset dimensions | **PASS for #410 candidate**, not final art |
| Standalone portability | Godot 4.7.2 native import + story-independent SceneTree regression; missing asset and invalid identity should fail safely | **IN PROGRESS**: separate test written on #410, check exact-head CI |
| Combat truth | Exactly one real authorized `staffStrike`; unchanged formula, party, HP, VIT and turn authorization; duplicate/stale event rejection | Existing #410/#493 receipts are **partial**; production adapter **OPEN** |
| Native visuals | Native 960×640 still/motion, source SHA, four idle states, exposed weakness, hit→Gale, dispersal, UI overlap and depth A/B | #410 **PASS** for 10-frame study; **not** general battle certification |
| Accessibility | Exact frozen still at reduced motion, no camera strobe; text/HP noncolor cues, keyboard/controller focus, visibility at 1×/scaled presentation | Reduced-motion static parity **PASS**; full interaction review **OPEN** |
| Cinematic/style | Silhouette/readability, enemy–party spatial grounding, compatible pixel density and visual Bible lighting; direct human inspection of unedited captures | Limited visual review done; creator approval **OPEN** |
| Performance | Capture GPU/CPU frame time, redraw cost, memory, particle counts on agreed target hardware; establish 60 FPS target *if creator approves* | **NOT MEASURED** |
| Windows custody | Unchanged Windows Defender host security preflight, export, clean install and launch verification | Strict hosted Defender gate **FAIL / HOLD**; do not bypass |
| Canon/story | Explicit encounter placement and current roster semantics; Ionia-first + Lyra-after-splashdown preserved | **BLOCKED** until revised story sequence and placement approval |
| Promotion | Human visual/QA signoff, integration PR, authorized merge and release | **NOT APPROVED** |

Keep **source**, **native contract**, **native visual**, **target hardware**, **creator acceptance** and **release** receipts separately. CI-green never means aesthetic approval. Source-hashed screenshot log previews are useful under artifact quota restrictions but should eventually be stored in a durable, controlled review location with privacy/reveal checks.

## 4. Documentation & ownership reconciliation

| Document | Required update | Owner / approval boundary |
|---|---|---|
| **This file** | Source → architecture mapping, tested states, gates, status/SHAs, PR lineage | Engineering + QA; this doc does not approve canon |
| `docs/GODOT_MIGRATION_COORDINATION.md` | Register #410 alongside #491/#493 as **separate extraction tracks** and explain dependency order | Godot integration lead |
| `docs/VISUAL_BIBLE.md` | Link this candidate under combat presentation; clarify authenticated post-hit VFX vs **future** telegraph, relative pixel scale, source provenance and accessibility | Art direction; Bible stays canonical, *enemy sprite does not* |
| `docs/VISUAL_BENCHMARK_SCENE.md` | Add one representative **combat** benchmark companion to dusk dock; do not mislabel a migration review as production-quality screenshot | Art + UX |
| `docs/DEVELOPMENT.md` / `godot/README.md` | Flag legacy JS vs forward Godot and provide exact command/CI receipt for standalone test. Do not declare default Godot game playable or save-migrated. | Engineering/production |
| `docs/NOTION_SOURCE_INDEX.md` and Notion **Visual Bible**, **Cinematic Development Ledger**, **Chapter I Reboard** | Link read-only implementation evidence and status; flag Ionia-first contradiction as unresolved placement, not a new encounter | Narrative, art, project management |
| `godot/art-review/WIND_SHEAR_VISUAL_V0_REVIEW.md` in #410 | Preserve asset/provenance hashes, native A/B images, text/HP tests, story-independent test path, actual screenshot review, outstanding human gates | Enemy visual art owner |
| CI / test evidence | Add isolated test, native screenshot manifests, no event replay, 1× scaled QA, and performance instrumentation when targets are known | QA / platform security |

Historical `Aetherwake` and `Dragonfly` references in older files are **provenance**, not instruction to overwrite the current public title or ship name. Avoid unrelated wholesale renames on the documentation-only branch; reconcile each reference to the [canon policy](../CANON_AND_REVEAL_POLICY.md) and appropriate author-approved ship assets.

## 5. Promotion decision

**Safe to extract now:** enemy-only atlases + source, presentation GDScript, verified battle HUD layout rules, native capture harness and tests. **Not safe to promote:** old Crossing encounter timing, Lyra-first party, unapproved creature appearance, fake pre-hit anticipation, planet/ship effects, target performance claims, Windows release or merged production art.

**Next proof to seek:** a **single story-independent Godot enemy visual SceneTree PASS**, then a neutral battle lab where **one** approved damage resolution triggers both weapon and enemy visuals once; finally reconcile approved story placement before binding the scene to the revised playable Chapter I.
