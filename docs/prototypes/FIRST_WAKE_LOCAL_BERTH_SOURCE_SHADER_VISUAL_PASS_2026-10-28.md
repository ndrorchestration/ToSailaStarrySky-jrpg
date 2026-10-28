# First Wake local berth — original-source shader & maritime art pass

**2026-10-28. Draft-only visual handoff, not approved coastal geography, rescue protocol, final production art or finished Chapter I.**

## Provenance / why

The independently validated [native berth physics #562](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/562) at `c561fc0264b8fa51cc419ceaf42575c296bcab94` has real `RigidBody2D` travel and an independent `Area2D` contact sensor, measured low-speed settling and player-secured lines. Genuine initial Compatibility GL screenshots show the *functional but crude* block pier, flat sky/sea and simple hull. The branch already includes source `first_wake_cinematic_sky.gdshader` and `first_wake_cinematic_sea.gdshader` and original timber/brass palette from `first_wake_cinematic_deck_architecture.gd`, all verified in the earlier live game [#555](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/555).

This child visual pass draws on those **actual in-repository, source-traceable assets**, not unrelated downloaded or AI-referenced images:
- `godot/scripts/first_wake_berth_cinematic_stage.gd`: adds real source shader `ColorRect` sea/sky behind the actual hull and authored pier; `M` reversibly sets real sea material `motion_scale=0/1`, without changing contact or chapter state.
- `godot/scripts/first_wake_berth_pier_art.gd`: original noncanonical timber-plank berth art, structural support silhouettes, brass bitts, reflections, safe-contact progress cue and rope *only after* the player actually secures lines. Stage reads source `phase`, `hull.position.x` and measured `stable_seconds / STABLE_SECONDS`, but has **no physics, lore, navigation or save authority**.
- `godot/scripts/first_wake_berth_ship_art.gd`: source-palette compact dragonfly-shaped hull and four drawn wing planforms attached to the **existing physical RigidBody2D**, never a fake physics actor. It is still a **2D visual study**; the original native 3D ship lives in the upstream separate wide camera and no false 3D render claim is made.
- `godot/scripts/first_wake_local_berth_game.gd`: swaps rectangle placeholders for these stage nodes, exposes M accessibility control and telemetry for independent sensor contact + stable dwell. All voyage/berth physics constants and story/save admissions remain unchanged.
- `godot/tests/first_wake_local_berth_game_test.gd`: retains the complete real playable flyer → Ionia hiring → true water splashdown → reserve inspection → local berth physics → secure lines → return/reload story test; adds checks for exact reused source shaders, art no-collision/no-story authority, shader reduced motion, hull-parent linkage and no contact on art changes.
- `godot/tests/capture_first_wake_local_berth_game.gd`: existing original three native Godot GL frames remain the visual proof: awaiting approach, actual contact, secured lines. Both source PNG hashes and bounded preview JPEGs are logged inside the CI run (PNG not downloadable under current artifact quota). **Visually inspect** legibility and quality independently from technical green.

## Acceptance and stop conditions

- A complete exact-head Godot 4.7.2 headless import and original 48-check game entry, expanded local berth gameplay tests, original 3D source ship/engine warning tests, and authentic GL capture of the three new frame states must succeed before **technical source acceptance**.
- Source shader visuals need creator review at native 960×640 resolution, plus contrast/readability, color-deficiency and reduced-motion coverage on actual Windows hardware. Artist acceptance must be recorded separately.
- No geolocated harbor, established landfall/route, 3D maritime simulation, family reunion, secret ship configuration, fuel alignment resolution or code-signed/published installer is included.
- Original [Windows #551](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/551) functional installer proof must be reconfirmed on the new exact head; independent Defender realtime-on custody remains a fail-closed gate. No public release, merge or irreversible canon modification.
