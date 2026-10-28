# Aureate Wake — one-scale geodesic bridge physics prototype (2026-10-27)

**PROPOSAL / Godot 4.7.2 development test, NOT final hull geometry, production art or structural certification.**

## What changed

This first **single-scene, metre-based** 3D study is built inside the current native Godot **First Wake** development project, but **not instantiated into its actual Chapter I gameplay**. It is a reversible response to the previously confirmed geometry mismatch among unmerged foredeck, short-cabin and geodesic-helm prototypes. The original #461 doorway and #482 glass source remain independently archived, not overwritten or silently reclassified.

Run only in an editor or QA harness: `res://scenes/aureate_wake_metric_bridge_study.tscn`. Script `res://scripts/aureate_wake_metric_bridge_study.gd`.

- **Common coordinates:** 1 Godot unit = 1 **provisional study metre**. Gross external cabin study beam **3.50 m**, cabin aft end **z = +6.0 m**, foredeck starts at **z = -2.60 m**, forward tip **z = -5.60 m**. The separately covered crew-cabin + helm envelope spans about 8.60 m, with an independent 3.00 m exposed forward deck. This is NOT the finalized hull, displacement/pressure vessel, or the old art scale mapped literally.
- **Geodesic helm:** dome radius **1.60 m** and diameter **3.20 m**, centered at **z = -1.20 m**, apex **y = 2.95 m**, inside the 3.50 m gross beam. Native larger triangular facets with actual diagonal bronze support members and translucent glass-like material are original *new metric proxies*, **not transferred final #482 shader/asset bytes**.
- **Physical walkway:** physically collidable separate cabin, helm, and bow floor modules in a *shared* scene. A **1.24 m nominal hatch clearance width** and **2.10 m nominal height**, real brass jamb/header colliders, **hinged real `StaticBody3D` door** with open, closed and reopened collision behavior. The forward dome has a **visible missing-pane wedge**, not an invisible sealed pane over the proposed exit.
- **Deck:** original simple open-air 3D deck (no roof). **1.05 m top rails** and vertical posts with actual collision. This is *not* a fully reviewed child-safe, climb-safe, drop-safe or accessible rail system; there are no tested infill panels, drainage/handholds, or verified mobility accommodations.
- **Crew usage:** simple navigation console at the starboard side and out-of-path cabin storage, retaining a centre walking route. This **does not** prove actual habitation for all five protagonists, Talen or guests.
- **No concealed machinery, no advanced traversal, no seaworthiness, no weather/pressure shielding and no autonomous engine system** are represented. Shell glazing has visual mesh only, no structural glass collision/protective integrity. Closing the door alone does **not** form a sealed environmental vessel.

## Acceptance tests for this incremental prototype

`godot/tests/aureate_wake_metric_bridge_physics_test.gd` loads the actual Godot 3D scene and uses:
1. Real `PhysicsDirectSpaceState3D.intersect_ray` on all three floors and both seams to show native colliders, rather than solely checking source meshes.
2. Real `PhysicsDirectSpaceState3D.cast_motion` of a **1.74 m tall / 0.26 m radius** capsule along a **7.60 m** physically continuous centerline route **in both directions**; checks full two-way passage while hatch open, blocking from either direction when closed, and renewed two-way passage upon reopening.
3. Render mesh, doorway, 1.05 m rails, dome/beam and 2.05 m minimum review headroom checks.
4. Existing native Chapter I **source-locked PR #503 production admission gate** stays `production_ready=false`, actual Ionia-first story/party/save stays unchanged and Resonance stays locked.

`godot/tests/capture_aureate_wake_metric_bridge.gd` records **three authentic 960×640 Godot Compatibility frames**: closely framed same-pose open and closed hatch, plus elevated full-hull view revealing cabin-to-deck continuity. A positive pixel difference is required. CI uses the digest-verified official Godot 4.7.2 Linux editor, software GL and uploads raw receipts. Linux software-render QA is NOT target Windows device/performance acceptance.

