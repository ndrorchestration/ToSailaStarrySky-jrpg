# First Wake — painted coastal sky, real Windows renderer QA (2026-10-28)

**Status:** TECHNICAL PASS, visual improvement **observed in actual native engine**, final cinematic-art acceptance HOLD. All code in stacked draft [PR #581](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/581), exact runtime head `42694641ba044ce029608f1b13aafafa27305b43`.

## What changed

The playable opening dock now uses the preexisting project's real `first_wake_cinematic_sky.gdshader` as a 960×402 behind-parent CanvasItem, replacing the flat color bands and repeated circle-cloud sky on the initial coastal stage. The historic procedural sky code is preserved verbatim behind `painted_sky_enabled=false` for direct visual rollback. The coastal skyline, sea and structural dock remain intact. The GPU shader is static and has no independent story or collision authority.

No opening dialogue, flyer, player inputs, movement bounds, character art source, story order, party, launch, RigidBody2D water contact, postflight reserve, saves or accessibility controls were altered.

## Exact real test evidence

The actual creator's unchanged Ionia and Ender 432×432 source JPEGs were imported from the private P4 local review set into a separate Windows QA worktree; source SHA-256 checks are documented in [PR #578 native art handoff](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/blob/review/first-wake-creator-portrait-overlay-20261028/godot/art-review/FIRST_WAKE_REAL_CREATOR_PORTRAIT_NATIVE_EVIDENCE_2026-10-28.md).

**Windows host:** official Godot 4.7.2 stable, Intel Iris Xe / OpenGL 3.3 Compatibility, native 960×640. Verified at the exact code head above:

- Native editor import — exit 0
- `res://tests/first_wake_painted_coast_test.gd` — PASS, 11 checks (shader instance, background depth, fallback, no physics authority)
- `res://tests/first_wake_game_entry_test.gd` — PASS, 48 checks (real landing, postflight player, save/resume, legacy isolation)
- `res://tests/capture_first_wake_creator_portrait_real_art.gd` — PASS, both real creator JPG portraits and exact story dialogue in native OpenGL
- Mean sampled per-channel absolute RGB difference in stable sky area x40–680, y120–320 versus previous exact-head flat-sky frames — **42.18/255**, measured from full-size PNGs. This demonstrates actual framebuffer impact rather than a ShaderMaterial assigned but never seen.

Genuine **after-upgrade** 960×640 PNG source hashes:

- Ender at job notice: `4dd8c91421da138c29677499adef173f1b7f5a661206236b226460d9b1d64c77`
- Ionia at captain interview: `7ebcf4a36122ac6761df526f0da5e26607bae00451edbad91768082c21967ecc`

Before-upgrade references (original PR #578 actual art, same character JPGs):

- Ender: `e1739b52bca8a391233b713acf084ddf1b1bf32ea13ea35665b1a96814971009`
- Ionia: `ff18158df89c0c8334cdcb9586da9d92660ecbfe54366ab17ad713889afa1684`

The screenshots, full-image source hashes, and private comparison HTML have been saved in the user's local **Aetherwake / Verification Sandbox / FirstWake-CreatorPortrait-Evidence-20261028** area. The existing local `SEE FIRST WAKE - Actual Godot Screenshots` shortcut opens a native **before/after** comparison. Neither original source JPGs nor their derived full-size PNG captures were published to the public repository.

Public exact-head [Godot painted-coast CI](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/actions/runs/40672754282), inherited First Wake gameplay/Ionia GL and repository smoke CI passed. These public CI jobs compile/test without the creator JPEGs. They are distinct from the local actual-source screenshot evidence above.

## Artistic assessment

**Improvement verified:** the dock's flat circles and uniform sky bands are replaced with nuanced cloud shading and a warmer, more painterly atmospheric backdrop. Both correct character portraits remain visible, the sky card is clear of actor paths, and the UI remains legible.

**Not yet production quality:** shoreline mountains remain flat polygon layers, dock boards and side props need material-texture treatment, reflection/rim-light integration and painterly composition, and **both field actor sprites are still the unapproved earlier provisional walk sprites**. They are not the high-fidelity portraits turned into proper multi-directional animated sprites. No style approval is implied by technical PASS.

## Production priorities

1. Source-bound production sprites for Ender/Ionia with authored transparent direction sets and convincing actual walking gait, preserving the current high-fidelity identity; no old SVG sprite promotion.
2. Coastal pier material and environmental depth/lighting study using real game geometry, honest native 960×640 captures, physical bounds unchanged.
3. Only then add further Chapter I character visual introductions at their actual story timing.
4. Windows security/Defender exact release gate remains separately blocked. No merge, installer, release, public asset upload or canon revision authorized.

The worktree uses reversible source code and original image source custody; this evidence belongs to the current **draft** only.
