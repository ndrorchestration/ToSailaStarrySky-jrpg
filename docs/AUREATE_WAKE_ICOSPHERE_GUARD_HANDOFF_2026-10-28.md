# Aureate Wake — original icosphere topology, metric hatch and bow infill

**October 28, 2026 | Native Godot 4.7.2 study | DRAFT / NO MAIN GAMEPLAY ADMISSION**

## Scope / provenance

This draft follows [PR #540](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/540) (verified, source-identical PR #482 shader) and the real walking-controller [PR #531](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/531). It replaces only the later *latitude-ring metric dome proxy* with a parameterized normalized **icosphere topology adapted from the earlier [PR #471](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/471)** source exact head `6a1f21258900027156251aa63107371ab29da7b9`. The source algorithm is adapted, **not copied as original asset bytes**. The actual original glass spatial shader remains the separately exact-byte-imported PR #482 shader, source hash-pinned at PR #540.

The new `godot/scripts/aureate_wake_icosphere_metric_topology.gd` builds a two-subdivision triangle sphere, clips it to the existing **provisional** 3.20m-diameter dome and 0.45m collar height, then removes real triangle geometry through the **forward** human hatch window, leaving a visual opening with an actual clipped perimeter. Interior capsule movement and the door's `StaticBody3D` collision remain separate, unchanged, and are not evidence of structural glass/certified seal.

The metric hull, crew cabin and open-air foredeck still share the *proposed study* beam 3.50m, 1.24×2.10m hatch nominal clearance, apex y 2.95m and 1.05m railing height. All are **author-unapproved candidate dimensions**, not locked canon.

## Meaningful physical safety-in-game test

Top rails and posts alone did not physically obstruct small gaps at chest/knee height. The updated ordinary open deck adds **5 collidable guard rungs** on each side **and the forward nose**, spaced 0.18m vertically from the deck. These are collision-geometry prototype infills, not engineering-compliant ship rails, child-safety certification, Talen-safe design, weather barriers or accessibility certification.

`godot/tests/aureate_wake_icosphere_guard_test.gd` is a real native Godot physics test. It checks:
1. mesh source provenance/triangle topology, compiled triangles, metric bounds, visual cutout on the actual pane geometry and frame mesh, deterministic source-derived construction;
2. all 15 rail-infill `StaticBody3D` colliders, vertical station rays against port/starboard/nose rungs;
3. real moving 1.74m `CharacterBody3D`: from actual cabin to guarded deck; sustained lateral movement meets rail collision instead of leaving deck; return to centre; sustained forward motion meets bow collision. No teleports or synthetic path descriptions;
4. new geometry leaves real Ionia-first Chapter I startup, save state and Resonance permissions unchanged.

`godot/tests/capture_aureate_wake_icosphere_guards.gd` captures **three real 960×640 Godot Compatibility** frames: adapted original-icosphere clear source shader, low-glare profile on identical geometry, and a forward viewpoint of fully collidable bow infill. It checks visible low-glare A/B difference. The scoped CI workflow uses the **digest-pinned official Godot 4.7.2** editor, native import/physics and real software-render screenshots. Inherited #512, #531 and #540 tests remain in their separate workflows, including true adult capsule open/closed/open, walker and exact shader SHA checks.

## Production boundary and unresolved deficiencies

- **Engineering:** these rail rungs do **not** prove real maritime guardrails, Talen-safe climb prevention, weather/impact forces, ship yaw, fall safety, accessible turning envelopes, anti-ghost collision or any operating ship design. A frame mesh can still intersect door trim; detail/clearance/stress/failure tests need independent review.
- **Art:** source-**derived** icosphere may be more faithful than the latitude-ring proxy but still remains programmatic preview art, not the author's final designed geodesic dome/helm. PR #482's source-identical **shader** is integrated, not the original **mesh**. Real ship interior quality, decorative detailing, seats, navigation sightlines, crew occupancy and cinematic lights remain to design.
- **Scene authority:** actual playable First Wake only has the independent opt-in 2D review. New 3D shell, physical infill and anonymous walker are in a separate Godot scene. They do not set quest flags, canonical dialogue, magic/resonance or reveal any hidden vessel functions.
- **Release:** Windows Defender hosted-runner prerequisite and final player/device acceptance remain on hold. No PR merges, canon locking, environment safety certification or deployment permitted.

**Production gate classification:** geometric/physics **G2 prototype test candidate**; G2 creator/hull approval and G3 Chapter I live 3D ship integration remain **BLOCKED** until independently verified. Native CI evidence is needed before marking this draft physically verified.