## Next production gates still blocked

- **Art/source:** replace the freshly authored proxy with licensed/creator-reviewed actual 3D mesh and the original study's better glass shader, source hashes, material A/B and independent glare/legibility QA.
- **Human fit and safety:** actual actors (not only a test capsule), walking controller/navigation including turning, player input, door interaction, handrails/infill and correct fall/egress hazard handling. Headroom at the portal perimeter, hinges and shell frame must be mapped in detail, not inferred only from dome apex.
- **Structure and climate:** glass frame collision, weather sealing and any environmental protection are separate physical engineering prototypes; simulated enclosed appearance **is not pressure/safety certification**.
- **Chapter I:** explicit scene transfer/review without giving additional plot access or changing the flyer→Ionia hiring→engineering→test-flight chronology. Re-run v2 checkpoint, combat authorization, accessibility and party tests before adding it to Chapter I.
- **Production:** visual creator signoff, representative actual device FPS/VRAM, installed Windows with intact Defender safety check, player acceptance, deliberately authorized merge and release.

Current state remains **G1/G2 PROTOTYPE RESEARCH**, not G3 gameplay integration or G5 release. Passing this prototype demonstrates only a native continuous physics corridor and a reviewable dimensioned candidate. The creator has not yet approved those dimensions.

## Real character walking and camera access test — 2026-10-28

**Next incremental development experiment, separate from the verified collision-only capsule test:**

- An *anonymous adult-sized* `CharacterBody3D` now lives inside the **isolated** metric ship scene. The actor has a 1.74m × 0.26m radius real `CapsuleShape3D`, physically resolves against the ship's floor/door/railing colliders, uses gravity and `move_and_slide()`. WASD/arrow keys move; E requests a hinged-hatch interaction **only within 1.28m** of the actual portal. This does not use real Ender/Ionia art or give a ship interaction ability to playable Chapter I.
- A native third-person review camera can follow the *actual moving body* and use a `PhysicsDirectSpaceState3D.intersect_ray` collision probe to shorten its camera arm before clipping an opaque hull. The separately tested **forward helm sightline** ray is clear through an open hatch but is blocked by the actual hatch collider when closed. No gameplay stealth, atmospheric or glass refraction semantics are inferred.
- `godot/tests/aureate_wake_crew_walk_test.gd` drives the actual `CharacterBody3D` over elapsed physics ticks instead of teleporting between zones: settle on real cabin floor → walk into helm → close hatch by proximity → attempt and reject through-hatch walk → reopen → walk onto open deck → strafe/turn inside rails → walk back to helm. It checks actual camera follow and collisions, unchanged Chapter I story/save/Resonance, and the unchanged fail-closed production admission manifest.
- `godot/tests/capture_aureate_wake_crew_walk.gd` captures **three real 960×640** Godot Compatibility images showing anonymous human-scale crew and physically operated hatch, plus walker successfully reaching the deck. A/B hatch visuals are checked for positive pixel changes. The scoped workflow runs all these *in addition to* inherited 30 physics-only and 3 render tests, then uploads per-head logs/screenshots.
- **Still not production accepted:** Source-identical detailed PR #482 glass shader/material was NOT imported. The currently faceted metric shell is original quick-study art, missing structural physical panels, proper aperture geometry and protective seals. Human capsule locomotion and camera tests do NOT certify a safe hull, actual crew occupancy, accessibility, naval/habitation engineering, collision from ship motion, weather shielding, gameplay Chapter I navigation, or Windows device performance.

**Acceptance boundary:** native run must be checked at the final exact commit before calling any walking proof verified. Success only advances G2 to an **isolated real-actor movement feasibility prototype**, never production ship access or Chapter I release. Next evaluate camera framing, shell/door art, safe foredeck infill and source-locked higher-fidelity glass in one joint review.
