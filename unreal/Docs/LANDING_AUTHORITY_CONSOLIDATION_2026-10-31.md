# Unreal First Wake — single water authority and faster integration

Status: **draft C++ source implementation; not yet compiled or run with UE 5.8**.

## Conflict found and resolved in source

The Unreal migration bootstrap had TWO water progress components:
- `UTSTSSWaterLandingGate::Observe` accepted public caller-supplied `bHullTouchesWater` and speed, with 2.0 seconds / 25 cm/s thresholds.
- `ATSTSSWaterContactObserver` observes a configured real rigid-body overlap, with provisional 1.5 seconds / 35 cm/s thresholds.

After the later state boundary restricted `AdvanceTo(SeaContact/FlotationConfirmed)`, the old gate could no longer legitimately advance the story. Worse, its old regression still expected it to do so. Competing landing authorities and incompatible threshold sets would make QA and player experience unreliable.

## Changes
1. The old `UTSTSSWaterLandingGate::Observe` now returns false, resets its timer, and remains temporarily callable only for compatibility. New level authors must use `ATSTSSWaterContactObserver`; do not add new calls to the legacy gate.
2. Replaced old synthetic-water success assertions with `TSTSS.FirstWake.LegacyWaterGateFailsClosed` checking that invented observations and direct story advances cannot complete landing.
3. Observer resets its stability counter on frame deltas over 0.25 seconds rather than counting a single long stall as a period of stable flotation.
4. No modifications to existing Godot First Wake, approved characters, ship visuals, Five Lights, or hidden traversal reveals.

## Pull-in priorities
- Reuse existing Unreal #608 story state, persistence and combat; new standalone engines would add integration cost.
- Reuse native Godot #547 genuine ocean-contact contract and #562 physical berth settling *as separate test specifications*. Port observable behavior, not old GDScript or numeric thresholds.
- Keep PR #614 full-path synthetic tests separate until any direct water transitions are replaced by a native editor physics fixture.
- Consider PR #610 geometry as a study and PR #609 materials as reference only; neither provides a verified buoyant vessel component.
- Do not promote until the pinned UE 5.8 Win64 editor builds, all automation runs with per-test result evidence, a test map demonstrates real overlap and sustained flotation, and creator-referenced character/ship rendering is reviewed.

## Remaining correctness gap
The current observer is a collision overlap + vertical velocity proxy, not a buoyancy solver. A body could settle on the seabed and falsely appear stable. A native scene test must additionally establish hull/surface height, displacement/buoyancy support, upright orientation, and no land/seabed collision before calling it production flotation. The observer is tick-based rather than fixed-physics-step; variable frame duration needs native tests. No playable or performance claims are made.

## Quality and speed rule
One canonical implementation per mechanic; one authoritative ordered First Wake story state; shared reusable save/combat contracts; exact-head native test receipts before visual or chapter acceptance. Minimize parallel prototype branches and record outstanding conflicts explicitly.
