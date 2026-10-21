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
