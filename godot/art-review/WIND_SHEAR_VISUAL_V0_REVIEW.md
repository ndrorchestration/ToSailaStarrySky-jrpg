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

The original pixel atlases and fallback geometry remain bounded to a 182×184 logical-pixel review stage on the right of the 960×640 combat panel. The creature is deliberately *not* a humanoid, a canonical new species, or creator-approved final enemy art.

## Original pixel atlas — candidate art v1

- **Committed source:** `godot/art-review/wind_shear_elemental_v1_atlas.png`
- **Editable generation source:** `godot/art-review/generate_wind_shear_atlas.py` (development-only Pillow dependency, not loaded by game).
- **PNG provenance (authoring output):** 320×92 RGBA, four 80×92 adjacent frames, SHA-256 `54f1181e0d9d294c964fc34d5edc3a36ea96d422d6b3770f4cfca200558ba4bf`; asset generated as original art for this study, not sourced from another game's art.
- **v1 frame order:** original idle; analyzed; Gale Force; dispersed. Original atlas remains intact as the static/reduced-motion/action-state fallback, with integer 2× nearest-pixel scaling (160×184 logical pixels).
- **New v2 idle atlas:** `godot/art-review/wind_shear_elemental_idle_v2_atlas.png`, separate 320×92 RGBA atlas of four 80×92 individually drawn idle poses (still, inhale, pressure crest, release), composed from the original base with distinct fin facets and light/shadow polygon linework. Development source: `generate_wind_shear_idle_v2.py` (Pillow, **not** a game dependency). SHA-256 `289c56cf2867705d188aca25d5e5bad4fba5504cd934f2cfcbe15ad52824c6a4`, Git blob `93033337c8b5cd279c45758376be6bf323bbc1ac`. First v2 pose has exactly the same 80×92 pixels as v1 still; the other poses contain 366, 697 and 517 changed RGBA pixel positions from the still, respectively. These are **authored drawings**, not the prior strip-offset simulation.
- **Playback:** idle poses cycle at 0.24-second steps. During damage and Gale Force reactions, analysis, dispersal or reduced-motion mode, the sprite switches back to the existing v1 art. Missing/mismatched v2 import falls back to original v1, never new combat authority.
- The scene first checks native `Texture2D` import, frame dimensions and pixel sampling; if import is not available it returns to existing code-drawn wind geometry. This is still a **review candidate**, not a signed-off production sprite.
- The **nine-frame native capture gate** in `godot/tests/capture_wind_shear_visual_review.gd` covers all four idle atlas poses, the byte-identical reduced-motion still, analyzed state, an **actual resolved Staff Strike hit**, Gale Force study and dispersed study. The actual hit uses the live controller; sampled clock time/Gale/dispersed art studies do not confer extra gameplay turns or victory. The gate checks exact static accessibility parity and live HP-meter behavior. These are Godot framebuffer captures, not the local art contact sheet.

## Rendering and interaction boundary

`godot/scripts/first_wake_wind_shear_visual.gd` is **visual only**. The scene mounts it at (684, 281), but exposes it exclusively for an active `wind_shear` fight whose formula target ID exactly equals `windShear`. It never appears in the noncanonical Formula Review encounter.

- No new random rolls, health changes, hitboxes, node-body collisions, chapter/save fields or combat action authority.
- The scene controls analyzed, cleared and enemy-turn count readouts. After a successful *real* Staff Strike decreases the current enemy HP, a bounded 0.24-second pixel-scale impact accent confirms the result; merely selecting an action, analyzing a weakness or triggering retaliation does **not** fabricate a hit. This is post-resolution feedback, **not** an advance attack telegraph or new combat animation authority. A new encounter resets art state; cancel/confirm and restore hide the visual.
- Ambient redraw is capped at approximately 20 Hz while displayed. Four separately authored idle poses cycle at about 4.17 frames per second and stop during action/reaction states. Reduced motion selects the original still, suppresses sway and transient action pulses, and can be set through `ProjectSettings.set_setting("accessibility/reduced_motion", true)` before the scene is created or by calling `set_reduced_motion(true)`. The authoritative HP number and meter remain readable with motion disabled.
- Chapter I capture pipeline already includes the authored Wind Shear fight. The capture script now also fails if the after-analysis visual identity is absent.

## Verification and review gates

