# First Wake — bounded water-contact/float review (2026-10-27)

**Status:** DRAFT / REVIEW-ONLY native Godot 4.7.2 scene. **No merge, canon promotion, player acceptance, or released build.**
**Ancestor:** [PR #430](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/430) source `19f2b9b2dd4cdf5ffec464fe91a46731e3a627b7`, itself stacked on Ionia-first [PR #426](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/426). Creator-directed chronology in [story PR #425](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/425).

## Verified-by-source design boundary

The established, existing **flyer → paid hiring of Ionia → boarding → engineering three-inspection checklist** remains unchanged. The new separate `first_wake_flight_water_review.tscn` is entered **only by pressing the named/remappable F launch-review action after preflight**. Existing E interaction remains deliberately blocked after preflight so old tests and normal opening behavior retain their explicit boundary.

The local flight proof requires:
1. `active_party_ids == ["ender", "ionia"]` and `step_key == "preflight"`; Lyra absent; Ionia already recruited.
2. A short physically moving `RigidBody2D` test-flight ascends, then presents an authored phase/containment/fuel warning at a bounded timer. **These are screenplay observations, not simulated engine-chemistry equations.**
3. Press E to initiate Ionia's controlled ocean descent; the revised story contract records the phase/containment/fuel failure only then.
4. The ship reaches a real native `Area2D.body_entered` signal with a matching ship physics body.
5. A local submerged-depth buoyancy force raises/stabilizes the hull. Only sustained stable waterline and low vertical speed for at least 0.45 seconds permit `complete_ocean_splashdown(true, true)`.
6. Scene reports `phase=waterborne` and `story_step=waterborne`; no premature Lyra join, postflight diagnosis, Talen arrival, or definitive fuel explanation.

The new scene is intentionally **synthetic local 2D physics, not the globe's physical ocean, true ship hydrostatics, player-controlled continuous flight, or the cinematic Aureate Wake asset**. The physical contact and temporary flotation must be validated in real Godot execution and a captured frame. `production_ocean_verified=false` intentionally remains part of the snapshot even if this bounded contact test passes.

## Art and gameplay review

- Uses temporary geometry. Review visuals are not admitted final art.
- No geography/destination/recovery mechanism implied by the sky/ocean backdrop.
- Keyboard/controller mappings retain user rebinds; F launches this isolated stage; E starts the flight then chooses the safe controlled descent.
- The live Chapter I legacy Lyra-first FSM, Wind Shear battle authority, magic jobs, existing save schema, worldmap and current planetary physics remain untouched.
- `first_wake_flight_water_review_test.gd` tests preflight rejection, Ionia-first identity, real 2D water sensing, sustained stabilization, invalid premature input, and no Lyra/fuel-canon leakage.

## Quality gates

- [ ] Exact-head Godot 4.7.2 native import and 2D physics test PASS, alongside the earlier Chapter I and #430 scene regressions.
- [ ] Actual 960×640 Godot capture and human visual review: ship visibility, waterline, UI overlap, captions and motion safety.
- [ ] Verify input usability, sound and reduced motion; this experimental scene is not the ultimate experience.
- [ ] Link or implement the full cinematic flight and ocean recovery using correct terrain/water/ship-source authority before promotion.
- [ ] Author postflight empty-reserve inspection, safe Lyra/Talen reunion, and collaborative working-theory investigation as separate gated increments.
- [ ] Independent Windows Defender/installer security gate remains unresolved; no release authorization.

**Scope-control principle:** A successful native RigidBody2D+Area2D buoyancy test may be reported as **LOCAL 2D SPLASHDOWN PHYSICS PASS**, not as production sea travel, realistic planetary hydrodynamics or Chapter I acceptance.
