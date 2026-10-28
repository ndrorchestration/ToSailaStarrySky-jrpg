# First Wake — true 3D coastal production proof (2026-10-28)

**Classification:** separate interactive Godot **3D visual-technology slice**, verified on Windows and not a Chapter One gameplay conversion, creator-art approval, merge or public build. The original native First Wake F5 entry remains `res://scenes/first_wake_game.tscn`.

## Why this exists

The project already has tested Ionia-first story chronology, real native water-contact and save/checkpoint behavior. Further refinement of flat 2D placeholders is lower-value than moving the production art workflow to textured/rigged 3D assets. We therefore **preserve the functioning JRPG systems** and validate a new spatial rendering/import pipeline separately.

**Review scene:** `res://scenes/first_wake_3d_visual_slice.tscn`  
**Godot version tested:** 4.7.2.stable.official.ed1daf0bf  
**Windows device:** Intel Iris Xe Graphics, 15.7 GiB reported RAM  
**Tooling note:** Blender and production GLB character sources were not present in the inspected Windows development workspace. Their absence is explicitly recorded, not silently replaced with a fabricated rig or actor.

The scene uses **186 live constructed true 3D mesh instances** at the measured preview head, including the individual pier planks and posts, spatial wave-displaced ocean, continuous modeled mountain silhouettes, support hardware, lanterns, a tapered ship hull, open frontal deck and a **provisional geodesic dome**. It has a physical `Camera3D`, actual `DirectionalLight3D` shadows, local `OmniLight3D` lanterns, weather/fog and time-of-day transition. A source-safe GLB slot exists for each of Ender and Ionia. **Zero real rigged protagonist GLBs were loaded.**

### Honest art boundary

These are geometry/material BLOCKOUTS, not visually final assets. The mountain materials remain plain, coast props lack high-frequency PBR textures, the ship is an engineering silhouette rather than an approved cinematic Aureate Wake model, and the correctly designed cast is **not yet 3D-rigged**. Technical rendering success does not mean the scene has reached the creator's visual bible.

## How to inspect

The scene is separately launchable and **does not change normal F5**. Windows shortcut:

`Desktop / Aetherwake / PLAY FIRST WAKE - 3D Coastal Preview`

Godot CLI, with a local `godot/project.godot` directory available:

```powershell
Godot_v4.7.2-stable_win64.exe --rendering-method forward_plus --rendering-driver vulkan --path "<path to godot folder>" res://scenes/first_wake_3d_visual_slice.tscn
```

- Arrow left/right: orbit camera around the coastal scene
- Arrow up/down: zoom
- **T**: compare sunset against blue-hour lighting
- **R**: reset camera

**This preview currently has a camera review interaction, not a migrated 3D player, story, combat or physics controller.** Never mistake a standalone 3D review scene for complete playable Chapter One.

## Actual Windows evidence

Native exact render was inspected at source SHA `3441b282e5f0746b59048a1744f88010216b76f1`. Later commit `9e9e5480903fc74ea1473d5b262b6127072924b8` added performance measurement without modifying that rendered scene.

| Test | Verified |
|---|---|
| Godot spatial scene and source GLB slot admission tests | 22 assertions PASS |
| True 3D OpenGL Compatibility 960×640 sunset frame | SHA-256 `6a28d2cb0981413b0006b85d09958c7281c0fe9c23cd0b2efcecca25dc4cbb2f` |
| True 3D OpenGL Compatibility 960×640 blue-hour frame | SHA-256 `fcccee56505b6245866f68ca063745da8d4eb3dc963a64ddd0b32fcb7acd9be2` |
| True 3D Vulkan **Forward+** 960×640 sunset frame | SHA-256 `cc20252f48792b3244cd9bd7b519c33183469f664434dfdb64e6a387addf76a1` |
| True 3D Vulkan **Forward+** 960×640 blue-hour frame | SHA-256 `f426121084be0648a6943ecc3b3eec5ad8b5e2dd2623653cf0e98b763b4771f7` |
| Native full unchanged 2D First Wake flight/water/save regression | 48 assertions PASS |
| Native direct launch of standalone 3D scene | Exit 0 |
| Original 2D project main scene still F5 entry | VERIFIED |

**Performance sample** (90 sequential rendered frames after 24 warm-up frames, 960×640, in this small study):

- OpenGL Compatibility: observed 90 frames / 1500.14 ms, **60.0 FPS**, mean 16.67 ms/frame.
- Vulkan Forward+: observed 90 frames / 1499.67 ms, **60.0 FPS**, mean 16.66 ms/frame.

These are observed preview cadences, **potentially VSync/frame-limited**, not GPU utilization measurements, 1% lows, final scene budgets or guarantees of full JRPG performance. The scene is deliberately not detailed enough yet to test production quality/performance trade-offs. Both renderers genuinely worked on Intel Iris Xe.

All four 960×640 PNGs, full hash receipts and a local HTML gallery are held privately on the creator's Windows device under:

`Desktop/Aetherwake/Verification Sandbox/FirstWake-3D-Renderer-Review-20261028`

and opened with:

`Desktop/Aetherwake/SEE FIRST WAKE - Real 3D Renderer Comparison`

No user character JPEG/PNG or native screenshot has been committed to public GitHub.

## Rigged character asset contract — Blender/GLB pipeline

`res://scripts/first_wake_3d_character_slot.gd` is a private-art import gate:

- Proposed source location: `res://art-review/private-3d/characters/ender.glb` and `ionia.glb`
- Import as `PackedScene` / `Node3D`
- Require an actual `Skeleton3D` with at least eight bones
- Require an `AnimationPlayer` with at least one authored animation when animation is required
- Fail closed when missing or invalid; never replace with generic character art, a static cutout presented as a rig or a synthetic test humanoid
- All visual/art and release approvals remain **false** regardless of importer success

**Source design targets:** Ionia = blonde, green-eyed naturalist/explorer with botanical field attire; Ender = green-haired inventor/mechanic with signature goggles and correct outfit. Use the approved Five Lights visual bible for Aepex, Lyra and Reson next, at their actual story gates. Do not revive rejected anime field sprites.

A production Blender scene should deliver separately approved, editable model, materials, animation clips and final source provenance; then export GLB into a **private** workspace. The art model should include real walk idle/turn, properly planted boots, hair/tool/accessory continuity and optimized LOD. Do not distribute proprietary image references or GLB source publicly before creator authorization.

## Independent gates before production promotion

1. **Visual** — creator signs off the correct five models from front, three-quarter, back and at gameplay scale, plus rigged animation playback.
2. **Environment** — actual textured/cliff/ship materials, coherent lighting, coastal shadows, ocean surf, water interaction and geodesic bridge pass native frame review.
3. **Engineering** — retain old working systems; 3D locomotion, character events, combat anchors and original story chronology become functional only in a separate independently tested integration.
4. **Performance** — measure representative 3D Chapter One load, GPU/CPU frame timings, memory and minimum hardware at both renderers; provide graphics quality fallback.
5. **QA/accessibility** — input remapping, readable HUD in camera orbit, camera collision, frame-rate independence, save schema and story-failure boundaries independently reviewed.
6. **Release** — exact Windows Defender-on security acceptance and installer verification remain separate blocked gates. No merge, production release or public art publication from this prototype.

**Recommendation:** Stay in Godot + GDScript for gameplay, adopt Blender as the production source for reusable GLB characters/sets, evaluate Forward+ on a genuine high-fidelity asset slice, and keep current native First Wake working until a replacement proves visual and gameplay parity.
