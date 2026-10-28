# Forest study → Godot Chapter I: prototype-to-production admission gate

**Status: REVIEW-ONLY PROTOTYPE CONTRACT.** This is not the acceptance or integration of the visual assets, not a newly playable forest, not a globe implementation, and not a creator/canon approval.

## 1. Exact source lineage / ownership

- **Study source**: [forest flight-slice PR #488](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/488) at `5fac28c5dd5159d742ffb102db71f70a8224cb34`, stacked on PRs #484 → #473 → #463 → #457 → #405 → #404. Standalone `godot/flight_slice/` and native Compatibility evidence: [run 40611335217](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/actions/runs/40611335217). Its forest is a **planar noncanon flight study**.
- **Target**: [Godot Chapter I candidate PR #480](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/480) at `46e15dbd94cedf964fdc008dad8528d8140dcbb6`; it has a **separate** Godot project rooted at `godot/`, with scene-based 2D First Wake, actors, interactions, quests and save constraints. There is no proof that it includes or consumes the 3D forest study.
- **This experiment** adds only `godot/scripts/forest_visual_bridge.gd`, a standalone native `godot/tests/forest_visual_bridge_test.gd` and a Godot CI step, plus this documentation. No Chapter I scene references the bridge; it has no save, quest, collision, world map or story integration.
- Historical `main` is a JS/p5/NW.js content reference; per `AGENTS.md` the active forward target is Godot 4.7.2 GDScript. This draft is stacked on PR #480, not main, and is **unmerged**.

## 2. What transfers as a contract

| Study result | Transfer now | Verification boundary |
| --- | --- | --- |
| Deterministic anchor/instance identity | **Protocol candidate**: stable unique species-cell IDs and local tangent AABB bounds | Native Godot manifest validator; real terrain-sampled global transform not delivered |
| Near/far distance hysteresis | **Portable policy**: 29/39 local-unit study thresholds | Pure scene-independent Godot GDScript test; thresholds provisional, not globe units |
| At-most-one mesh change/update | **Portable policy** for normal detail | Test one-change budget and convergence. Rendering smoothness/latency still open |
| Low-quality emergency fallback | **Portable policy**: changes are immediate | Test forced fallback and no deferred high mesh |
| Source placement invariants | **Required integration gate**, not transferred geometry | Must prove one-to-one instance conservation against the true production terrain sampler |
| Terrain-integrated moss / shrubs / species meshes | **Keep in art lab** | No accepted source texture, target-GPU proof, biome/lore placement or creator art signoff |
| Fixed-pose A/B screenshots and JSON receipts | **Reuse evidence schema** | Test native engine + exact commit + same viewport/scene/clock, then moving-camera and target Windows GPU |
| World sphere, polar biomes, aurora/moon, ship modes | **Out of scope** | Need world-space geodesy/streaming/altitude contract; do not infer from planar study |

## 3. Actual prototype-to-production test

Run from the standalone Chapter I candidate branch (after Godot 4.7.2 editor import):

```sh
Godot_v4.7.2-stable_linux.x86_64 --headless --editor --path godot --quit
Godot_v4.7.2-stable_linux.x86_64 --headless --path godot --script res://tests/forest_visual_bridge_test.gd
```

Expected exact receipt: `FOREST_CH1_BRIDGE_PASS`. The test exercises the portable local-space policy, one-switch update, deterministic state, low-quality fallback and **fail-closed** canon/collision/navigation/save/space boundaries. It does not render a new forest or demonstrate actual player camera behavior.

## 4. Next, gated *playable* handoff — still pending

1. Select a noncanonical **test location** attached to a currently existing playable Godot scene, only after tracing the authoritative terrain/collision/foot anchors; do not invent a canon forest settlement.
2. Define a production `WorldSurfaceId / LocalTangentFrame / chunk bounds / height-query / biome-mask` adapter and stable instance IDs. Globe curvature, horizon handling, origin rebasing and pole seams must be defined independently from this planar study.
3. Admit **one reversible, opt-in terrain-bound vegetation patch** (with a toggled baseline) and ensure the playable character, quest, collision/landing, save and traversal state are bit-for-bit unchanged on enable/disable.
4. Test at a readable scene/camera scale: 960×640 native captures in near/medium/far views, daytime/night/rain/fog and reduced motion/low quality. Compare silhouette, actor/quest readability, LOD popping, shadow stability and overdraw. Use reference art approved by the creator.
5. Measure CPU draw preparation, Godot render statistics, GPU time, frame pacing and VRAM on **target Windows hardware**, at fixed run conditions. Set concrete budget after baseline measurement; software-rendered CI wall times are **not** a GPU FPS claim.
6. Record a new **visual approval** and independent **player acceptance** only after real play. Keep any production renderer merge / planet propagation / release behind explicit creative and authorization gates.

## 5. Documentation reconciliation checklist

- `godot/flight_slice/README.md`: native study and exact PR #488 details; **retain on its isolated branch**, not as accepted game documentation.
- `godot/README.md` and this page: record isolated portable Chapter I contract, exact branch/commit, test outcome and no runtime wiring.
- `docs/GODOT_MIGRATION_COORDINATION.md` (main when reconciled): append the divergent flight-study/Chapter I lineage; do not overwrite dated SHAs.
- `docs/VISUAL_BIBLE.md` and `docs/VISUAL_BENCHMARK_SCENE.md`: keep approved artistic direction; add only candidate-review/test matrices, do not mark forest art accepted.
- Notion **Cinematic Planetary Visual Fidelity & Godot Prototype** and **Consolidated Development & Cinematic Visuals Ledger**: append exact evidence, new gate and pending target-GPU/creator/Windows status.
- Notion **Documentation Authority & Reconciliation** / **Worldbuilding Productionization Readiness Matrix**: add a cross-track authority note and mark `SOURCE-CONTRACT-PROTOTYPE`, not `INTEGRATED`.
- Chapter I acceptance documents: only update if opt-in vegetation actually touches a playable scene; no Chapter I or save acceptance is inherited from this proof.

## 2026-10-27 source-specific native admission receipt

Initial implementation commit `54122a4e9f44ba8fc880c1cb65e4a55c8c6c5fde` has **executed** in the Chapter I Godot 4.7.2 native pilot: [workflow 40615514993](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/actions/runs/40615514993) **SUCCESS**, with explicit `FOREST_CH1_BRIDGE_PASS`. [Repository smoke 40615514956](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/actions/runs/40615514956) **SUCCESS**, and [native Ionia render review 40615514619](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/actions/runs/40615514619) **SUCCESS** at that same code commit. This proves **portability of a pure GDScript policy contract only**, not scene integration or visual acceptance.

Separate [Godot Exact Windows QA 40615514378](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/actions/runs/40615514378) is **NOT PASSED**: Windows preflight refused `WINDOWS_QA_HOST_DEFENDER_REALTIME_DISABLED` (antivirus service enabled, real-time protection not enabled). A sibling Windows job succeeded, but does not supersede this fail-closed custody blocker. **Do not bypass, weaken or describe Windows release authorization as cleared.** A new documentation commit requires its own exact-head verification.

**Current gate decisions**: `SOURCE_BRIDGE=DRAFT`; `PORTABLE_POLICY_TEST=PASS_AT_54122a4e`; `SCENE_WIRING=NONE`; `PLANET_INTEGRATION=NONE`; `ART_ACCEPTANCE=PENDING`; `GPU_PERFORMANCE=UNVERIFIED`; `WINDOWS_SECURITY_PREFLIGHT=BLOCKED`; `CREATOR_ACCEPTANCE=PENDING`; `RELEASE=HOLD`.
