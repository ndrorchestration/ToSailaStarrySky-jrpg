# Wake controller and input integration candidate

This draft is stacked on #281 exact `6178a461b837d31445f069738780745c72ea089c`. It selectively recovers Wake exploration from unmerged #258 controller blob `f6798f482d25b3eb9b231e6c928d23f8dfa11efb`, following the controller/input incompatibilities reproduced by evidence-only #277 at `13160bf5fe462286b56bd8d85a4bce9eab45621a`. It does not replace the current controller wholesale or import the old dock, berth, Talen, Rift Scholar or scene-record definitions.

## Player behavior

New Game enables exploration with `createState({ exploration: true })`. Existing default `createState()` callers retain narrative-only compatibility; this is not the production New Game path. The current ten authored scene records are byte-for-byte equivalent under JSON serialization (SHA-256 `b3b5e1b132932c039e8ce121abc424b1b7ff7c6bccc003262e7679f16c5e2fcb`). No party/canon/art record changes.

Scenes 5–8 each begin in the existing narrative presentation. Confirmation enters exploration after that scene's dialogue. Arrow/WASD keys move and E inspects only while exploration is active. Another confirmation advances only after the scene gate is satisfied. A visible movement/inspection cue is always shown during exploration, changing to ENTER CONTINUE when ready.

| Current scene | Required exploration event |
| --- | --- |
| `lyra_family` | Trigger the recovered anomaly through exploration/context |
| `lyra_join` | Find and acknowledge Lyra; recruit her once on subsequent confirmation |
| `ionia_practical` | Find Ionia; she does not join the active party |
| `core_walk` | Gather at least two distinct clues, then interact with the unlocked Core threshold |

The recovered `wrong_song` behavior is consistently mapped to current `lyra_join`; no authored scene rename is used. Current `presentationTicks` and runtime presentation holds remain authoritative. Each next scene returns to narrative mode; completion prevents movement and interaction mutation. Dynamic objective/feedback strings recovered from #258 remain candidate implementation content, not new creator acceptance.

## Integration-exposed defects repaired

- Nearby inspection brackets used the procedural floor mapping even when characters used the painted cabin floor. The rendered bracket was 170px above its target. A renderer regression reproduced y208 instead of y378 at Lyra, then passed after passing the painted-interior flag consistently. Both floor modes are checked.
- Movement against a clamped boundary counted as a step and mutated discovery/feedback. A negative regression reproduced this, then passed after returning without mutation when coordinates cannot change.

## Verification and limits

The initial production-input regression failed because New Game supplied no exploration state. It now runs the actual `startFirstWakeOpening`, `keyPressed`, `handleInput` and advancement bodies against the real controller. It checks presentation hold, narrative/action separation, every negative progression gate, duplicate clues, Core threshold, exactly-once Lyra join, no Ionia join, world handoff, completed-state nonmutation and narrative compatibility. The two additional defect regressions were separately RED before repair, then GREEN.

Seven selected Node checks pass locally: opening contract, narrative fallback, visual contract, measured HUD bounds, presentation clock, controller/input integration and inspection cue projection. Local syntax checks pass. A same-system reviewer found the cue defect, then re-reviewed both corrections and found no remaining important issue within this scope.

Real Linux Chromium153 at 960×640 completed New Game → all four narrative/exploration phases → two distinct clues → Core threshold → chapter card → world using physical keyboard events. No direct scene/state assignment or controller-action calls drive that route; state evaluation observes progress. Actual canvas text includes the existing three visible narrative lines for each scene, continuation cues, movement controls and Lyra objective. Page errors were empty. This is an automated scripted route, not an uncoached human playthrough or complete Chapter 1 acceptance.

The full smoke route now uses the same physical-keyboard helper through the opening before continuing its existing world/combat checks. The new Node regressions and standalone Chromium route are explicitly wired into smoke. Hosted results must be bound to the final candidate tree; local selected checks are not a substitute for that result. Historical PR277 snapshot diagnostics are not part of this candidate's tests.

The retained narrative/width Chromium probe now labels itself accurately as default-constructor compatibility plus synthetic width fixtures, rather than claiming that the live HUD is still absent. That probe is distinct from the live keyboard route.

No Windows package/installation observation, art admission, appearance approval, human player acceptance, protected-main merge, release or public deployment is established. The desktop-title correction in sibling #280 is not inherited here. VISUAL_ACCEPTANCE=PENDING; HUMAN_PLAYER_ACCEPTANCE=PENDING; PROMOTION=NOT_AUTHORIZED.
