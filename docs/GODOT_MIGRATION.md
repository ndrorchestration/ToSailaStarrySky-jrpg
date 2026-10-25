# To Sail the Starry Sky — Godot-native development direction

**Creator decision: 2026-10-24.** Godot 4.7.2 Standard (GDScript) is the target engine for all NEW game/runtime/world-map development. Stop adding or extending p5.js, JavaScript, Three.js, HTML Canvas, NW.js and Node-based playable prototypes. This does not mean deleting valuable source, game history, art or pending migration evidence.

## Where development actually stands

- Protected `main` still boots the legacy browser/p5.js runtime. It has NOT yet been replaced.
- Native Chapter I work exists in stacked Godot branches: PR #306 (pilot), #337 (Chapter I), #338 (content), #339 (codec), #341 (Windows preview), #342 (formula), #343 (encounter), #344 (save store), #345/#346 (combat), #347 (party authority).
- Native migration continues on top of `feat/godot-first-wake-party-combat-authority-20261022` for now. This integration branch does not imply all stacked PRs are safe to merge as-is.
- Planetary geometry/flight and visual experiments in draft PRs #349 and #363, and issue #350's native renderer archives, are *research inputs*, not canonical planet geography or admitted game scenes.
- This slice ports PR #349's **spherical math and geodesic flight** to GDScript and adds a separate Godot visual study; do not imply climate, globe tiles, visuals, ship physics or Chapter I synchronization are production-complete.

## Canon, saves, and permission boundaries

1. Preserve Ender, Lyra, Ionia, Reson, Aepex; First Wake sequence, existing outcomes, abilities and rules, Dragonfly/Aureate Wake identity and all locked visual/lore specifications.
2. No JS runtime code imports, eval, hidden browser bridge or npm dependency from any Godot game scene.
3. JS source is frozen as **legacy parity fixture**, not the destination engine. Keep it readable and traceable until equivalent native tests/receipts and save migration prove replacement safe.
4. Do not reinterpret 2D First Wake's dock geometry as final global terrain. Illustrative planetary radius (6371 km), coastlines, biome layout, camera scale and flight constants remain NON-CANON.
5. Preserve and version legacy saves. Godot save codec must accept only schema explicitly authorized and tested, reject unknown revisions, back up before any conversion, and maintain restart/recovery evidence. Never silently transform saves or unlock hidden route content.
6. Aurora/Moon Bridge: no route appears merely because a scene renders decorative ribbons. Gate activation on the full-moon clue, correct nearby auroral approach and rare gravitational/magnetic alignment, with spoiler protection and tests.
7. No merge, release, human-acceptance or visual-acceptance claim from static inspection or synthetic imagery.

## Migration work order

| Priority | Native subsystem | Minimum admission evidence |
|---|---|---|
| P0 | Consolidate native First Wake Chapter I, player art, dialogue and stage machine | Godot 4.7.2 exact-head import; reproducible native path; visual and uncoached player review |
| P0 | Combat/stat/party + local persistence | Legacy/native golden state-transition fixtures, deterministic battle output and corruption/recovery tests |
| P1 | Planetary coordinates, geodesic flight, horizon, map projections | Native regression tests for poles, antimeridian, horizon, radius and units; no fixture planet promotion |
| P1 | Godot Forward+ globe, clouds, sun, atmosphere and bounded LOD | Native shader compile, 3 distinct genuine captures, frame-time/VRAM on target hardware, visual review |
| P1 | Dragonfly 3D flight, world discovery and safe ground/sky/planet transitions | Real landing/pathfinding/visibility/secret-gate tests and versioned save round trips |
| P2 | Cinematics, audio, UI/accessibility, animation and export | Parity/visual sign-off, Windows clean-install and launch, provenance and license checks |
| Exit | Retire browser release path | Native feature, content, accessibility, and saves verified; owner authorizes release cutover |

## Immediate Godot workflow

- Open `godot/project.godot` with Godot **4.7.2 Standard**. Its Chapter I player-preview scene remains the native entrypoint.
- Open `godot/scenes/planetary_globe_study.tscn` separately with **Run Current Scene (F6)** for the experimental globe; it is not connected to the save/game route.
- Run `godot --headless --path godot --editor --quit`, followed by `godot --headless --path godot --script res://tests/planetary_geometry_test.gd` and `.../planetary_flight_test.gd`.
- Preserve JS regression results as historical baselines, but write **new tests in Godot/GDScript**.
- Native CI is required but not equivalent to human creator approval. Distinguish `STATIC`, `NATIVE TEST PASS`, `RENDER REVIEW PASS`, and `RELEASE`.

**Known non-deliveries:** fully migrated playable campaign, approved final globe art, owner-private atlas content import, native Moon Bridge reveal, published/installed release, safe save transfer and current exact-head native test result.

## 2026-10-24 native tile/streaming metadata handoff

Native `planetary_tiles.gd` and `planetary_streaming.gd` translate PR #349's cubed-sphere tile indexing, polar/dateline face-neighbor sampling, bounded visible-tile address planner and automatic LOD downgrade. `planetary_tile_cache.gd` is a capped memory-only LRU. All run without JavaScript, Node or browser renderer. Coordinates continue to use a deliberately unapproved test radius; this is **not** actual terrain mesh LOD, network/disk streaming, visibility authorization, geographic canon, save migration, or Moon Bridge reveal. Native tests run as their own Godot CI steps; isolated study only.

**Parallel work notice (user-provided external agent notes):** Hyperagent reports a separate **local-only**, unpushed `work/godot-native-ui-validation-20261024` branch based on native Chapter I at `74fe1bce7a8a02eb3cbf30f725fa2af0925ba670`. Its reported native title/UI wrap/modal fixes, test runner, 34 successful checks and nine Mesa/Xvfb frames are **not independently verified in this PR** and the branch is not accessible via GitHub until pushed. Compare and integrate through isolated PR/patch review, not by resetting this branch or assuming the evidence is admitted. Do not replace the legacy save IDs merely for game-title cosmetics.
