# Aureate Wake — one-scale geodesic bridge physics prototype (2026-10-27)

**PROPOSAL / Godot 4.7.2 development test, NOT final hull geometry, production art or structural certification.**

## What changed

This first **single-scene, metre-based** 3D study is built inside the current native Godot **First Wake** development project, but **not instantiated into its actual Chapter I gameplay**. It is a reversible response to the previously confirmed geometry mismatch among unmerged foredeck, short-cabin and geodesic-helm prototypes. The original #461 doorway and #482 glass source remain independently archived, not overwritten or silently reclassified.

Run only in an editor or QA harness: `res://scenes/aureate_wake_metric_bridge_study.tscn`. Script `res://scripts/aureate_wake_metric_bridge_study.gd`.

- **Common coordinates:** 1 Godot unit = 1 **provisional study metre**. Gross external cabin study beam **3.50 m**, cabin aft end **z = +6.0 m**, foredeck starts at **z = -2.60 m**, forward tip **z = -5.60 m**. The separately covered crew-cabin + helm envelope spans about 8.60 m, with an independent 3.00 m exposed forward deck. This is NOT the finalized hull, displacement/pressure vessel, or the old art scale mapped literally.
- **Geodesic helm:** dome radius **1.60 m** and diameter **3.20 m**, centered at **z = -1.20 m**, apex **y = 2.95 m**, inside the 3.50 m gross beam. Native triangle tessellation, warm bronze lattice and translucent glass-like material are original *new metric proxies*, **not transferred final #482 shader/asset bytes**.
- **Physical walkway:** physically collidable separate cabin, helm, and bow floor modules in a *shared* scene. A **1.24 m nominal hatch clearance width** and **2.10 m nominal height**, real brass jamb/header colliders, **hinged real `StaticBody3D` door** with open, closed and reopened collision behavior. The forward dome has a **visible missing-pane wedge**, not an invisible sealed pane over the proposed exit.
- **Deck:** original simple open-air 3D deck (no roof). **1.05 m top rails** and vertical posts with actual collision. This is *not* a fully reviewed child-safe, climb-safe, drop-safe or accessible rail system; there are no tested infill panels, drainage/handholds, or verified mobility accommodations.
- **Crew usage:** simple navigation console at the starboard side and out-of-path cabin storage, retaining a centre walking route. This **does not** prove actual habitation for all five protagonists, Talen or guests.
- **No concealed machinery, no advanced traversal, no seaworthiness, no weather/pressure shielding and no autonomous engine system** are represented. Shell glazing has visual mesh only, no structural glass collision/protective integrity. Closing the door alone does **not** form a sealed environmental vessel.

## Acceptance tests for this incremental prototype

`godot/tests/aureate_wake_metric_bridge_physics_test.gd` loads the actual Godot 3D scene and uses:
1. Real `PhysicsDirectSpaceState3D.intersect_ray` on all three floors and both seams to show native colliders, rather than solely checking source meshes.
2. Real `PhysicsDirectSpaceState3D.cast_motion` of a **1.74 m tall / 0.26 m radius** capsule down a **7.60 m** physically continuous centerline route; checks full passage while hatch open, blocking with the door closed, and renewed passage upon reopening.
3. Render mesh, doorway, 1.05 m rails, dome/beam and 2.05 m minimum review headroom checks.
4. Existing native Chapter I **source-locked PR #503 production admission gate** stays `production_ready=false`, actual Ionia-first story/party/save stays unchanged and Resonance stays locked.

`godot/tests/capture_aureate_wake_metric_bridge.gd` records **three authentic 960×640 Godot Compatibility frames**: same-pose open and closed hatch, plus elevated view revealing cabin-to-deck continuity. A positive pixel difference is required. CI uses the digest-verified official Godot 4.7.2 Linux editor, software GL and uploads raw receipts. Linux software-render QA is NOT target Windows device/performance acceptance.

## Next production gates still blocked

- **Art/source:** replace the freshly authored proxy with licensed/creator-reviewed actual 3D mesh and the original study's better glass shader, source hashes, material A/B and independent glare/legibility QA.
- **Human fit and safety:** actual actors (not only a test capsule), walking controller/navigation including turning, player input, door interaction, handrails/infill and correct fall/egress hazard handling. Headroom at the portal perimeter, hinges and shell frame must be mapped in detail, not inferred only from dome apex.
- **Structure and climate:** glass frame collision, weather sealing and any environmental protection are separate physical engineering prototypes; simulated enclosed appearance **is not pressure/safety certification**.
- **Chapter I:** explicit scene transfer/review without giving additional plot access or changing the flyer→Ionia hiring→engineering→test-flight chronology. Re-run v2 checkpoint, combat authorization, accessibility and party tests before adding it to Chapter I.
- **Production:** visual creator signoff, representative actual device FPS/VRAM, installed Windows with intact Defender safety check, player acceptance, deliberately authorized merge and release.

Current state remains **G1/G2 PROTOTYPE RESEARCH**, not G3 gameplay integration or G5 release. Passing this prototype demonstrates only a native continuous physics corridor and a reviewable dimensioned candidate. The creator has not yet approved those dimensions.
