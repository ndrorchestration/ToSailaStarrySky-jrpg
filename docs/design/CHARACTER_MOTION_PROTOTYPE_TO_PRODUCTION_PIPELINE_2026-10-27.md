# Character Motion & Visuals — Prototype-to-Production Admission Pipeline

**Status (2026-10-27):** `DESIGN_CONTRACT_PROPOSED`; `NATIVE_ISOLATED_PROTOTYPE_VERIFIED`; `MAIN_RUNTIME_INTEGRATION=NOT_DONE`; `ART_ACCEPTANCE=NOT_APPROVED`; `MERGE=HOLD`; `RELEASE=HOLD`.

This is a **public-safe documentation bridge on historical JS `main`**, not proof the Godot character assets or tests are merged there. Forward gameplay target: **Godot 4.7.2 / GDScript**. Read [character creator authority](../CHARACTER_AND_ART_AUTHORITY.md), [visual bible](../VISUAL_BIBLE.md), [Godot coordination](../GODOT_MIGRATION_COORDINATION.md), and [canon/reveal policy](../CANON_AND_REVEAL_POLICY.md) first. Current native character evidence lives in *stacked draft PRs*, not on `main`.

## 1. Evidence inventory — reusable vs not yet accepted

| Component | Exact candidate / evidence | Reuse in main design | Admission blocker |
| --- | --- | --- | --- |
| Five Lights comparison stage | [#409](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/409), [#421](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/421) | Character registry, source custody, 960×640 visual comparison | Art still candidate; cannot imply approved outfits |
| Four-way 6-frame Lyra/Aepex/Reson | [#435](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/435), [#439](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/439), [#446](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/446) | Directional clip binding and state labels | Not independent final sprites, gameplay movement, portrait kit, or approved likeness |
| Real moving test actors | [#458](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/458), [native test](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/actions/runs/40597622023) | Optional field locomotion adapter; no gameplay state writes | Isolated flat 2D collision circle; **does not prove 2.5D/planet terrain grounding** |
| Native per-frame boot alpha | [#469](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/469), [native test](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/actions/runs/40600515440) | Import/foot-baseline lint; overlay debug | 72 valid pixel rows do not identify planted toes |
| 72 explicit provisional stance labels | [#474](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/474), [native test](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/actions/runs/40607024751) | Versioned pose-contact annotations, slip tracer | 20.00–28.95 px *hypothetical* two-phase marker drift; no artist-identified stance |
| Lyra south source boot polygon anchors | [#487](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/487), head `aa68f341e62b7c5f8de666ecd6410f244ab4a0b3`, [native test](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/actions/runs/40609828168) | Template for per-foot source annotation, not automatic conversion | 12/12 source points verified; right/left candidate drift 24.33/24.74 px, **not corrected** |

The 12 px single-held-frame marker travel in #469 and 20–28.95 px provisional two-frame marker travel in #474 are **different metrics**, not conflicting reports. Neither is a creator-certified planted-foot error. Latest #487 is a measurement improvement over screen-half alpha, **not a fixed walk**. Source images, native 960×640 capture hashes and rollback receipts stay attached to their original draft PRs. Earlier successful CI must never be claimed for a changed integration head.

## 2. Proposed modular production contract (not implemented in the playable game)

A reusable Godot `CharacterVisualPresenter` should **consume** already-authorized game state, never set it:
- `CharacterVisualDefinition` (id; exact creator identity/spec reference; source asset hashes; orientation/clip map; art approval status). Current canonical character IDs are Ender, Ionia, Lyra, Aepex, Reson. Group reference order Ionia–Ender–Aepex–Lyra–Reson is **image identification**, not recruitment order.
- `LocomotionView` (velocity → facing/idle/walk; actual terrain-contact source from the game; animation phase; reduced-motion behavior; feet/occlusion anchors). Prototype `CharacterBody2D` physics tests are a **2D laboratory**; actual exploration integration needs the map's collision/projection, slopes, water/decks, and 2.5D visual depth, not reuse of a circle as 3D foot physics.
- `EquipmentVisualBinding` (read-only currently equipped weapon/armor/charm appearance from verified equipment authority; sockets, hold/carry and transition clips, correct handedness/occlusion). **Never** award items or alter inventory from an art callback; see separate equipment stacked draft track and its promotion contract.
- `ExpressionAndCinematicBinding` (field/talk/portrait/emote identifiers; same identity/materials under camera/time-of-day changes; no secret story beats imported into public manifests).
- `AffinityVisualHint` (optional presentation-only plot motif, *not automatically castable abilities*). Innate story energies: Ender **Spirit**, Ionia **Earth**, Lyra **Water** with distinct pink spirit-energy visual motif, Aepex **Air**, Reson **Fire**. Jobs/classes may have **zero learned combat magic** while plot resonance remains.

Prototype diagnostic overlays P/K/T are **developer-only**, OFF by default and unavailable in ordinary player UI and packaged release. Prefer a single identity/source registry over five hand-wired scene branches. Do **not** couple optional sprite presentation to Chapter I party recruitment or save serialization.

## 3. Bounded integration experiment P-01 (smallest real production-path test)

Implement in a **new opt-in Godot character-presentation fixture**, based on the actual native Chapter I branch chosen at integration time and explicitly diffed against #487. Do not assume #487 can be merged wholesale into a different Chapter I/ship/environment branch.

Fixture steps and expected observable outcomes:
1. Spawn an **unrecruited, noncanonical visual test actor** through `CharacterVisualPresenter` using the same data/animation path intended for future production fields; the actual game roster, scene progression and save bytes remain unchanged. Default OFF.
2. Move it across **deck + dock + ground** samples (and an independently isolated shallow-water edge if compatible), with genuine terrain contact/collision, facing changes, walk↔idle, stop/restart, occlusion and obstacle tests. Use the existing physics controller if compatible; explicitly test the 2D-to-2.5D projection rather than inferring it.
3. Feed a **read-only equipped-weapon change** from the approved equipment visual contract; verify that the correct held/holstered meshes or sprites change in both field and noncanonical practice battle, without mutating item possession, skill trees or elemental spell grants. If the equipment authority is not integrated, mark this subgate **BLOCKED**, do not fake a passing demo.
4. Trigger a **noncanonical dialogue/emote/portrait cut**, preserving age, hair, facial features, equipment and lighting identity; return to exploration and test state restoration. Preserve Ionia-first preflight and Lyra's later arrival after ocean splashdown; do not prematurely recruit any party member.
5. Capture **real native Godot frames** at logical 960×640 and presentation 1440×960, daytime/nighttime, clear/rain, normal/reduced motion and high/low graphics settings where the respective environment adapters exist. Record unavailable combinations as **NOT_RUN**. Add honest camera/occlusion, layering and palette readability review.
6. Enter/exit the prototype twice; assert no save diff, no party composition change, no story gate change, no leak of debug hotkeys into player input, reversible fallback to existing candidate sprites, and no invalid scenario carried into the game.

**P-01 PASS requires a genuinely executed opt-in integrated scene** on one exact Godot commit with source hashes, scene/physics checks, screenshots and a human-readable comparison. A PR description, mock manifest, unit test, or isolated sprite viewer is insufficient. P-01 does *not* constitute release/admission.

## 4. Quality gates and release discipline

| Gate | Required evidence | Current status |
| --- | --- | --- |
| P0 Provenance & creator identity | Original layered or editable art; source hashes, redistribution rights, named character locks, all derived assets traced | Partial source custody; creator approval outstanding |
| P1 Native import/behavior | Four-way clip maps, no flip shortcuts for asymmetric gear/tattoos, real movement, collisions, no regressions | **PASS only in isolated candidate branch**; P-01 cross-scene **NOT_RUN** |
| P2 Anatomical gait | Annotated anatomical foot identity and stance windows; true world-space toe/heel traces over full stride; stop/turn/idle; artist-reviewed foot slide | **FAIL FOR ADMISSION / NOT_CERTIFIED** (measured candidate drift) |
| P3 Gameplay integration | Noncanonical opt-in fixture exercising shared controller/visual registry, scene changes, party/save invariants, equipment read-only adapter | **NOT_RUN** |
| P4 Visual + accessibility | Creator-approved style/proportions/portraits, lighting/weather, readable 1× scaling, gamepad, reduced motion, occlusion | **PENDING** |
| P5 Target platform | Representative desktop GPU memory/frame time, native Windows export and installed-launch smoke, accessible persisted screenshot/video evidence | **NOT_RUN / security hold where applicable** |
| P6 Admission/release | Explicit creator review, provenance/rights approval, controlled merge and separate release decision | **HOLD** |

For P2 set a *proposed, not yet adopted threshold* such as ≤2 logical px of measured true world-stance toe drift over a verified stance interval at logical 1× scale **only after** artist-labeled contact points exist; require supporting visual judgement, not threshold-only acceptance. Add seam tests (frame 5→0), opposite-leg sequence, heel/toe carry, idle/walk transitions, diagonal movement, slopes, surface movement and carrying a full-length weapon. A lower threshold must not be met by artificially freezing the character root, falsifying physics displacement or smoothing only a debug marker.

For the **Ionia-first Chapter I test**, preserve the creator-described preflight/test flight, controlled ocean splashdown, and Lyra's later entry/Talen relationship. Independent narrative choices and irreversible later-game route details do not belong in this public QA fixture. The historical JS Preview 0.1 installer and its exact acceptance hashes must remain untouched; Godot targets require their **own** candidate binding.

## 5. Receipt template for each executed prototype test

```text
CHARACTER_VISUAL_PIPELINE_STAGE=P01|P02|P03|P04|P05|P06
CANDIDATE_GODOT_COMMIT=<full exact SHA>
PARENT_CHAPTER_BRANCH_AND_SHA=<verified native game state>
SOURCE_ART_HASH_MANIFEST=<exact file and frame hashes>
SCENE_AND_INPUT_ROUTE=<native scene path, controls, replay seed>
NATIVE_GODOT_VERSION=4.7.2
CHARACTER_ID=<id or noncanon fixture actor>
DIRECTIONAL_CLIPS=<4 source-bound paths, import receipts>
PHYSICS_TERRAIN_PROOF=<collider/raycast/actual movement evidence>
STANCE_CONTACT_SOURCE=<artist-approved annotation ID or NOT_APPROVED>
STANCE_WORLD_DRIFT=<unit, tolerance and exact capture window or NOT_RUN>
EQUIPMENT_VIEW_STATE=<adapter evidence or BLOCKED>
STORY_PARTY_SAVE_DIFF=<zero-impact receipts>
NATIVE_LOGICAL_CAPTURE=<960x640 hashes>
PRESENTATION_CAPTURE=<1440x960 hashes or NOT_RUN>
ACCESSIBILITY_PERFORMANCE=<measured receipts or NOT_RUN>
CREATOR_VISUAL_ACCEPTANCE=PENDING|PASS|FAIL
ENGINEERING_RESULT=PENDING|PASS|FAIL
MERGE=HOLD
RELEASE=HOLD
```

**Promotion rule:** no observed gate result inherits from an ancestor branch to a modified head without checking the exact integrated tree. A source-art hash is not a human art review. A rendered image is not a playable frame rate. A passing host functional test is not a Windows host security pass.

## 6. Required doc sync and owners

- **GitHub — this document:** durable, public-safe admission decisions, test scope, dependency graph and receipt template.
- **[Character and Art Authority](../CHARACTER_AND_ART_AUTHORITY.md):** add explicit pointer to the current unapproved character-motion stack and avoid blanket approval claims.
- **[Character Art Direction](../CHARACTER_ART_DIRECTION.md) and [Visual Bible](../VISUAL_BIBLE.md):** clarify field/portrait/battle/cinematic visual identity; existing creator locks override old general open-trait language. Update actual accepted animation standards only after artist review.
- **[Godot Migration Coordination](../GODOT_MIGRATION_COORDINATION.md) and [Agent Handoff Index](../AGENT_HANDOFF_INDEX.md):** list the character-motion stack as independent from Chapter I, equipment, world/flight/ship drafts; identify nearest safe P-01 dependency.
- **[Notion Source Index](../NOTION_SOURCE_INDEX.md):** add this public-safe bridge under character art / prototype admission.
- **Notion [Character Art Contract](https://app.notion.com/p/3e2f5bad238b8109b13ce1328d65910c), [Art Library](https://app.notion.com/p/3e3f5bad238b81999b97cd821db6603b), [Development Ledger](https://app.notion.com/p/406f5bad238b81649ecaea05f451c2d6):** log the measurement receipts, P-01→P-06 gates, source status and crosslinks. Do not overwrite canonical dossiers with speculative outfits or private source images.
- **[Development Guide](../DEVELOPMENT.md), [historical Preview 0.1 Acceptance](../PREVIEW_0_1_ACCEPTANCE.md):** historical build hashes remain immutable; add a separately bound future Godot P-01 acceptance record after a *real* integrated build exists.
