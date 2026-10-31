# Existing work pulled into Unreal First Wake: 2026-10-30

**Status:** code-reviewed source references and additional Unreal automation tests committed; Unreal Editor execution is NOT yet verified. Base: `feat/unreal-5-8-migration-foundation` (draft PR #608). No merge, public release, or canon revision.

## Reuse inventory (do not duplicate)
| Existing source | Already present in Unreal bootstrap | Next gap |
| --- | --- | --- |
| Godot First Wake #547/#600 | `UTSTSSFirstWakeState`, milestone actor and inspector guard | Physical 3D event wiring, dialogue authenticity, scene and native capture |
| Godot combat #601 | `UTSTSSCombatRules`, abilities, turns, rejection/atomic tests | Fixture parity and real 3-active combat scene |
| Godot save expectations | `UTSTSSSaveGame`, `UTSTSSPersistence`, dedicated round-trip test | Gameplay snapshot assembly, version upgrades, clean-machine reload |
| Ship design and PR #610 | Four-form noncanonical Unreal preview actor on sibling draft | Compile, authentic geometry/art, physics, feature gates, native visuals |
| SpriteCook #609 / Notion asset register | Concept atlas inventory | Authorized source originals, licensing, 3D production, proper Unreal import |
| 32-point Chapter I polish contract #582 | Existing quality gate schema | Link each native acceptance artifact to a specific gate; do not auto-close |

## New bounded contribution
- Added `TSTSS.FirstWake.CompleteOrderedLaunchToBerth` to check flyer → Ionia hire → boarding → three inspections → sign-off → launch → sea contact → flotation → empty reserve → berth.
- Added `TSTSS.FirstWake.RejectedRestorePreservesState` to test fail-closed in-memory restore and invalid persisted inspection evidence.
- **Important**: sequential milestone tests are **not proof** of actual collision-derived water contact; they only test ordering. Native Unreal collision and scene authority remains pending.
- **Test status:** written, **NOT EXECUTED** (no UE 5.8 toolchain available to this session). Do not cite as PASS.

## Recommended next integration order
1. Fix actual UE compile blockers from logs before expanding the engine.
2. Bind overlap/hit collision to sea-contact and flotation evidence instead of allowing generic milestone interaction to imply real physics; add negative tests for scripted shortcuts.
3. Bind authentic original First Wake dialogue and party state to spatial UE interactions; retain exact Ionia-first order and Lyra's later join.
4. Make one 3-active encounter and single save/resume scene work end-to-end.
5. Capture exact-head native screenshots, packaged performance metrics and creator art review.
6. Only then revisit globe/LOD/aurora/lunar layers with a benchmarked streaming prototype.

The creator-approved cast reference outranks older visual mockups. Five Lights are story affinities and do not automatically confer combat spells. 
