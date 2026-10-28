# Native Aureate Wake wing-pose / flight integration seam v0.1

**PUBLIC-SAFE WORKING STUDY. NO MERGE, CANON, GAMEPLAY, OR RELEASE AUTHORITY.**

## What the integration test proves

The new neutral four-wing hinge geometry from stacked [PR #478](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/478) becomes a usable **Godot 4.7.2 GDScript presentation interface**, not a separate manual art slider. This dedicated follow-up uses `wing_pose_pipeline.gd` as an **opt-in** review controller, with no player inputs or gameplay data.

`request_pose(target: float, seconds: float=1.8)` accepts a bounded fraction `[0,1]`; `advance(ship, delta, reduced_motion)` applies its eased progress to the existing four real hinge pivots.

### Required native evidence

- Full existing ship + terrain + weather/magic + native flight/touchdown scene still constructs and runs.
- 1.8-second wing-pose review window advances alongside the independent 1.8-second environment crossfade; neither one controls the other.
- Mid-transition requests reverse from their present pose, with no instantaneous snap.
- Invalid input (NaN/duration <=0), missing ship and zero-delta pause behave predictably, with no state advance on rejection.
- Reduced-motion request resolves to a stable target and retains the original no-wing-flex behavior.
- Identical ship position/transform, hull mesh, chunk budget and landing state when only the wing-pose state is changed.
- Pilot touchdown *request* remains queued to the original physics-authoritative gate. An art pose cannot authorize landing.
- The inherited [PR #478](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/478) original native wing A/B visuals, regression suites and native capture path must remain green at this new exact head.

## How it maps toward production Godot and Chapter I

The original `main` branch retains the JS game as historical playable baseline. Chapter I native Godot (currently stacked around [PR #347](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/347)) is a **separate 2D/scene-state track**. Planetary native Godot [#364](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/364) is also a different stack. This wing lab is not yet a playable First Wake ship or a production 3D asset.

**Target integration port (not accomplished):**

1. Establish a reusable `ShipVisualPose` component in the integrated production Godot ship scene. Inject an explicit ship ref and transition requests; do not give it authority over landing physics, player/crew progression, save data, world states, dialogue or weather.
2. Add a Chapter I **presentation-only** event contract from an already established safe story/flight event, with a no-op/fallback when the 3D ship renderer is unavailable. A player can still play the scene without a pose adapter.
3. Retain simple open-flight and weather-response poses; keep the normal silhouette exactly recognizable. Validate ship, deck, railings, three masts and passenger volumes before enabling any larger angle, closure or rig movement.
4. Run Chapter I exact-head native tests, actual in-scene screenshot/video, input+reduced-motion, save/load roundtrip, boarding/landing collisions and forward-platform occupancy. Ship's intimate home identity and physical access take priority over spectacle.
5. Keep every unapproved capability, activation rule or creator-restricted reveal outside the public game and public acceptance corpus. Any further restricted development must use owner-controlled private artifacts and gates.

**Important design boundary:** The 15° preview is a geometric demonstration, not a physics-approved wing setting or aerodynamic claim. The controller is currently **unwired** to runtime input, logic or saves.

## Separate evidence / holds

| Gate | Minimum proof |
| --- | --- |
| SOURCE | Exact pinned stacked PR + diff and public-safe scope review |
| NATIVE CONTRACT | Godot 4.7.2 test `GODOT_WING_POSE_PIPELINE_PASS`; inherited regression suite green |
| NATIVE VISUAL | Real captured hinge A/B frames; separate moving-ship temporal QA remains open |
| SHIPBOARD / FOREDECK | Explicit reconcile with #452 foredeck and #461 boarding; clearance + occupied access not yet verified |
| PRODUCTION GODOT | Controlled port into approved Chapter I ship/flight scene with save/player parity |
| TARGET HARDWARE | Windows Forward+ GPU/VRAM/animations |
| CREATOR REVIEW | Art and narrative approval, distinct from CI |
| MERGE / RELEASE | HOLD |

## Provenance

- Proposed follow-up stack: review branch based on `004407f26e897ef80b4d419f72ac7b6638de1c52` (PR #478 exact verified head).
- Baseline ship source originally derived from environmental PR #432 at `b65c9ca1114c2df35193df9e0c598b8705b305d8`.
- [Godot migration coordination](../GODOT_MIGRATION_COORDINATION.md) and [public canon/reveal policy](../CANON_AND_REVEAL_POLICY.md) remain authoritative for migration and disclosure.
