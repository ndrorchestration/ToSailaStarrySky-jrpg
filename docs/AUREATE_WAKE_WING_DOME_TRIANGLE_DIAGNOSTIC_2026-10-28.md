# Aureate Wake — Wing Membrane / Geodesic Pane Triangle Probe

**2026-10-28 | Stage B1.1 | PUBLIC-SAFE NONCANON GEOMETRY DIAGNOSTIC | PHYSICAL ADMISSION BLOCKED**

## Provenance and question

The source-original [#541 shared geometry pilot](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/541) reports **190 wing-component / geodesic-helm AABB overlaps** over five poses at 0%, 25%, 50%, 75%, 100% of an existing mild 15° appearance sweep. All originally classified overlap pairs are geodesic helm; **none** is yet a demonstrated physical triangle intersection or passenger hazard.

This follow-up retains the exact original 3D wing and geodesic mesh source, the real Ionia-first Godot Chapter I review scene, existing QA opt-in and progression boundaries. It adds no geometry to production and changes no lore, player controls or saves.

## Method and deliberately limited scope

- Source: original wing `Membrane_PortFore/PortAft/StarboardFore/StarboardAft` triangle surfaces versus original `GeodesicGlass` triangle surface; no rods, braces, balcony, railing, door, underside/skin, cabin occupancy, rotating mechanism volume or closed pressure geometry.
- Transforms: compute mesh triangle vertices into the common original ship-local study-art-unit frame, including the four rotating hinge transforms and the bridge's original proposal offset.
- Broad triangle gate: overlapping triangle AABBs (with small tolerance); **narrow triangle gate**: SAT projections onto two face normals, triangle-edge cross pairs and coplanar in-plane separating axes. Degenerate surfaces are ignored; their exclusion is *not* a proof of clearance.
- Compare at the same **five discrete wing poses** already in PR #541 and restore every original wing pose afterward, including a previously half-swept orientation.
- Regression: known intersecting noncoplanar, intersecting coplanar, disjoint coplanar, separated parallel and malformed triangles; use the *real* Chapter I flyer → Ionia hiring → gangway sequence before the actual review mesh is instantiated. Confirm real party/story/v2 save invariants, no Resonance permission, no leaked 3D preview after opt-out.
- Bound work to four million triangle candidate tests. Incomplete, malformed, absent geometry, impossible budget or parser errors **must fail closed**, never report a certified clear hull.

## How to interpret output

`FIRST_WAKE_TRIANGLE_PROBE_REPORT` captures glass and wing membrane triangle counts, per-pose and per-original-wing SAT contact counts, triangle-box candidate count, test count, budget status and explicit unit/method tags.

A **positive SAT contact** is evidence of triangles touching/overlapping under the sampled assumed art layout, subject to implementation tolerance and triangulation errors. A **zero SAT contact** is *not* a safe wing: other wing parts, player body volumes, unmodeled mechanisms and **continuous** motion between samples remain unverified. The operating environment, full physical world-scale, pressure ratings and true door/helm collision shapes are unresolved. The protocol never sets `physical_integration_ready=true` and always reports `NOT_CERTIFIED`.

The 3.40 m outside vs 3.80 m interior beam, 3.80 m dome vs 2.35 m proposed threshold and 1.825 m proposed summit vs 2.05 m review target conflicts from #541 remain separate blockers based on **unapproved 2.5m/art-unit assumptions**. The true final ship metre dimensions must be authored and approved as one coherent whole, not inferred from this scan.

## Verification and admission

The test is `godot/tests/first_wake_wing_dome_triangle_probe_test.gd`, backed by `godot/scripts/ship_wing_dome_triangle_probe.gd`; its exact-head native Godot 4.7.2 workflow is `.github/workflows/godot-first-wake-cross-study.yml`. All inherited original Chapter I story/ship geometry contracts and four real screenshots must continue passing.

**Native execution receipt (exact code head `74f35eb29b2f596289137d40ea13ede9ed65f4a2`):** [Godot 4.7.2 run #40632616570](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/actions/runs/40632616570) **SUCCESS**. The actual original geodesic glass supplied **70 triangles**; the four original wing membranes supplied **360 triangle observations across five poses**. The scan compared **1,094 triangle-AABB candidates** with the exact reported `DISCRETE_TRIANGLE_SAT_WITH_COPLANAR_AXES` method and returned **0 membrane/glass SAT contacts** across all five poses and all four wings, budget not exhausted. `FIRST_WAKE_TRIANGLE_PROBE_PASS checks=25`; inherited geometry 40, original 3D 43, pose port 38 and ship space 32 all PASS, as did the four original scene screenshot contract.

**Interpretation:** The previous 190 **mesh-bounding-box** overlap pairs cannot be attributed to a detected collision *between wing membranes and glass pane triangles* at these five discrete frames. It is **not** proof that geodesic frame/collar, wing ribs or physical wing roots clear, and not a continuous motion, actor or egress certificate. This distinction is central: do not convert a limited negative into a broader safety PASS. The first attempt [#40632532878](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/actions/runs/40632532878) failed on a reserved-name test-harness parse error, corrected before the successful run.

**Current physical verdict: BLOCKED.** The source geometry and provisional metre contradictions are unchanged. A later documentation-only commit does not add new source-code validation.

### Next production tests

(1) Test the bridge collar, frame and **all structural wing ribs**, not just membrane against glass; (2) continuously sweep temporal wing positions with collision geometry and occupant exclusion volumes; (3) reconcile one shared metre-based external hull, foredeck, geodesic glass bridge and accessible hatch; (4) native 3D boarding/camera/gameplay and Windows GPU/security verification. All remain **OPEN**.
