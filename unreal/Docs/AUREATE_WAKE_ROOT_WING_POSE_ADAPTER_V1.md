# Aureate Wake — root-pivoted wing geometry adapter v1

**Status:** source candidate only. Unreal 5.8 native C++ build, map/transform screenshots and clearance testing **PENDING**. Do not merge or release from source-level tests.

This draft is stacked atop the authored wing GLB [PR #625](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/625) and the First Wake review benchmark [#622](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/622). The ship actor remains one `AAureateWakePreviewActor` with exactly four wing components and two Seaborne hydrofoils. No new ship runtime authority.

## New integration path

- `bUseRootPivotedWingPose = false` by default, preserving all legacy 100-cm-centered Cube preview positions.
- When `AuthoredWingMesh` is present **and** `bUseRootPivotedWingPose` is explicitly enabled, `WingPoseForMesh` selects a root-pivoted arrangement authored for the current **280-cm +X span** asset.
- Front roots at approximately +155 X, aft at -180 X; port and starboard roots at +/-112 Y; four wing roots, not four overlapping 100-cm preview cubes.
- Skyborne: wings project broadly outboard with distinct forward/rear sweep. Seaborne: wings fold above the waterline in review only. Submersible: wings tuck lengthwise and remain visible. Orbiter: four equal-scale sails directed +Z, -Z, -Y and +Y with forward hull/bridge unchanged.
- `RefreshWingMeshes()` recomposes existing form after new artist mesh assignment when not transitioning; both `SnapToForm` and transition interpolation use the mesh-aware pose. A missing authored wing refuses new form changes while the opt-in flag is true.
- The old `bAllowOrbiterPreview=false` default and `RequestForm` preview guard remain untouched. The hidden form is not a player unlock.

## Mandatory Unreal/native acceptance

1. Build the exact PR head with the UE 5.8 Windows C++ toolchain and correct all compiler/Unreal API errors.
2. Import the generated one-wing GLB to a distinct review path. Verify it imports as a StaticMesh with three material slots, correct Unreal axis and unit handling. Set `AuthoredWingMesh` on an isolated preview actor and **manually** opt into `bUseRootPivotedWingPose`.
3. Compare the legacy Cube preview with authored wing at the same actor transform, test all four Sky/Sea/Submersible/Orbiter modes in an isolated test level, respecting Orbiter opt-in; visually inspect **all four wing root joins**, bridge/deck clearances, wing intersections, foils, scale, imported alpha and silhouette.
4. Repeat transformations in both directions and interrupt mid-transition; confirm no popping/interpenetration after refresh, and no story sea-contact or flotation event emitted by form requests.
5. Capture actual UE 5.8 rendered screenshots (not generated geometry previews), with fixed cameras, engine SHA and frame-time traces.
6. Get creator aesthetic approval and independent native physics QA before considering promotion into the playable First Wake.

**Limitation:** Current poses are review geometry guesses, NOT physically engineered hinge kinematics, seaworthy sealing, buoyancy or a cinematic art pass. User-approved art and ship design still govern all final proportions.

[Unreal wing art GLB review document](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/blob/feat/unreal-aureate-wing-glb-artpack-v1/unreal/Docs/AUREATE_WAKE_WING_GLB_ART_REVIEW_V1.md)


## Corrected asset import gate — October 31, 2026

The original wing v1 GLB is **retired for import**: it encoded centimeter geometry as glTF meters and could appear **100× too large**. The [corrected generator](../Tools/author_aureate_wing_glb.py) writes positions in meters (0.01 × source-centimeter coordinate), preserving unit normals. Expected full X bounds are approximately -0.16 to +2.804 meters (about 296.4 cm including the rear brass hinge). The prior v1 GLB is not valid review input.

New [fail-closed review importer](../Tools/import_aureate_wing_review.py) and [import regression tests](../Tests/test_import_aureate_wing_review.py) check the exact corrected manifest SHA-256, glTF meter-scale metadata, 2.8-m membrane span, 3-section material layout and empty candidate destination.

Offline check (can run without Unreal Engine):

```powershell
py -3.11 unreal/Tools/import_aureate_wing_review.py --glb "C:\\TSTSS_Review\\AureateWake_Wing_Lookdev.glb" --manifest "C:\\TSTSS_Review\\AureateWake_Wing_Manifest.json" --check
```

Editor-only workflow: enable Python Editor Script Plugin and Unreal Interchange, run the same script inside Unreal Editor Python with `--import-review` instead of `--check`. The editor must present its pipeline options for explicit operator inspection; destinations with existing assets are refused, and no actor/map is modified. Validate imported centimeters, Z-up conversion, normals, mesh sections, material transparency and pivot before manually linking to `AuthoredWingMesh` in an isolated map. **Unreal native execution NOT VERIFIED; source checks cannot satisfy this acceptance gate.**

Source references: [Khronos glTF 2.0 units](https://github.com/KhronosGroup/glTF/blob/main/specification/2.0/Specification.adoc); [Epic Unreal Interchange import](https://dev.epicgames.com/documentation/unreal-engine/importing-assets-using-interchange-in-unreal-engine).
