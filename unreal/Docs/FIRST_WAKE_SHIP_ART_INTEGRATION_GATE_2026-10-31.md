# TSTSS Unreal — First Wake + Aureate Wake + Authored 3D Art Integration Gate

Date: 2026-10-31. State: **ISOLATED REVIEW BRANCH / SOURCE-VERIFIED ONLY / NOT NATIVE-BUILT / NOT APPROVED FOR MAIN OR RELEASE**.

## Exact source authority and integration method

Created branch `integration/unreal-first-wake-ship-art-reconcile-20261031` from **current Unreal foundation** `3a8461a025ec3ee91b422a54fe58b6731ce7f595` (draft PR #608), not from the older Godot or ship branch. Preserved every foundation C++/config file, including `TSTSSFirstWakeState`, `TSTSSWaterLandingGate`, `TSTSSWaterContactAdapter`, `TSTSSCombatAbilities`, `TSTSSPersistence` and `DefaultInput.ini`. This is a real git-tree integration from exact source blob SHAs, not a simulation of a merge.

43 original paths reconciled atomically from:

- Ship/water observer + selected engineering docs/scripts from [draft PR #629](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/629), source `6c8a2502cee98727523f9247129c0b21387eadee` — **16 paths**, including fixed `AureateWakeWaterObserverComponent.cpp`, its source checker and dependency contract.
- Authored wing/GLB + root-pivot pose + four ship root supports + isolated First Wake review map scripts / asset safety + QA from [draft PR #631](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/631), source `a0be9dec82514d6c45314c0ff7d54a3f7356f96b` — **26 paths**, including the more recent four-support `AAureateWakePreviewActor`.
- `unreal/.gitignore` additive privacy-preserving review art exclusions — **1 path**, keeping the foundation's existing UE build cache ignores.

The earlier art branch's `AureateWakeWaterObserverComponent.cpp` and `check_aureate_water_observer_source.py` are **explicitly rejected**, because the former could request Seaborne visual state merely on `bTouchingWater` without first checking accepted water-contact story progression. Selected PR #629 version uses physical-body velocity where simulated and checks `bContactAccepted && bTouchingWater` after the story water gate. This is safer, but still requires native collision proof.

Do **not** replace the foundation `TSTSSFirstWakeState` with the stale copy from the art branch. The current foundation rejects generic `AdvanceTo(SeaContact/FlotationConfirmed)`, requires all engineering inspections and validates save/restore inspection masks.

## Integrated source check

Workflow: [`.github/workflows/unreal-integrated-first-wake-source.yml`](../../.github/workflows/unreal-integrated-first-wake-source.yml). It tests all offline unit suites together, checks the physical observer/story coupling, ensures the declared C++ automation suite is present in the Windows verifier, runs the isolated coastal review-map specification, regenerates corrected meter-scale wing and support GLBs and validates their non-destructive importer manifests, then screens normal wing transformations against the actual GLB geometry. Outputs an artifact containing the two review-only GLBs and numeric clearance JSON.

Additional regression:
- [`test_integrated_first_wake_ship_authority.py`](../Tests/test_integrated_first_wake_ship_authority.py): story milestones and engineering prerequisites, accepted-contact before visual landing, 4 wings / 4 supports / 2 hydrofoils, isolated non-destructive art imports, Orbiter fail-closed and no ship preview story authority.
- [`check_aureate_preview_source.py`](../Tests/check_aureate_preview_source.py) scoped its Submersible-visibility test to *wing* components. The old blanket exclusion of every `SetVisibility(false)` was incompatible with intentionally hidden optional **support** components.

The first integrated workflow run `41191917278` executed 77 offline unit tests and initially failed on a formatting-sensitive test assertion: `replace_existing\x27, False` versus a zero-space form. Source importers themselves still had `replace_existing=False`, the intended fail-closed safety control. The integration test was fixed to normalize whitespace, retaining the check. This first failure is preserved as evidence.

## Native production gates — all still pending

1. Confirm the development host has Unreal Engine **5.8**, Windows C++ build tools, the Python Editor Script Plugin and native scene test infrastructure. Native build of `ToSailTheStarrySkyEditor`, then execute `unreal/Tools/Verify-Unreal.ps1`. Source-only checks and hosted Python do **not** establish C++ compilation, engine test execution or frames.
2. Import the corrected wing and root support GLBs into two *separate*, empty review folders via their manual, guarded importers; verify meters-to-centimeters, actual import transforms, materials/tangents, PBR opacity and light response. Imported assets remain **noncanonical**.
3. Build the isolated First Wake coastal review map; wire a **single** authoritative hull/water-contact observation path for that trial. Do not activate both `ATSTSSWaterContactAdapter` and `UAureateWakeWaterObserverComponent` for the same hull/story until there is a tested ownership contract. A water-volume overlap alone cannot be a SeaContact milestone; verify actual hull/waterline intersection and physical velocity.
4. In the isolated actor preview, expect exactly **4 wings, 4 supports and 2 hydrofoils**. Test all three normal forms and six directed transitions with actual StaticMesh assets; inspect hull root mount geometry, collisions, brackets, forward geodesic bridge, long-range silhouette and performance. Wing root support length-scaling can distort its brass collars and requires cinematic review. True continuous-time collision and structural load tests remain open.
5. Hidden Orbiter/Moon Bridge preview remains default-off and the authored-wing interpolation route remains disabled due to prior witnessed proxy intersections. Do not imply final physics or story unlock from the four-form review enum.
6. Capture genuine UE engine screenshots/video, frame timing and test logs bound to **exact git SHA**. Have creator judge visuals against approved October 30 character/ship reference, then seek separate decisions for engine, narrative, visual and build acceptance.
7. Do **not** merge to protected main, modify Godot First Wake, change Windows installer, publish art or deploy without explicit creator approval. Original PR #608/#629/#631 remain independent draft audit evidence.

## Known project risks

**Source divergence:** new foundation changes while review branches move. Keep integration branch pinned and rebase/reconcile explicitly before native build; do not overwrite newer story, combat and save files.

**Multiple physical observation routes:** only one should be assigned story authority in any native scene until an integration test proves safe handoff/mutual exclusion.

**Engine-native quality:** procedural GLB geometry and source check passes are not artistic acceptance, real-time optical effects, animations or player-visible feature admission.

**Asset provenance:** candidate wing/support meshes are authored review lookdev, not final producer-approved objects; older v1 100× oversized wing GLB is permanently retired for import.
