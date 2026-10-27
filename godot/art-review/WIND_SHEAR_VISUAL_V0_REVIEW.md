# Harmonic Shear Elemental — native enemy visual study v0

**Status:** IMPLEMENTED as a provisional original pixel atlas with fallback visual renderer; **not creator-approved enemy art**. Public-safe Chapter I combat, no new story canon or hidden content.

## Authority and source

- Canon/current metadata: `wind_shear` Chapter I Crossing hazard maps to existing `windShear` / **Harmonic Shear Elemental** only.
- Its `galeForce` retaliation deals 2 damage and applies the currently modeled knockback metadata; `uncoverTruth` exposes an EMP vulnerability. The new renderer does not modify any of these rules.
- Other Crossing hazards (Loose Cargo Sweep and Dock Authority Hold) remain noncombat and are **not** newly rendered as enemies.
- Implementation base: native Chapter I draft PR #347, exact code-source head `74fe1bce7a8a02eb3cbf30f725fa2af0925ba670`. New work lives on a separate draft branch.

## Revised Chapter I chronology — integration hold (2026-10-27)

**Creator-approved story direction:** [#425](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/425) and the native hiring slice [#430](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/430) place Ionia as Ender's **first** companion, with Lyra joining later after splashdown. This is later than the older native Crossing/party assumptions in base [#347](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/347).

**IMPLEMENTED:** the Wind Shear *visual component* remains reusable and presentation-only. **OPEN:** whether this legacy Crossing encounter and its placement belong in the revised Chapter I sequence. Do **not** interpret the passing PR #410 combat smoke as approval of the older Ender+Lyra-first story order. Do not merge old chapter sequencing to make this art appear. Integrate through the revised narrative line only after an explicit encounter-placement and party-authority reconciliation.

## Visual thesis — PROPOSAL, not an art lock

A recognizable **broken harmonic pressure form**, not a generic elemental ball:

- A tall asymmetrical crystal/wind-fin body in subdued Scioto blue and silver/teal.
- Broken orbital arcs implying unstable acoustic pressure and shear.
- Five tapered counterflow streamers, a paired fractured core, and narrow horizontal hover shadow.
- **Uncover Truth:** restrained amber brackets expose the previously hidden split core.
- **Gale Force:** a brief warm pressure edge, never a whole-screen strobe.
- **Victory before confirmation:** solid core dissolves into dim separated fragments; gameplay still requires the existing confirmation action.

The original pixel atlas and fallback geometry remain bounded to a 182×184 logical-pixel review stage on the right of the 960×640 combat panel. The creature is deliberately *not* a humanoid, a canonical new species, or a final hand-authored pixel sprite.

## Original pixel atlas — candidate art v1

- **Committed source:** `godot/art-review/wind_shear_elemental_v1_atlas.png`
- **Editable generation source:** `godot/art-review/generate_wind_shear_atlas.py` (development-only Pillow dependency, not loaded by game).
- **PNG provenance (authoring output):** 320×92 RGBA, four 80×92 adjacent frames, SHA-256 `54f1181e0d9d294c964fc34d5edc3a36ea96d422d6b3770f4cfca200558ba4bf`; asset generated as original art for this study, not sourced from another game's art.
- **Frame order:** idle; analyzed; Gale Force; dispersed. Texture is displayed with nearest-neighbor scaling at 1.8× (144×165.6 logical pixels), preserving authored pixel blocks.
- The scene first checks native `Texture2D` import, frame dimensions and pixel sampling; if import is not available it returns to existing code-drawn wind geometry. This is still a **review candidate**, not a signed-off production sprite.
- The five native capture states (idle, analyzed, **observed-hit**, Gale Force, dispersed) are implemented in `godot/tests/capture_wind_shear_visual_review.gd` and gated by the existing Godot visual review workflow. The observed-hit screenshot comes from a real authorized Staff Strike; the stand-alone Gale/dispersed art-state captures remain presentation-only and do not grant extra combat turns or progression. Those frames are *Godot runtime output*, distinct from the artist-local PNG contact sheet.

## Rendering and interaction boundary

`godot/scripts/first_wake_wind_shear_visual.gd` is **visual only**. The scene mounts it at (684, 281), but exposes it exclusively for an active `wind_shear` fight whose formula target ID exactly equals `windShear`. It never appears in the noncanonical Formula Review encounter.

- No new random rolls, health changes, hitboxes, node-body collisions, chapter/save fields or combat action authority.
- The scene controls analyzed, cleared and enemy-turn count readouts. After a successful *real* Staff Strike decreases the current enemy HP, a bounded 0.24-second pixel-scale impact accent confirms the result; merely selecting an action, analyzing a weakness or triggering retaliation does **not** fabricate a hit. This is post-resolution feedback, **not** an advance attack telegraph or new combat animation authority. A new encounter resets art state; cancel/confirm and restore hide the visual.
- Ambient redraw is capped at approximately 20 Hz while displayed. Its idle motion is small and may be frozen using `ProjectSettings.set_setting("accessibility/reduced_motion", true)` (prior to preview scene creation), or by calling `set_reduced_motion(true)` on the visual directly.
- Chapter I capture pipeline already includes the authored Wind Shear fight. The capture script now also fails if the after-analysis visual identity is absent.

## Verification and review gates

- Contract to execute: `godot --headless --path godot --script res://tests/first_wake_wind_shear_visual_test.gd`.
- Required regressions: existing Wind Shear adapter, retaliation, crossing-scene, save/restore, formula review and Chapter I state tests.
- **Verified native render gate:** at code head `e1f6fd083b2d68e42943b23e4060999d3be72df7`, [Godot capture run 40593688979](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/actions/runs/40593688979) passed. Five real 960×640 renderer frames were hashed and distinguished, including an observed hit. The bar-region test confirms analysis does not lower HP but the actual strike does. The frames remain runner-only and **were not externally viewed**, so no creator visual acceptance or frame-pacing result is claimed.
- **Verified regression boundary:** same code head [native run 40593688590](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/actions/runs/40593688590) PASS and [smoke run 40593688544](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/actions/runs/40593688544) PASS. Exact Windows security custody remains an independent hold.
- **Future image gate:** preserve `chapter1-wind-shear-combat-native-960x640.png` as a comparison, inspect all five new native frames and actual animation on target displays. A passing pixel hash is not a human aesthetic review.
- Creator/player review must check silhouette readability at native scale, legible enemy HP/status/commands, no aliasing or clipping, perceived elemental identity, analyzed/retaliation clarity, idle visual noise, reduced-motion behavior, and frame pacing on target hardware.

## Next art iteration (not implemented)

Artist-review five captured states at native resolution, then extend the current four-pose raster to actual authored in-between timing and better material/light consistency. A truthful **pre-attack telegraph** must wait for a separate, authorized pre-resolution combat-state contract; do not mislabel immediate post-resolution pulses as player counterplay. Avoid assuming speculative enemy species or bosses are canon. Keep this review asset reversible until an authentic creator-approved sprite supersedes it.
