# First Wake — Aureate Wake profile and tidal lighting visual pilot

**October 28, 2026 · REVIEW-ONLY · ART ACCEPTANCE PENDING.** This is a reversible **in-engine Godot 4.7.2 implementation** in the creator-directed Ionia-first Chapter I flight/splashdown scene. It is not an image-generation concept, finished production ship model, literal planetary ocean physics, ship-capability reveal, canon/spec authorization, or Windows release.

## Actual implementation

| Source | Runtime purpose | Authority boundary |
|---|---|---|
| `godot/shaders/first_wake_tidal_surface_review.gdshader` | New Godot `canvas_item` procedural water material: depth color, horizontal multi-scale wave bands, restrained reflected warm sunlight and coastal foam. Uses GPU material time for visual animation. | Screen-space decoration only. **Does not** create wave forces, real depth, physical collisions, navigation or fuel chemistry. |
| `godot/scripts/first_wake_aureate_wake_visual_review.gd` | Original hand-layered deck, copper/wood hull and keel, articulated-looking fixed side-wing silhouette, railings, and a segmented provisional **geodesic bridge dome** with restrained luminous fittings and stage-reactive engine highlight. | A decorative child of the **same original `RigidBody2D`** with its **unchanged 144×34 rectangular collision geometry**. No executable movement, magical Art, new mode, launch right, submersible, atmospheric or lunar capability. |
| `godot/scripts/first_wake_flight_water_review.gd` | Draw order: atmospheric dusk/shore behind animated water; the same physical vessel over sea; UI panels above both. Updates the cosmetic rig's state when genuine flight/water/berth phases change; exposes no new story gates. | Existing physics water sensor, independent berth contact/stability sensor, force and speed, reserve inspection, failed propulsion, and family opening remain in original script and unchanged. |
| `godot/tests/first_wake_tidal_ship_visual_rig_test.gd` | Automated native test verifies shader/rig are instantiated in real scene, can't capture input, correct collider and water/berth sensors remain, story party is Ionia-first, and no unauthorized capability appears. | Technical invariant and import/render gate **not** visual artistic acceptance. |
| `.github/workflows/godot-first-wake-pilot.yml` | Executes the new native test in the pinned editor pipeline, while retaining physics, save, chronology and return-route tests. | No workflow release bypass. |

## Visual review against the visual bible

The visual language intentionally leans on a small, warm reclaimed-material ship against cool twilight, warm glints on water, segmented reflective glass, a consistent dark/navy stage and restrained teal highlights. The open deck and provisional geodesic bridge are consistent with the creator's design **intent**, but the current image is just a review silhouette, not an accepted ship visual bible or a mechanical revelation. It is rendered in actual playable Godot at 960×640; changing the source scripts changes the game screen.

**Unresolved production art work:** pixel-authored and creator-approved precise ship silhouette, wing mechanics for all approved/hidden configurations and story gate, high-resolution layered materials/textures, a proper panoramic camera lens and depth, coastal environment source geology/biome/lighting, cinematic sky/cloud/weather scattering and perceptual-quality water foam/spray, dynamic scale/readability, character sprites and deck activity, audio, accessible reduced-motion user control and human/player shot approval.

**Visual evidence:** [first genuine shader + dome native two-frame comparison](reviews/native-evidence/2026-10-28-first-wake/aureate-wake-native-tidal-dome-two-frame-review.svg) comes from original 960×640 PNG buffers in [native Godot Actions render run #40662312067](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/actions/runs/40662312067) at exact script head `0070a3de854aa201683ad9562cdbd50cedc402e4`. Two SHA-256 PNG receipts were independently produced by Godot and logged. **The later post-composition visual pass is now separately captured and published:** [two exact native Godot waterborne and berth screenshots](reviews/native-evidence/2026-10-28-first-wake/aureate-wake-tidal-atmosphere-native-review.svg), [native capture run #40662836358](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/actions/runs/40662836358), source head `73e5fdcf4757d2de13d6fe9baf492f5283f0f653`. Source PNG hashes: waterborne `adbb42baa99252cb3ad20812204161dff60c2142d10979ea9052782dee075386` (95,322 bytes) and berth secured `5b6708b937309028f6032155072631c6cf8165b7db1d5614ff89b1c95d8d08d2` (99,579 bytes). Both source buffers were emitted from the native renderer, and their exact bytes were embedded losslessly into the SVG without screenshot editing. The older preceding two-frame sheet is retained separately as a before-cleanup receipt; do not conflate the two source heads. The two original frames are review-only evidence, not art accepted for marketing.

## Native review acceptance evidence

- The revised shader/rig native integration test was added to the pinned Chapter I workflow; [Godot run #40662836420](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/actions/runs/40662836420) completed **SUCCESS** at the post-compositional source head `73e5fdcf...`, including the existing flight/water and save routes.
- [Native rendering run #40662836358](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/actions/runs/40662836358) completed **SUCCESS**, and the resulting actual two-frame sheet is directly available from the README.
- **Human visual acceptance remains pending.** The current ship is still small at the nominal 960×640 overview; the coast and cloud strata are preliminary shapes, not a final approved pixel-authored ship/world art pack.

## Required check

- Pinned `godot --headless --path godot --editor --quit`, `godot --headless --path godot --script res://tests/first_wake_tidal_ship_visual_rig_test.gd`.
- Existing `godot/tests/first_wake_flight_water_review_test.gd` must still demonstrate real native water contact and safe berth, then family transition, no pre-splashdown Lyra.
- Existing `capture_first_wake_recovery_review.gd` must produce authentic distinguishable original 960×640 PNG frames from the renderer, not a standalone diagram.
- No `main` merge or public release without author approval. Independent Windows Defender custody remains **BLOCKED** until separately cleared by authorized security processes.
