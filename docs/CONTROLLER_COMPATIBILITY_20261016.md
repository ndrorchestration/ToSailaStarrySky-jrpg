# First Wake controller/input recovery: integration boundary

This is executable preparation for selective recovery, not live exploration or a replacement controller. It extends evidence-only draft #277. Narrative fallback #278 and verified HUD candidate #281 remain separate. No production source, acceptance gate, protected main or release is changed.

## Reproduce

Run `node tests/first-wake-controller-compatibility.test.js` at this evidence branch. It exits zero only when the pinned incompatibilities and the recovered controller positive control reproduce. It deliberately prints `INTEGRATION=NOT_ESTABLISHED`. This is not a smoke/readiness gate and is not wired to CI. Existing deliberately RED `first-wake-hud-reachability.test.js` remains RED.

| Source | Exact identity |
| --- | --- |
| Current diagnostic parent | #277 `c23e7e173a5e4a595bf13db338c6f193b1ca5625` |
| Current controller | `modules/first-wake-opening.js`, blob `01f0128ef5f34449a3a94b1bc47e6737ffe9e709` |
| Current input/runtime | `aetherwake.js`, blob `a2399d6d344cc6db0049205c88af916d6181d736` |
| Recovered unmerged candidate | #258 `d4145ab9aedbfd70640fc2bac9890f0459d3d927` |
| Recovered controller fixture | `tests/fixtures/first-wake-controller-v08.js`, exact original blob `f6798f482d25b3eb9b231e6c928d23f8dfa11efb` |

The current controller/input blobs also match the #281 candidate inspected at `6178a461b837d31445f069738780745c72ea089c`. Fixture bytes are bound with Git blob hashing before execution. The old file header says v0.7; its exported VERSION is 0.8.0. It is a test fixture, never loaded by the game. No source discovery implies creator admission.

## Observed contracts

| Boundary | Current stack | Recovered candidate | Required internal reconciliation |
| --- | --- | --- | --- |
| Presentation | `presentationTicks`, `canAdvancePresentation`; runtime holds Enter before minimum | `sceneTicks`, `presentationReady`; `advance` enforces cinematic minimums | Preserve current clock and input hold; do not add a second clock |
| Opening input | Enter/Space advance; no opening movement/E dispatch | Requires dock movement, berth/Talen interactions, then Wake movement/interactions | Recover input and state together; controller-only transplant stalls at dock |
| Sequence 6 | `lyra_join` | `wrong_song`, acknowledgement required before join | Map behavior consistently without replacing current authored scene or bypassing acknowledgement |
| Wake HUD | Current state/APIs absent | Supplies state, movement, hotspot, view and feedback APIs | Integrate a coherent contract, not only display APIs |
| Progression | Ten narrative scenes complete through confirmation | Additional dock, berth, Talen, anomaly, Lyra, Ionia and Core gates | Explicitly choose selective scope; retain all included prerequisites and visible controls |
| Party | Lyra joins at sequence 6; Ionia remains outside active party | Same party invariant, different interaction gate | Exactly one Lyra recruitment; no early Ionia join |
| Authored copy | Newer scenes/card contain different text | Older dialogue/card and scene metadata differ | Preserve current authored scene records; no wholesale source replacement |

The current key dispatcher was executed with its actual `keyPressed`, `handleInput` and `advanceFirstWakeOpening` function bodies. Audio/toast/clock sinks are stubbed; this is a Node VM test, not a browser or player session. It shows:

- Current narrative route respects the initial hold and completes, recruiting Lyra once, without an exploration state.
- Swapping only the recovered controller reaches `dock_walk` and stalls. Right-arrow, D, E, Enter and Space do not satisfy the recovered gate.
- At a directly selected Wake scene, all arrow/WASD/E keys leave exploration unchanged. Direct state selection is diagnostic setup, not player-route evidence.
- Renaming only the recovered scene record and its validator list to `lyra_join` yields an empty objective, no Lyra interaction event, and an unguarded party join. Behavior branches still use `wrong_song`. This is a deliberately incomplete mutation demonstrating why an ID-only patch is unsafe, not a proposed implementation.
- The untouched recovered controller completes through its own exported movement/interaction APIs: dock → berth → Talen → anomaly → Lyra acknowledgement → Ionia → locked Core → two distinct clues → Core threshold → chapter card. Lyra joins once; Ionia does not join. This proves recovered API consistency, not integration with the current input or renderer.

## Verification receipt

Local Node 24 diagnostic exits 0. An in-memory sensitivity mutation that routes the right arrow to recovered `moveDock` makes the expected dock-stall assertion fail, demonstrating that the diagnostic notices the missing input boundary changing. The fixture Git blob hash matches its pinned source; current controller and input hashes match the diagnostic parent. The original live-HUD prerequisite remains expected RED. No full smoke, Chromium route, Windows package or human acceptance is claimed for this evidence-only change.

## Next implementation boundary

Recover Wake sequences 5–8 as one coherent controller/input candidate on top of #281, preserving current SCENES, presentation clock and party/canon records. The implementation must make the scene-6 acknowledgement mapping explicit, route opening movement/E exclusively while exploration is active, preserve Enter/Space behavior outside that range, and keep included gates and feedback consistent. Dock/berth/Talen mechanics are a distinct scope; importing the entire v0.8 controller would silently import those gates and older authored copy.

Before claiming live exploration, require tests for negative progression gates and exactly-once recruitment, a real browser route using physical keys rather than direct state assignment, and full hosted smoke at the resulting tree. Current rendering deliberately switches to the exploration HUD when APIs exist; the integrated route must also verify the intended authored scene presentation instead of silently reintroducing hidden narrative. Visual/player acceptance and promotion remain pending independently.
