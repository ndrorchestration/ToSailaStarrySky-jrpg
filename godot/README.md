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
