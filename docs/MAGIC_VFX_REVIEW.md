# Magic cinematic VFX — native look-development study v0.1

**Status:** IMPLEMENTED CANDIDATE / ART NOT APPROVED / NATIVE RENDER NOT YET CERTIFIED.
**Source:** isolated Godot 4.7.2 + GDScript branch based on `feat/godot-first-wake-party-combat-authority-20261022` at `74fe1bce7a8a02eb3cbf30f725fa2af0925ba670`.
**Scope:** five original SVG sigils, deterministic `Node2D` draw pass, isolated opt-in visual review scene and scene-level test. No active encounter uses this.

## Creator-approved foundational identity (newer authority)

| Protagonist | Fundamental energy | Effect motif |
| --- | --- | --- |
| Ender | Spirit | Ivory/violet constellation alignment; soul-bound light, not automatic Holy |
| Lyra | Water | Flowing tidal ribbon; the creator's pink spirit-light remains visibly present |
| Ionia | Earth | Grounded faceted minerals, shards and settling dust |
| Reson | Fire | Rising thermal tongues, cinders and warm impact |
| Aepex | Air | Flowing pressure wakes and displaced aerodynamic bands |

These energies are **narrative/plot resonance regardless of job selection or whether a character ever learns magic**. Do not award any spell, mastery, equipment or combat permission by displaying a visual. The earlier `docs/MAGIC_SYSTEM.md` affinity list is stale relative to the newer creator decision; leave its runtime registry untouched until an authorized reconciliation.

## Use

Open `res://scenes/magic_vfx_showcase.tscn` in `godot/project.godot` using Godot **4.7.2** and run the current scene (F6). Keys **1–5** select protagonist, **M** opts into/out of animation, **SPACE** restarts the selected vignette; **ESC** exits. Reduced motion defaults ON, showing a stable full composition. Effects deliberately omit screen flashes/camera shake; colors aren't the only identifying cue.

A standalone consumer can instantiate `res://scripts/magic_vfx.gd`, add it to the scene tree and call `play_affinity(character_id, reduced_motion)` using an allowed character id. Invalid IDs fail closed without changing the currently selected visual. The node has no gameplay side effects.

All authored effects follow **anticipation → formation → release → impact → aftermath** on a 2.4-second non-gameplay timeline. Motion-sensitive mode is a stable illustrated frame instead of flashing/rotating particles. This is a visual vocabulary, not a master spell atlas.

## Art and validation gates

1. Native import: `godot --headless --path godot --editor --quit`.
2. Native contract: `godot --headless --path godot --script res://tests/magic_vfx_contract_test.gd`.
3. Visual review: capture genuine Godot framebuffer images for each of the five looks in both motion modes at 960×640 and inspect bleed, contrast, readability, composition and accessibility. Benchmark on GL Compatibility and representative hardware.
4. Only after native captures + creator sign-off, consider integrating into battle, upgrading to particles/3D volumes, or admitting spell-specific effects.

**Unverified in this branch:** actual native Godot import and renderer, screenshot fidelity, animation playback, 2.5D camera occlusion, combat transitions and hardware performance. Passing code checks cannot substitute for these. Art direction is a candidate, not canon.

**Provenance:** SVG glyphs and procedural drawing authored for this project as original placeholders; not derived from third-party/copyrighted effect packs. They remain editable vector sources, without dependencies or runtime downloads.