- Contract to execute: `godot --headless --path godot --script res://tests/first_wake_wind_shear_visual_test.gd`.
- Required regressions: existing Wind Shear adapter, retaliation, crossing-scene, save/restore, formula review and Chapter I state tests.
- **Verified native render gate:** at code head `e1f6fd083b2d68e42943b23e4060999d3be72df7`, [Godot capture run 40593688979](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/actions/runs/40593688979) passed. Five real 960×640 renderer frames were hashed and distinguished, including an observed hit. The bar-region test confirms analysis does not lower HP but the actual strike does. The frames remain runner-only and **were not externally viewed**, so no creator visual acceptance or frame-pacing result is claimed.
- **Verified regression boundary:** same code head [native run 40593688590](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/actions/runs/40593688590) PASS and [smoke run 40593688544](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/actions/runs/40593688544) PASS. Exact Windows security custody remains an independent hold.
- **Future image gate:** preserve `chapter1-wind-shear-combat-native-960x640.png` as a comparison, inspect all nine captured native frames and actual animation on target displays. A passing pixel hash is not a human aesthetic review.
- Creator/player review must check silhouette readability at native scale, legible enemy HP/status/commands, no aliasing or clipping, perceived elemental identity, analyzed/retaliation clarity, idle visual noise, reduced-motion behavior, and frame pacing on target hardware.

## Native pixel-shear QA receipt — code SHA e7a18c54

- [Godot native 960×640 capture run 40596874750](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/actions/runs/40596874750): **PASS** with eight individually hashed framebuffer captures. Unlike a source-only review, the measured idle-phase hashes actually differ.
- Baseline static idle **and** sampled reduced-motion full-frame captures produce identical SHA-256 `d92ba082c083b26b2a406eaedbd17cd403bf62d8579d0a07807797e86577f1cb`. This is a native runtime screenshot equality result, not merely a claim about the `reduced_motion` boolean.
- Pressure phase 1 SHA-256 `ded50185fc9aaa2b4efc4b83df2462e653f1b36037f6b1768975badfaa6c3d09`; phase 2 `7e9c97252ccd00faf4f21670b838bbc885b19c29c442c4d545a127b78bf47d4f`.
- The archived contact-sheet/animated-GIF study is not equivalent to an engine screenshot. Native screenshots remain runner-only owing to the existing artifact-storage restriction; no target-display aesthetic acceptance or GPU profiling has been claimed.
- Legacy Crossing placement remains **on hold** under the Ionia-first opening authority in #425/#430. Rendering verification must not move that encounter into the approved story by implication.

## Authored v2 exact-head QA receipt — 2026-10-27

- **Exact code head:** `68cfd5242d569b656ff71244ac17e7b4024a1b67`.
- [Native Godot regression run 40600720720](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/actions/runs/40600720720): **PASS**, including v2 imported 320×92 atlas geometry, four timed frame choices, visible-pixel static-pose equivalence, fight-only art visibility, reaction priority, gameplay isolation and reduced-motion state.
- [Real native framebuffer run 40600720670](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/actions/runs/40600720670): **PASS**, nine distinct named 960×640 capture receipts. Idle phase 1/2/3 SHA-256: `1603f8ac49ffebf1dbff92e8d1c43c94dabf89876037d0270d7cb0ff39f7a71e`, `e5433654ca52dac4c9e341d260389eb7b62bbc4e52125b6e733d76be8e6f1b54`, `30aab2c9a74b31f95b698c8bc4d6771ee41b8976bbd5d5b95eaa53eaceec442f`.
- Static first pose and reduced-motion native full-frame screenshot SHA-256 both equal `d92ba082c083b26b2a406eaedbd17cd403bf62d8579d0a07807797e86577f1cb`. Real hit, Gale Force and dispersal captures also verified.
- [Repository smoke run 40600720776](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/actions/runs/40600720776): **PASS**.
- During regression development, raw Godot imported RGBA buffers differed only in invisible RGB where **alpha was zero**, despite source PNG first-pose RGBA equality. The test normalizes only those fully transparent RGB channels and retains exact comparisons of visible color and alpha; the independent full-frame render SHA check remains strict.
- Strict Windows verification remains bound to the unchanged Defender real-time-protection custody gate. Successful rendering and functional prerequisites do not waive that gate.
- **Review limitation:** Screenshots remain runner-only under existing Actions artifact quota. Their hashes prove real engine frames and timing-state differences, but not creator acceptance, target hardware FPS, in-game aesthetic quality, or revised Chapter I encounter placement.

## Next art iteration (not implemented)

Artist-review the native nine-frame sequence at exact-head resolution, then improve real sprite-sheet choreography, faceted lighting consistency and target hardware animation profiling. The first original hand-authored v2 idle frames are implemented, but are **not** creator-approved final art. A truthful **pre-attack telegraph** must wait for a separate, authorized pre-resolution combat-state contract; do not mislabel immediate post-resolution pulses as player counterplay. Avoid assuming speculative enemy species or bosses are canon. Keep this review asset reversible until an authentic creator-approved sprite supersedes it.
