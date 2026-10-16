# PR #276 live HUD reachability investigation

Source inspected: `44a63ea03b8874cb427b81f2f62c1763231cde0b`.
This evidence draft is stacked on #276. No production code was changed.

## Observed blocker
The proposed objective, feedback and clue HUD is dormant in the exact candidate.
Both production HTML entrypoints load `modules/first-wake-opening.js` (blob `01f0128ef5f34449a3a94b1bc47e6737ffe9e709`).
That controller exports v0.1.0 and neither `wakeExplorationView` nor `nearbyWakeHotspot`. Its state has no `wakeExploration`.

Call chain: HTML -> controller + bundled `aetherwake.js` -> `drawFirstWakeOpening` -> visual.draw -> sequences 5–8 -> drawWakeExploration -> missing view/state -> drawInterior + return.
Consequently the HUD code is never entered. A real Chromium 153.0.8010.0 renderer probe at 960×640, using the production controller's createState/advance/tickPresentation, recorded zero text calls in all four scenes: lyra_family, lyra_join, ionia_practical, core_walk. The settled core_walk captures visibly show the interior and actors with no objective, feedback, clue cue or dialogue text.

Protected main also has no exploration API (opening blob `37d59c4a6329a14535db21a89d43d6950a5ff74a`). Exact #272 and #273 use the same v0.1.0 controller blob as #276. Their diffs do not provide an authored exploration controller to extract. This is not safely repairable as a width-only adjustment.

## Checks and limits
- `node tests/first-wake-hud-reachability.test.js`: deliberately RED, exit 1, missing wakeExplorationView. This new diagnostic is not wired into CI. Do not use invented controller objectives to turn it green.
- `node --check tests/capture-hud-reachability.js`: PASS.
- `node tests/capture-hud-reachability.js`: exit 0; page errors []; result BLOCKED_MISSING_LIVE_HUD_CONTROLLER.
- Exact-ref runtime bytes were materialized through GitHub, and core JS, controller, renderer, p5 and entrypoint blob IDs were recomputed. This was not a Windows checkout; RDC devices were offline.
- Captures use a direct production renderer probe, not an uncoached playthrough. The day/night flag changes the real vignette only; it is not evidence of two authored time-of-day scenes. Optional unrelated assets were not all materialized.
- No longest authored objective/feedback corpus exists in this loaded controller. Text containment, clue-state measurement and E INSPECT validation therefore remain blocked. No overflow defect was established and no ellipsis/wrap repair was made.
- Historical hosted and Windows smoke remain evidence of their inspected coverage, which did not exercise this dormant HUD.

## Capture packet
Local source packet: `evidence/hud-reachability-20261016/`.
Manifest and expected-red output accompany this draft. PNGs remain internal scratch captures only; no screenshot deliverable is published. Reproduce them with the capture script. Recorded hashes:
- core-walk-day.png SHA256 `9aeb4a020692640c02e6f6ddf62ec00dadb10aa97f22bbb767927df7ba42ed66`
- core-walk-night.png SHA256 `4fabb17fdf0709f50bec8d46dc05dc90debfe0a0a4ae0db9a21fb379be5e5223`

Next decision: identify the approved authored exploration controller contract before integrating it, or restore the existing narrative fallback in a separately scoped repair. Then rerun the real authored-copy containment gate.

VISUAL_ACCEPTANCE=PENDING
HUMAN_PLAYER_ACCEPTANCE=PENDING
PROMOTION=NOT_AUTHORIZED
