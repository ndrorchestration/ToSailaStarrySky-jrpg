# Aureate Wake — Wing Structural Ribs vs Dome Frame/Collar, Narrow-Phase Gate

**2026-10-28 | Stage B1.2 | SOURCE-EXACT NONCANON GEOMETRY ANALYSIS | PHYSICAL ADMISSION BLOCKED**

The earlier [#541](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/541) AABB pass measured 190 broad overlaps (all around geodesic helm). [#543](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/543) then demonstrated **0 sampled SAT contacts between wing *membranes* and glass *panes*** over five original poses (70 glass triangles, 360 membrane triangle observations, 1,094 triangle candidate tests; [native run #40632616570](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/actions/runs/40632616570) PASS).

This follow-up performs the next **materially different** narrow-phase source-mesh test rather than treating membrane clearance as whole-wing clearance.

## Actual original geometry targeted

- Wing side: `BrassRibBundle_*`, `DarkRibBundle_*` and `GlassRibBundle_*` for PortFore, PortAft, StarboardFore and StarboardAft.
- Bridge side: original `GeodesicFrame` and `BridgeBaseCollar`.
- Frame: all meshes live in the same **provisional original ship-art coordinate frame** inherited from source-exact #541, not approved metres. The source files are not reshaped.
- Pose: original 0, 25, 50, 75, 100% of the *ordinary 15° artist review sweep*, with pose restoration.
- Method: grid-bucket indexed X/Z candidate lookup, 3D triangle bounding-box rejection, discrete triangle SAT with coplanar axes. Bounded candidate work to at most 1.5 million tests. Results break out frame vs collar contacts by five poses and by the four wing identities.
- One true native Chapter I engineer scene, after actual Ionia-first hiring/boarding and explicit hidden review opt-in. No rendering permission, player controls, story/roster, save data or visual layout changes outside test-only scripts.

## Scope and interpretation

A SAT-positive intersection identifies potential geometric interference of *source rib/frame or rib/collar triangles at a sampled artist pose*, not a pressure-shell leak, true animated contact response, real cabin collision or confirmed passenger injury. A zero result would **still not clear** other fairings, hull interfaces, continuous intermediate poses, actor body volumes, geodesic helm ergonomics, exterior/interior and doorway conflicts. The implementation always returns `physical_integration_ready=false`, `continuous_sweep_verified=false`, `actor_clearance_verified=false` and `status=NOT_CERTIFIED`.

This source architecture deliberately avoids auto-adjusting the proposed 2.5m/art-unit dimensions. The existing 3.40m exterior versus separate 3.80m interior, 3.80m dome versus 2.35m entry and 1.825m upper standing clearance vs 2.05m review target remain independent **blocking proposals**.

Native test file: `godot/tests/first_wake_wing_frame_narrow_probe_test.gd`; report prefix `FIRST_WAKE_FRAME_NARROW_REPORT`; exact-head Godot 4.7.2 CI runs it alongside original #541, #543 and Chapter I regressions and native screenshot capture.

**Status at creation: CI PENDING.** Exact counts must be read from the execution receipt before being described as evidence. No merge, release, player capability, new ship mode, or restricted plot material.
