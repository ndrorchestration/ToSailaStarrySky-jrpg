# First Wake: independent playable local berth gate

**2026-10-28. Native gameplay candidate; NOT creator-approved map geography, a canon towing process, full Chapter I or an official release.**

## Source and intent

Derived from [draft PR #555](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/555) exact `40e086d04c641ee98cd8bed69f8d2c1021cb0930` — the existing **playable** Ender→Ionia first-flight, actual native 2D splashdown, PW-01 visual, and shader-enhanced open-water shipboard scene. The separately tested [draft #552](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/552) has an independent **local berth** sensor and requires an actual overlap/low-speed dwell; [draft #548](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/548) admits the later family review only after explicit safe mooring. Those tracks do **not** share a combined game branch. This candidate implements a *smallest reversible physical berth* in the #555 live game rather than passing a hard-coded `mooring_confirmed=true` value or copying conflicting physics and save controllers.

## New playable mechanics in the real Godot main entry

1. Ender must complete the legitimate Ionia-first job and engineering path; the ship must physically enter the **original local ocean Area2D** and settle with buoyancy, then the game restores postflight control to Ender.
2. Player must stand near the depleted-reserve station and finish the actual Ender/Ionia inspection dialogue. `first_wake_game_session.gd` must confirm `postflight_diagnosis`, party `[ender, ionia]`, actual earlier contact and reserve observation.
3. Player approaches Ionia aboard the open-water ship and presses **E** to begin a **LOCAL berth review**. This is an explicitly game-level handoff, not a claimed rescue service, world harbor, long-distance route or production ocean. At the original gameplay entry, a new Godot scene instantiates a *second real* `RigidBody2D` with `CollisionShape2D` and independent `Area2D` berth contact sensor. Initial physical berth contact is absent.
4. Player presses **E** to initiate measured local movement. The real hull moves horizontally through 2D physics, with actual Area2D overlap required. The hull must settle below the specified speed threshold for a sustained 0.42 seconds; **E** then secures the lines manually. A camera frame, contact flash or timer without overlap cannot create a secured-berth receipt.
5. Session only admits the safe local result from an **in-tree instance of the exact berth script**, whose sensor still overlaps the actual rigid hull and whose snapshot demonstrates explicit lines, contact, stable dwell, Ender/Ionia-only party and no invented global route or reunion. **R** returns to the same playable shipboard deck for further interactions and the postflight checkpoint. The local berth state is deliberately **not saved** under the preexisting `tstss.first-wake.first-flight.v1` checkpoint; reload loses the unpersisted berth receipt rather than inventing a historic sensor event.
6. The Lyra/Talen postflight story from #548 is **not** brought into this branch, because its safely moored stage, physical world route and save upgrade require separate approval and cross-branch testing. No early magic/fuel solution, ship-secret reveal or canon-world landmark is added.

## Exact-head admission evidence (required, not assumed)

- `godot/tests/first_wake_local_berth_game_test.gd`: exercises the real F5 main game from Ender's flyer through Ionia, engine-check dialogue, genuine original `Area2D` splashdown, open-water player movement, depleted reserve, captain's explicit local-berth request, new physics sensor approach, stable measured overlap, explicit line action, return to player control, and checkpoint anti-forgery. It requires failing negative cases: preflight/pre-reserve/remote-capta​in requests, no early lines, no contact without overlap, no legacy save migration or automatic family reunion.
- `.github/workflows/godot-first-wake-pilot.yml`: adds this test to the **existing pinned native 4.7.2** game suite without removing earlier #555 live Godot and real graphical acceptance gates.
- Pending **same-head** native Godot test and follow-on new scene visual capture; previously green #555 checks do not prove these changes until this new branch passes.
- Standard Windows functional Setup.exe/installed native window tests remain separate; separate Defender-on security, publisher signing, target-player acceptance and explicit release approval remain open. No installer is publicly published.

**Explicit nonclaims:** no geolocated island, navigable planetary coastline, rescue vessels, approved maritime procedure, actual submersible or lunar capability, production ocean forces, Lyra recruitment or plot resolution. This is strictly local 2D physical gameplay that preserves existing ship/3D water-view separation.
