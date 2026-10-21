# Aetherwake — Godot 4.7.2 / GDScript migration feasibility pilot

**Status:** Isolated native-engine proof, **not** a complete migration, creator-accepted art, scene/canon rewrite, approved release, or evidence that production is now Godot.

## Objective

Move the *next technical vertical slice* off the legacy `p5.js / NW.js / JavaScript` implementation and evaluate a **purpose-built Godot 4 scene graph** with GDScript. Existing JavaScript sources remain a reference for story, save semantics and gameplay rules; no backwards-compatibility or save-data migration has been attempted.

This small opt-in Godot project contains a dock visual-grounding test, playable movement for Ender using `CharacterBody2D` and y-sorted actors, Ionia interaction at proximity, and a **distinct scene** for a trivial turn-based test arena. The numerical mock combat is **NOT** the actual Aetherwake encounter formula and must not be mistaken for an implemented migration. The dock terrain is **pilot geometry only** and does not authorize world route/canon changes.

## Run

Open `godot/project.godot` in **Godot 4.7.2 Standard (GDScript)** and press F6 or Play. Arrow keys move Ender; E interacts near Ionia; B opens the separate battle test; in that scene 1 strikes, 2 guards, R returns. No NW.js, npm or browser runtime is used.

```bash
Godot_v4.7.2-stable_linux.x86_64 --headless --path godot --editor --quit
Godot_v4.7.2-stable_linux.x86_64 --headless --path godot --script res://tests/smoke_test.gd
```

## Native Ionia source-art review (separate stacked candidate)

The **unapproved** layered Ionia SVG from art-review branch `art/ionia-original-v01-20261021` (original Git blob `0d82927b6c4f863fddd53526ee3c6ff8ce1cb093`) is imported at `res://art-review/ionia-original-v01-green-eyes.svg`, with its two iris fills and outlines adjusted from teal/blue to **green** for the latest character alignment. This derivation is a source review and **not** a canonical/creator art approval or a finished sprite pack. Original hand-authored shapes and 512×768 resolution are retained; there is no directional animation.

Run the Godot pilot, then press **V** to toggle the unapproved single-frame Ionia native `Sprite2D` on the dock; press **V** again to restore the baseline placeholder. The review image is a static `Texture2D` at approximately 67×100 logical pixels and is not an authored 64×96 directional field animation; the shared foot shadow remains visible. The pilot's current temporary dock shape is not canon geography. **B** still enters the separate, nonproduction turn-based training arena.

`godot/tests/smoke_test.gd` now asserts that Godot itself imports the SVG as a texture and toggles preview on/off from a hidden-by-default state; headless tests do **not** substitute for rendered screenshots, human visual inspection, complete gameplay or acceptance of art. The two existing critical boundaries remain: no legacy `p5.js`/NW.js replacement in production, and no Defender #293 release change.

## Explicitly not delivered

- **Final art:** Actor silhouettes are drawn from primitive shapes, conspicuously not approved character sprites. The separate original Ionia SVG candidate on `art/ionia-original-v01-20261021` is **not automatically promoted**; its eye-color rendering and visual compliance must be reviewed against approved canon before use.
- **Gameplay:** No faithful migrated quest route, no inventory, no independent movement topology, no real stat/ability combat, no real assets/cutscenes/UI transitions, no multi-direction animation source, no save migration.
- **Release:** No Windows installer or export, signed admission, gameplay acceptance, third-party security review or changes to the Defender #293 hold.

## Migration gate

Compare this pilot against the existing `First Wake` contract. Establish: full play route and controls; matching authored map geometry/collision; Ender approved likeness; Ionia design/eye-color and original layered art; actual encounter mechanics in separate turn-based arenas; save/load parity and recovery; native-scale screenshots and tests; then a creator-approved engine-choice/production promotion. Keep the first Godot integration draft and the legacy production branch distinct until these gates pass.


## Ender native movement review — 2026-10-21

Press **R** to toggle the existing six-frame Ender side-view walk strip in the native pilot. This is an opt-in animation candidate, hidden by default. Original pixels are reused without regeneration from `art-staging/field/ender/candidate/field-walk.png` at PR #295 source `133bb175d95b8b28772f8c802ec68b5ee8836842`. Likeness approval is distinct from animation/field-pack approval.

