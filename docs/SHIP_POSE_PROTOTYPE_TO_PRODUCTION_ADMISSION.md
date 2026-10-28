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

## 4.2. Stage B0 actual 3D mesh in the real Chapter I scene — bounded preview

The follow-up [native Chapter I original-wing review draft #523](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/523) imports the exact standalone [#490](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/490) 3D ship art script, pinned source blob `b21327071e2120fd75113d6051af17dd2c45dbfd`, into an **independent Godot SubViewport** after the existing Ionia-first engineer-stage **QA opt-in**. This is the first **real rig** receiving the ordinary wing pose in a genuine Chapter I frame; it is not the physical in-world ship, a player-facing camera, a flight controller or a collision-certified asset.

First exact-head [Godot CI #40624681728](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/actions/runs/40624681728) **PASS** at source `3149f6458c3abe905e3f62e87916b0805526be9b`: 43 native scene/rig checks, inherited 38 + 32 scene contracts, three genuine 960×640 screenshots of no inset, neutral 3D model and swept model. Sampled image changes: 9,017 cells for appearance; 586 for the 15° wing movement. The ship appeared too small for a satisfactory art-review inset, so the revised [#523 head](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/523) tightens its study camera and requires four real screenshots (no inset/neutral/midpoint/full sweep); **that revision must be verified separately**, and this historical PASS does not apply to newer bytes.

**Stage B0 scope and stops:** test-only viewport in a real chapter scene, no new player key, default no 3D resource in memory, no chapter/save/collider mutations. Physical clearance, shared metre scale, dome and deck, full motion/cinematography, Windows target GPU and art approval are all **OPEN/BLOCKED**. The independent bridge [#482](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/482) reports, under its provisional 2.5 metres/art-unit assumption, a 3.80 m dome vs 2.35 m proposed entry width and 1.825 m summit clearance vs 2.05 m review target. These are conflicting *study hypotheses*; they must not be silently harmonized by changing mesh scale or lowering safety requirements.

**Next physical gate:** select one creator-accepted internal metre reference; reconcile external hull, foredeck, geodesic dome, working hatch/threshold, three masts, four swept-wing roots and actor occupancy in a **single Godot 3D scene**, with on-screen collision/occlusion tests and safe boarding. Only then move the visual component from an overlay viewport into the playable world.

**Stage B0 revised exact-head closure:** [Draft #523](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/523) source head `0bc89c83c0fc82c7286fa806cbf2f84d795fbd73` has [Godot 4.7.2 native #40625102042](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/actions/runs/40625102042) **SUCCESS**, with 43 actual 3D Chapter I rig tests, inherited 38 pose-port and 32 ship-space checks. Four genuine 960×640 captures (original chapter/no inset, neutral 3D wings, midpoint, 15° sweep) confirm visible changes, with 9,015 sampled changed pixels to expose renderer, 954 for first-half wing motion and 1,006 for second-half. Inherited Chapter I pilot, Ionia render, ship-space, pose port and smoke also completed SUCCESS at that exact head. [Raw four-frame artifact](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/actions/runs/40625102042/artifacts/12789370952) available while retained. The QA viewport occludes some engineering props, so it is **not an acceptable always-on production HUD**.

The separate [Windows QA #40625101984](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/actions/runs/40625101984) **FAILED host Defender custody preflight**; independent Windows functional-prerequisites job SUCCESS cannot override this boundary. Keep Windows security and GPU acceptance blocked without weakening preflight. Native visual + story contract success does **not** authorize merge or production use.

## 4.3. Stage B1 actual original ship-space source reconciliation (2026-10-28 candidate)

The next [draft #541](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/541) stacks on the exact previous native 3D wing review #523 head and brings the **original, byte-identical** geodesic bridge, open foredeck, glazing shader and 10.4×3.8×2.6m independent interior layout into the real Chapter I `SubViewport` *only under test opt-in*. It does not move the model into the physical Chapter I game world. [Scope, source fingerprints and test protocol](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/blob/prototype/ch1-ship-geometry-cross-study-20261028/docs/AUREATE_WAKE_SHARED_HULL_GEOMETRY_GATE_2026-10-28.md).

Under the explicitly **unapproved** 2.5 metres/art-unit onboarding hypothesis, original hull skin loft maximum exterior beam = **3.40 m**, yet separately authored cutaway has **3.80 m** interior beam (0.40m contradiction). Separately, 3.80m geodesic dome vs 2.35m crew threshold (1.45m overhang) and 1.825m dome summit height above the open deck vs 2.05m review minimum (0.225m shortfall) remain **physically incompatible**. Their plan projection near-connects by 0.075m but has no real contiguous door aperture. These are source-reconciliation findings, not settled story canon, an approved new scale or a certified human-safe vessel.

A new fail-closed contract samples actual 0/25/50/75/100% wing meshes against transformed deck/rail/dome mesh **AABB** volumes. Even zero reported AABB overlap cannot certify continuous triangle sweep or passenger clearance. The correct technical verdict is `BLOCKED_ON_HULL_SCALE_EGRESS_AND_SWEPT_VOLUME` until metre-normalized geometry, a truly shared collision scene, physical door and occupied crew capsules exist. Source-blobs were read back and match originals. **Native CI and four-composite screenshots were pending when this addendum was authored; no PASS implied.**

No one may solve this by simply shrinking the crew cabin, rescaling whole sources without a signed-off consistent coordinate transform, relaxing minimum egress, or converting the opt-in overlay into a player control. Retain all Windows/security, creator signoff and merge/release holds.

### Stage B1 source-specific native clearance triage — exact-head closeout

The refined [draft #541](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/541) code head `df8d4ab69f800f71d8462741a2d3c84adb11683b` passed [Godot 4.7.2 native #40631427844](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/actions/runs/40631427844): **40 purpose-built clearance checks**, inherited 43 actual-3D, 38 pose-port, 32 ship-space, and four authentic composited Chapter I GL frames, with preserved story/save state. Same-head native First Wake pilot, Ionia render, original-wing capture and smoke also completed SUCCESS.

The collision **broad-phase** classification now pinpoints the bottleneck: **190 AABB-overlap pairs were all with the geodesic helm study**, zero with the foredeck under these exact original source placements. The original four wing groups accounted for 47 port-fore, 48 port-aft, 47 starboard-fore and 48 starboard-aft pairs, across five poses (28, 36, 42, 42, 42). The even distribution implicates shared dome/wing root layout rather than a one-sided mesh oversight. **This does not establish 190 true triangle penetrations**. AABBs are broad-phase conservatism; a narrow-phase or actual actor/door physics test and signed-off coordinate frame remain necessary before any safety claim.

The documentation action is to prioritize **dome/wing attachment spatial reconciliation** after creator-approved metre-based hull and crew circulation requirements, without rescaling the ship to hide the 3.40m exterior vs 3.80m separate interior conflict. The exposed deck must remain accessible under ordinary safe conditions. Do not move this staged 3D viewport into a production player scene or infer any hidden ship configuration from the ordinary rig.

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
