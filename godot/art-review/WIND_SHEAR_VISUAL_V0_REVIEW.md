# Harmonic Shear Elemental — native enemy visual study v0

**Status:** IMPLEMENTED as a provisional visual renderer; **not creator-approved enemy art**. Public-safe Chapter I combat, no new story canon or hidden content.

## Authority and source

- Canon/current metadata: `wind_shear` Chapter I Crossing hazard maps to existing `windShear` / **Harmonic Shear Elemental** only.
- Its `galeForce` retaliation deals 2 damage and applies the currently modeled knockback metadata; `uncoverTruth` exposes an EMP vulnerability. The new renderer does not modify any of these rules.
- Other Crossing hazards (Loose Cargo Sweep and Dock Authority Hold) remain noncombat and are **not** newly rendered as enemies.
- Implementation base: native Chapter I draft PR #347, exact code-source head `74fe1bce7a8a02eb3cbf30f725fa2af0925ba670`. New work lives on a separate draft branch.

## Visual thesis — PROPOSAL, not an art lock

A recognizable **broken harmonic pressure form**, not a generic elemental ball:

- A tall asymmetrical crystal/wind-fin body in subdued Scioto blue and silver/teal.
- Broken orbital arcs implying unstable acoustic pressure and shear.
- Five tapered counterflow streamers, a paired fractured core, and narrow horizontal hover shadow.
- **Uncover Truth:** restrained amber brackets expose the previously hidden split core.
- **Gale Force:** a brief warm pressure edge, never a whole-screen strobe.
- **Victory before confirmation:** solid core dissolves into dim separated fragments; gameplay still requires the existing confirmation action.

All geometry is original, code-authored `CanvasItem` content bounded to 182×184 logical pixels on the right side of a 960×640 battle review panel. The creature is deliberately *not* a humanoid, a canonical new species, or a final hand-authored pixel sprite.

## Rendering and interaction boundary

`godot/scripts/first_wake_wind_shear_visual.gd` is **visual only**. The scene mounts it at (684, 281), but exposes it exclusively for an active `wind_shear` fight whose formula target ID exactly equals `windShear`. It never appears in the noncanonical Formula Review encounter.

- No new random rolls, health changes, hitboxes, node-body collisions, chapter/save fields or combat action authority.
- The scene controls analyzed, cleared and enemy-turn count readouts. A new encounter resets art state; cancel/confirm and restore hide the visual.
- Ambient redraw is capped at approximately 20 Hz while displayed. Its idle motion is small and may be frozen using `ProjectSettings.set_setting("accessibility/reduced_motion", true)` (prior to preview scene creation), or by calling `set_reduced_motion(true)` on the visual directly.
- Chapter I capture pipeline already includes the authored Wind Shear fight. The capture script now also fails if the after-analysis visual identity is absent.

## Verification and review gates

- Contract to execute: `godot --headless --path godot --script res://tests/first_wake_wind_shear_visual_test.gd`.
- Required regressions: existing Wind Shear adapter, retaliation, crossing-scene, save/restore, formula review and Chapter I state tests.
- Real image gate: execute `godot/tests/capture_first_wake_chapter1_review.gd` with Godot 4.7.2 and OpenGL Compatibility, then inspect `chapter1-wind-shear-combat-native-960x640.png` against the prior source at the *same battle state*. This document **does not** claim such rendering was done.
- Creator/player review must check silhouette readability at native scale, legible enemy HP/status/commands, no aliasing or clipping, perceived elemental identity, analyzed/retaliation clarity, idle visual noise, reduced-motion behavior, and frame pacing on target hardware.

## Next art iteration (not implemented)

Produce a source-controlled, pixel-authored animation atlas with explicit provenance and directional light consistency; add anticipation and impact stages to the existing damage-state interface; avoid assuming that speculative new creatures or bosses are now canon. Keep this art study as a reversible fallback until an authentic reviewed asset supersedes it.