Animation advances per 14.8 pixels of actual travel (10 frames/second at the pilot's 148 pixels/second speed), resets to frame 0 when stopped and does not step against the boundary. Left movement mirrors the available side-view strip. Vertical motion retains that side view: front/back and diagonal authored poses remain missing. Mirroring is provisional and is not acceptance of staff-side continuity. The fallback silhouette uses a continuous distance-driven leg phase instead of the former binary leg jump. No staff pixels, pose anatomy, production asset manifest, or canon are changed.

Verification commands after editor import:

```sh
godot --headless --path godot --script res://tests/smoke_test.gd
godot --headless --path godot --script res://tests/ender_walk_test.gd
godot --path godot --rendering-driver opengl3 --resolution 960x640 --script res://tests/capture_ender_walk_review.gd
```

The last command requires a real display (Xvfb is suitable) and writes two stills plus 24 input-driven movement frames to `godot/review-evidence/`. Those files are native captures, not generated illustrations. Private delivery must be verified separately from rendering; Actions artifact quota is not fixed by this change.

### Authority and migration follow-up

The pilot inherited old `docs/CHARACTER_ART_DIRECTION.md` wording that leaves likeness choices open. Do not use it to override the later [approved alignment](https://github.com/ndrorchestration/aetherwake-jrpg/blob/133bb175d95b8b28772f8c802ec68b5ee8836842/docs/PROTAGONIST_VISUAL_ALIGNMENT_V1.md) or approved Ender appearance PR #261. Ionia's navy-coat SVG remains unapproved and differs from the locked cream blouse/brown utility-layer direction.

Next art work: recover and bind approved source art; author front/back/diagonal walk poses with stable staff carry and foot contact; evaluate Ender and Ionia together in the same native scene. The current dock and mock arena are feasibility fixtures.

Production parity remains NOT RUN: First Wake interaction and join order; real combat statistics/abilities/turn outcomes; objective/event progression; save/load/backup/corruption recovery and version migration. Capture identical inputs and expected state changes from the JavaScript reference before porting each subsystem. Do not reuse mock arena values as production combat rules. Production migration, visual acceptance and release remain pending; Defender #293 hold is unchanged.

## Native Ionia alignment comparison — isolated draft candidate (2026-10-21)

This follow-on branch from PR #308 adds **a second, unapproved, editable layered Ionia SVG** at `res://art-review/ionia-cream-leather-review.svg`. It derives explicitly from the earlier green-eyed Ionia artwork (`ionia-original-v01-green-eyes.svg`), preserving original source layers, hair and facial details while trialing the **later approved protagonist likeness palette**: cream/light blouse, brown leather harness/utility layers, restrained brass hardware, shoulder-length curly blonde hair and green eyes. The earlier navy source is retained unmodified for side-by-side provenance and comparison. The source contains original hand-authored utility-belt/harness details; it is **not a directional 64×96 walk strip** and is **not an approved field pack**.

In the **same genuine Godot dock scene**, press **R** to show Ender's six-frame side-view walk, **V** for the preserved Ionia original SVG, and **C** for the revised cream/leather source. Ionia's V and C sources are mutually exclusive and hidden by default. This is a reversible visual study: none of the source/preview operations changes canonical costume decisions, authored Chapter 1 map geometry, the production game runtime or Defender #293 release hold.

`godot/tests/ionia_alignment_test.gd` checks actual engine SVG imports, distinct resource paths, default invisibility, exclusive switches and visibility alongside Ender. The renderer script `capture_native_ionia_review.gd` now captures both genuine 960×640 two-character states and asserts that **Ionia pixels differ while Ender pixels do not**. Workflow artifact-quota restrictions still apply; native images may exist only temporarily on the hosted runner unless independently delivered and inspected.

**Remaining P0 (issue #297):** author proper approved-likeness front/back/diagonal Ender walk frames with physical staff continuity, plus a *genuine Ionia walking animation* with sound contact phases. Do not treat this static source comparison as completion of both-moving-character proof, 2.5D world polish, creator acceptance or native migration. Compare the result against `docs/PROTAGONIST_VISUAL_ALIGNMENT_V1.md` from PR #295's exact-head history, not superseded open-ended character-art wording. Creator visual approval and game parity are still pending.

## Native movement art integration candidate — stacked on PR #309 (2026-10-21)

**Authoritative context:** P0 issue #297 (native visible improvement), approved likeness mapping in the PR #295 history, and existing side strip in draft PR #308. This branch adds **authored review-only SVG strips**, not production field art or replacement canon.

- **Ender:** opt-in `R` now selects the existing 384×96 / six-frame east/west side strip, plus two original 384×96 / six-frame **front (south)** and **rear (north)** vector candidate strips based on approved auburn hair, bright green eyes/goggle lenses, olive/tan costume and staff with brass ferrules. Six contact-phase poses are separate source geometry, not simple recolors of one frame. East/west still mirror the old side strip, so staff continuity on left turns is unresolved. Diagonal movement uses its dominant axis; authored diagonals are still absent. All view switching is driven by actual motion; stopped actors return to frame 0 without sliding feet.
- **Ionia:** `T` enables a 3072×768 / six-frame **front-facing** Atlas of separately redrawn opposite-foot contact/lift geometry derived from the original layered cream-and-leather source. The **only** supported direction in this candidate is a short downward forward movement from the pilot position to a bounded stop. It does not pretend a front view is a completed rear or side animation. `V` and `C` still select the unanimated original and aligned Ionia references respectively; all three review modes are mutually exclusive, opt-in, and hidden by default. Upper-body layers stay fixed in these Ionia candidate poses and require proper authored follow-through and gait critique.
- **Authentic native evidence:** `godot/tests/directional_walk_review_test.gd` exercises sprite import, source identity, actual six-phase movement for Ender's up/down and Ionia's bounded forward walk, idle resets and hidden-by-default controls. `godot/tests/capture_directional_walk_review.gd` generates four **real Godot 960×640** images of north/south Ender and Ionia moving/stopped, checking region differences; captured PNGs remain ephemeral unless safely delivered outside the blocked GitHub Actions artifact quota.
- **Do not promote:** art is candidate-quality vector gameplay study, not final pixel-art field pack. No artist/creator visual rating, staff back/side attachment acceptance, complete directional Ionia art, environmental quality acceptance, Chapter 1 quest/combat/save parity, signed integration, engine production promotion, protected main merge, Windows installer or release.

`VISUAL_ACCEPTANCE=PENDING`; `FIELD_PACK_READINESS=NOT_READY`; `PRODUCTION_ENGINE_MIGRATION=NOT_ADMITTED`; `SECURITY_HOLD_293=OPEN`; `RELEASE=NOT_AUTHORIZED`.

## Authentic Godot physical dock-depth review — 2026-10-21 (stacked on #310)

Press **G** to toggle a **GDScript-only 2.5D environment candidate** in the actual 960×640 First Wake native pilot. It preserves the earlier geometric fixture and character positions as the default. The optional stage is rendered by two separate `CanvasItem` layers around the existing Y-sorted actors: distant sky/water/shoreline and a timber dock (behind), plus narrow near-side post/rope occlusion and a preserved dialogue panel (in front). This adds visually supported decking, underdeck braces, perspective seams, warm/cool lighting cues and ambient ground contacts. These elements are **decorative development geometry, not accepted canon**: no added locations, boarding routes, walkable areas, collision shapes, quests, ship identities or story progress.

The Ionia review SVG variants are shifted to a shared near-zero-foot baseline at `(0,-46)` while preserving image size and art provenance; both actor classes now draw two low ellipsoidal contact-shadow layers, not circular torso-sized shadows. Ender continues to use the real six-frame directional study from #310; `T` still triggers Ionia's bounded forward walk. All actor and terrain review toggles are disabled by default and can be reversed.

**Technical evidence:** `godot/tests/dock_depth_review_test.gd` proves baseline hidden state, toggle restore, unchanged walk bounds and character positions, retained two-actor movement, and correct background/foreground layer order. `godot/tests/capture_dock_depth_review.gd` generates three authentic native PNGs: same-position before/after at 960×640 plus both actors moving. It rejects identical horizon/deck regions or missing native movement. The hosted capture workflow emits SHA-256 hashes but does **not upload** PNGs because the already-documented GitHub Actions quota is blocked. Rendered evidence must still be independently delivered and visually inspected before acceptance.

This selectively implements the **physical-grounding principles** documented in earlier art PR #298, without merging its legacy JavaScript renderer, reconstructing a bridge/ship approach or promoting a new world geography. The result may still look flat or stylistically inconsistent at native size: no human reviewer has accepted environmental quality, Ionia original-quality anatomy, gait animation, or staff-carry parity. The accepted likeness reference remains `PROTAGONIST_VISUAL_ALIGNMENT_V1.md` in the #295 lineage; the old #297 navy-coat description does not supersede it.

**Hard gates:** `VISUAL_ACCEPTANCE=PENDING`; `FIELD_PACK_READINESS=NOT_READY`; `PRODUCTION_ENGINE_MIGRATION=NOT_ADMITTED`; `RELEASE=NOT_AUTHORIZED`; Defender #293 security/release hold unchanged. Real Chapter 1 objective, combat, save and route parity are unproven.

## Ionia four-direction native character-art study — 2026-10-21

This **stacked draft** adds original editable Ionia side-facing left/right and rear-view six-pose SVG review atlases to the existing front source. These are hand-authored proposed models reflecting the provisional cream blouse, brown harness/belt, shoulder-length blonde curls, gold/brass captain fittings and green eyes. The three new 3072×768 atlases have six separately posed leg-contact phases with counter-swinging arms; they are *not* traced render exports of an accepted source, an artist-approved full field pack, or proof that all four views match the same physical 3D anatomy at native scale.

**Y** triggers a reversible native-Godot preview in which Ionia travels **south → west → north → east** around a rectangular diagnostic circuit completely inside the existing 145–815 × 410–522 pilot movement bounds. Each view uses its own imported atlas and frame index advances only with measured displacement. Completion stops at the original circuit start and returns to frame zero; there is no repeated automatic loop. Original `T` forward-only preview, `C` cream/leather single-frame art, and `V` prior original are preserved and remain mutually exclusive with the new mode. Art toggles are hidden by default and do not touch quests, canonical geography or authored player routes.

Native test `ionia_four_direction_test.gd` checks four unique real imported textures, six distinct index phases per leg, complete bounded traversal, idle and opt-out, and restoration of T/C modes. Native renderer script `capture_ionia_four_way_review.gd` captures authentic 960×640 scenes of each direction while Ionia physically moves, with the enhanced scene `G` also enabled. These checks remain engineering observations only. As of prior runs, GitHub Actions image uploads are blocked by its artifact-storage quota; PNGs cannot be assumed to be retrievable from hosted checks.

Remaining: evaluate **native-size visual quality** by independent screenshot review, unify side/front/rear silhouettes and anatomical proportions, improve Ender's real side staff carry and diagonal source poses, and promote none of the material to final art without creator approval. Chapter 1 quest/combat/save parity, native production engine choice, and security/release approval are still separate holds.

`VISUAL_ACCEPTANCE=PENDING` · `FIELD_PACK_READINESS=NOT_READY` · `PRODUCTION_ENGINE_MIGRATION=NOT_ADMITTED` · `RELEASE=NOT_AUTHORIZED` · Defender #293 remains in force.

## Ender westward carry / unmirrored character study — 2026-10-21

The opt-in Ender **R** preview now uses a **separate, original editable 384×96 SVG atlas** for westward motion. Previously, left movement displayed `flip_h=true` on the original six-frame eastward PNG, which also mirrored his equipment and defeated artist review of back-carry continuity. The original approved-likeness source pixels remain **unmodified for east**; Ender still uses the experimental north/south authored candidates from #310. The new west source uses six distinct step poses, a copper/auburn-hair side profile, green-lensed brass goggles, olive/tan field-scholar clothing, and a full-length brass-ferruled staff aligned to **body x=31 / y=8–88** in each pose. This geometric invariance is a *source study*, not an assertion that the original east PNG shares the same attachment axis. Full left/right art style and posture equivalence still requires artist review.

Native `ender_walk_test.gd` now rejects mirrored west, ensures west is a separate imported texture, and retains idle and wall-stop checks. `directional_walk_review_test.gd` verifies six **rasterized, pairwise-unique** west poses from Godot's actual SVG import and checks the six staff source anchor paths, the actual leftward traversal, frame cycle and stop. `capture_ender_staff_review.gd` generates **authentic Godot 960×640 east/west** captures on the same enhanced deck at comparable character coordinates, rejecting missing directional visibility or identical in-game character pixels. This capture is not a promotional render; image upload is separately blocked by the existing GitHub Actions artifact quota. CI's native renderer and Godot import can establish technical correctness but cannot establish human visual acceptance.

**Still P0:** side-to-side character identity/style consistency and physical staff carry attachment to the approved source; improved contact and arm/torso weight; authored diagonal views; comparable Ionia body proportions and style; actual viewable native screenshots and human artistic assessment. Story/map authority, gameplay/quest/combat/save parity, migration admission and Defender #293 release hold remain unchanged. `VISUAL_ACCEPTANCE=PENDING`, `FIELD_PACK_READINESS=NOT_READY`, `PRODUCTION_ENGINE_MIGRATION=NOT_ADMITTED`, `RELEASE=NOT_AUTHORIZED`.

### Private native visual inspection fallback (no Actions artifact upload)

Because GitHub Actions artifact storage has repeatedly yielded **zero downloadable artifacts**, the renderer job now runs `godot/tests/emit_private_native_preview.gd` after its full-resolution capture checks. That second renderer pass emits exactly two **480×320 JPEG previews**, generated from genuine 960×640 in-game Godot framebuffers, in marked Base64 chunks in the **private workflow job log**: `east-original` and `west-new-unmirrored`. It uses neither a public storage endpoint nor write-enabled Actions permissions. Previews are explicitly smaller and lossy; they must not be represented as 960×640 source evidence or final art acceptance. The full-size 960×640 PNG tests and SHA receipts remain separate and continue running first.

An actual visual inspection of the first recovered preview showed the independently drawn west source visually oversized compared with the preserved original east PNG; the candidate now uses a reversible **0.83× horizontal / 0.82× vertical** sprite transform with feet re-anchored to ground. This is a *visual QA correction*, not proof of original-character likeness, sprite-pack admission, staff physical correctness, or user acceptance. Native inspection should continue on later exact-head captures, with any comparison packet carrying its exact source head and downgraded-resolution label.

Review receipt sequence: open the private workflow for the exact commit, inspect the job logs for `AW_PRIVATE_REVIEW_JPEG_BEGIN` / `AW_PRIVATE_REVIEW_JPEG_DATA` / `AW_PRIVATE_REVIEW_JPEG_END`, decode each concatenated Base64 payload as JPEG, and inspect alongside the original source/commit SHA. Never place those private screenshots on a public service without authorization. This workaround only resolves *recoverability from private logs*, not Actions artifact quotas or the requirement for full-resolution creator review.

## Conversation movement repair — current directional stack, 2026-10-21

Opening the existing Ionia conversation now pauses both actors, including an active Ionia diagnostic route. E or Escape closes it and restores movement; the route resumes from its preserved position and segment. T/Y route controls are ignored while dialogue is open so they cannot teleport the speaker. Frame 0 is held during the pause; this is not newly authored idle/listening art. The dialogue label wraps within its panel.

`tests/dialogue_pause_test.gd` reproduced movement during dialogue on the parent before the fix and covers proximity, both actors held, route-state preservation, guarded diagnostic controls and E/Escape resume. Existing four-direction assets, staff changes, dock rendering and opt-in switches remain inherited from PR #321 at `3288cf1e501dc53a32c2b7b53c07519f694718b3`.

The earlier local idle/talk experiment based on #308 was not submitted: it would replace newer directional sprite handling and conflict with the existing T binding. This repair is intentionally based on the current stack. No art acceptance, real quest/combat/save parity, production migration, merge or release is established. Defender #293 hold remains.
