# Aureate Wake — Ship-Pose Prototype → Production Admission Contract

**2026-10-27 | PUBLIC-SAFE HANDOFF | DOCUMENTATION CANDIDATE | NO GAMEPLAY ADMISSION**

This plan connects the validated, **noncanonical** 3D neutral wing rig to the **forward-development Godot Chapter I** pipeline without merging incompatible branches, changing plot timing, importing provisional dimensions, or claiming a playable ship transformation.

## 1. Exact source boundaries, not a false merged baseline

| Track | Review source pinned when planned | Verified meaning | Production limit |
| --- | --- | --- | --- |
| Neutral wing hinge study | [#478](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/478), `004407f26e897ef80b4d419f72ac7b6638de1c52` | Four existing membrane pivots, 51 native checks, two genuine 960×640 GL captures | Geometry/collision/art not accepted |
| Wing-pose/event timeline | [#490](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/490), `7abee4f14971868f52626d032d238c7140e0c457` | 45 native integration checks; interruptible 1.8s visual review alongside weather; [native run](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/actions/runs/40612183111) and [smoke](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/actions/runs/40612183093) PASS | Opt-in standalone flight study, no Chapter I player-facing behavior |
| Native Chapter I ship space | [#497](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/497), `d341d367c005b3c00d758336982d0e34d5e95839` | Real Ionia-first flyer/hiring/boarding/engineering scene, hidden read-only ship-space preview, v2 checkpoint stability; [native QA](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/actions/runs/40613875428) | 2D schematic only; no 3D wing rig or playable vessel flight |
| Physical foredeck/boarding | [#452](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/452), [#461](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/461) | Separate public-safe physical study | Independent scale, access and swept-wing clearance not reconciled |
| Observatory glazing and egress | [#482](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/482) | Fail-closed dome/entry scale contract | Provisional 3.80 m dome versus 2.35 m entry; 1.825 m height versus 2.05 m standing review target — **blocked**, not certified dimensions |
| Historical playable baseline | `main` | Legacy JavaScript game and source history | Do not implement new JS gameplay; Godot 4.7.2/GDScript is forward-development target |

All listed PRs were draft/unmerged when inspected. Re-fetch exact heads before any integration. A successful isolated CI run is not a production game integration receipt.

## 2. Minimum end-to-end prototype-to-production gate (AW-VISUAL-POSE-01)

**Demonstrator:** a *familiar*, ordinary weather-response / preflight wing adjustment, first in a test-only adapter and later as a real 3D ship visual. This is not a new skill, ship mode, flight grant, dramatic story clue, or secret traversal demonstration.

**Stage A — Scene-to-presentation handshake (first candidate to build):**

- Instantiate the actual `godot/scenes/first_wake_job_preview.tscn` from the approved native Chapter I branch, not a mock of Chapter I.
- Follow its real **job flyer → meeting/hiring Ionia → gangway → engineering** order. Use only existing script methods to reach the legitimate review stage.
- A separate opt-in `ShipVisualPosePort` receives a bounded, neutral visual cue (e.g., idle / small review sweep); a pluggable sink receives a **presentation request only**. It must return a no-op/rejection if the sink is absent, the player has not boarded, the story stage is wrong, the 3D rig is absent or the cue is invalid.
- Verify that 2D Chapter I can run perfectly without the visual sink. Do **not** add runtime input shortcuts, new save keys, route fields, hidden modes, crew-energy requirements or event text describing future capabilities.
- Assert actor position and bounds, active party, dialogue, objectives, checkpoint bytes, input actions, existing combat locks and physics permission are unchanged by a cue or rejection.
- For **preflight visual review**, require test opt-in. Do not automatically tie ship pose to story choices until the physical ship scene and storyboard are creator-approved.

**Stage B — Scene-linked rig/adaptation (requires an accepted 3D ship scene):**

- Port the generic `wing_pose_pipeline.gd` API or a compatible pure-GDScript interface into the *actual* ship presentation layer; explicit sink injection, no `get_node` dependency across independent scene roots.
- Four existing wing roots must remain stable and reversible with neutral, intermediate and mild weather-fold poses; pause, reset, reduced-motion snap and interrupted requests preserve continuity.
- The flight controller and landing/collision gate remain authoritative; visual pose requests never mutate velocity, transform, touchdown support or cabin access state.
- Add deterministic native matched-camera frames **and continuous motion capture** during real weather change; inspect alpha-sorted membranes, fore/aft symmetry, hard hinge penetration, camera readability and ship-scale silhouette.

**Stage C — Human-scale spatial integration (currently blocked):**

- Reconcile a **single meter-based** hull, geodesic bridge, doorway, foredeck, rails, standing space and cabin occupancy with the creator before modeling safety claims.
- Integrate #452/#461 and bridge-scale work **by explicit review**, not cherry-picking incompatible scene roots.
- Validate real swept-volume clearance for four wing meshes vs cabin/glass/masts/railings and the entire foredeck with a standard actor collider; no swept motion while persons occupy an unsafe volume.
- Verify guarded entry/exit and boarding state with actual Godot physics. Provisional deck rail-height and dome clearance work does not count as human-safe certification.

**Stage D — Target-platform and production admission:**

- Run exact-head Chapter I scene contracts, real gameplay inputs, screenshot/video, reduced motion, save/load round trip and reset/recovery with the integrated scene.
- Run exact native Godot 4.7.2 parser, GL Compatibility fallback, real Windows Forward+ GPU frame-time / frame-pacing / VRAM / shader-compilation and stress tests.
- Confirm deterministic regression and failure outputs; capture provenance manifests, branch head, frame comparison, scenario steps and source-art licenses.
- Require distinct creator reviews for ship aesthetics, Chapter I storytelling, playability, visual accessibility, performance, merge and release.

## 3. Safe interface and fail-closed requirements

Proposed public-safe interface (not yet production implementation):

```text
ShipVisualPosePort.request_visual_cue(context, cue, optional_sink)
  context: verified scene identity, opt-in status and current public-safe stage
  cue: a bounded ordinary appearance-only pose token
  sink: explicit renderer adapter implementing apply/advance/recover
  result: accepted/rejected with safe reason; never saves or rewrites story state
```

A renderer-independent contract is preferable to importing the entire `godot/flight_slice` scene into Chapter I. The existing [ship-space intake study](FIRST_WAKE_SHIP_SPACES_PIPELINE_PROTOTYPE_2026-10-27.md) provides precedent: opt-in only, actual Chapter I story chronology, and byte-identical checkpoint.

Test the negative cases: missing sink; invalid/NaN values; premature request; false party/stage; interruption during environmental crossfade; pause; reduced motion; restore after save/load; ship not loaded; unsafe swept volume; boarding and landing while transition is active. Fail closed and preserve game progress.

## 4. Documentation and source-of-truth routing

- **Engineering authority:** this plan and [migration coordination](GODOT_MIGRATION_COORDINATION.md). Source + exact-head CI decide what is implemented.
- **Ship shape / visual quality:** [world/ship direction](WORLD_SHIP_VISUAL_DIRECTION.md), [visual benchmark](VISUAL_BENCHMARK_SCENE.md), [cinematic contract](CINEMATIC_CLIP_CONTRACT.md). Art approval is independent of unit tests.
- **Story / public disclosure:** [canon & reveal policy](CANON_AND_REVEAL_POLICY.md); creator-controlled Notion holds restricted mechanics. No future reveal names, triggers, celestial destinations, pictures or route logic in public PRs, screenshots, tests or comments.
- **Chapter I chronology:** later creator direction and the Ionia-first native job preview supersede *forward-story assumptions* from older runtime documentation. Do not rewrite history: older JS baseline behavior must be labeled historical if it differs.
- **Operational logs:** public PR/CI links for engineering proofs and scoped private Notion development ledger for design rationale. Avoid blindly copying full private pages to GitHub.

## 4.1. Stage A implementation candidate and verification receipt (2026-10-27)

[Draft #507](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/507) is a **separate** native Chapter I stack on #497 at `d341d367c005b3c00d758336982d0e34d5e95839`, candidate head `98bf760685b880b5bfef94ce66915636e7231592`. It ports the source-identical neutral pose timeline from #490 into `godot/scripts`, adds a stage-gated `first_wake_ship_visual_pose_port.gd` and strictly test-only methods in the existing Ionia-first scene. A native test follows the real flyer/hiring/gangway progression and drives a **mock Node3D presentation sink**, not a physical 3D airship.

[Exact-head native workflow #40615917375](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/actions/runs/40615917375) **SUCCESS**: `FIRST_WAKE_SHIP_POSE_PORT_PASS checks=38 scene=REAL_NATIVE render=TEST_SINK_ONLY production=HOLD`; inherited `FIRST_WAKE_SHIP_SPACE_HANDOFF_PASS checks=32`; real job preview and v2 checkpoint regressions passed. [Repository smoke #40615917424](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/actions/runs/40615917424) **SUCCESS**. No player input, save key, progression override, 3D art admission, flight control or hidden mechanic is added.

**Interpretation:** Stage A contract is native-tested in a draft; **production Chapter I moving-wing visuals, boarded-safety, accepted scale, target GPU, creator acceptance and merge remain open.** Recheck PR heads / additional workflows before promotion.

**Security gate classification:** on the same Chapter I #507 exact head, [Windows QA #40615917385](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/actions/runs/40615917385) **FAILED BEFORE WINDOWS APPLICATION ADMISSION**. The hosted runner preflight reported `DEFENDER_ANTIVIRUS_ENABLED=False`, `DEFENDER_REALTIME_ENABLED=False`, and stopped at `WINDOWS_QA_HOST_DEFENDER_ANTIVIRUS_DISABLED`; the separate Windows functional-prerequisites job passed. Treat as <b>host security prerequisite failure</b>, not a demonstrated pose-adapter, art, or Windows-installer test failure/success. Do not relax the security control or claim hardware readiness.

## 5. Release and decision register

| Gate | Current status |
| --- | --- |
| Neutral hinge prototype | NATIVE TESTED — draft/unmerged |
| Pure Godot visual pose controller | NATIVE TESTED — draft/unmerged |
| Real Chapter I ship-space schematic | NATIVE TESTED — draft/unmerged |
| Chapter I → pose-adapter handshake | **DRAFT-IMPLEMENTED / NATIVE TESTED in PR #507; unmerged, renderer is a test double** |
| 3D ship / foredeck / dome / hatch integrated scene | **BLOCKED ON SCALE & COLLISION RECONCILIATION** |
| Full moving-camera art acceptance | OPEN |
| Target Windows GPU | OPEN |
| Player-facing Chapter I gameplay and saves | NO PRODUCTION ADMISSION |
| Creator visual/canon review | OPEN |
| Merge / public release | HOLD |

**Next action:** inspect the native test-only Stage A candidate in PR #507 and its separate inherited CI; then proceed to physical scene, camera/boarding and GPU verification only after unified metre-scale hull acceptance. No documentation or test-only stub is production admission.
