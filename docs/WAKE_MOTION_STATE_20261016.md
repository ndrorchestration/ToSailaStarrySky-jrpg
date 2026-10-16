# Wake movement pose correction

This draft follows verified controller/input candidate #282 at `d5474165932480702b48f7a6211f5806a3e2b603`. That candidate moves the actor but never supplies the `moving` and `facing` values already consumed by the exploration renderer. It therefore selects idle action/zero procedural speed and defaults to right-facing regardless of movement input.

Successful exploration movement now sets a 12-tick walking pulse against the existing `presentationTicks` clock. Another successful step extends that deadline; presentation ticks expire it back to idle. Horizontal displacement changes the supported left/right facing; vertical displacement retains the prior lateral facing. A clamped horizontal component in a diagonal API request does not change orientation. Blocked or invalid movement leaves pose/deadline and discovery state unchanged.

Scene entry/exit clears the pulse so a deadline from the prior scene cannot leak across its clock reset. No second scene clock, animation loop, asset, authored text, scene record, progression gate, recruitment rule or renderer implementation is introduced. Default narrative-only state construction remains compatible.

## Verification

- New motion regression was RED because initial exploration lacked moving/facing state, then GREEN after correction. It observes the existing renderer receiving walk/idle actions, nonzero/zero procedural speed and left-facing state; checks expiry, refresh, wall/invalid-input nonmutation and phase reset.
- Reviewer identified a diagonal-boundary edge case. An explicit boundary-state fixture reproduced RED (`right` instead of retained `left`), then passed after basing facing on actual horizontal displacement. This fixture is a unit test, not player-route evidence.
- All eight selected Node checks pass: the new motion test plus controller/input, inspection cue, opening, narrative fallback, visual contract, measured width and presentation-clock checks. Syntax checks pass. Same-system review found no remaining important issue after the correction.
- Linux Chromium153 at 960×640 completed the physical-keyboard route from New Game through the four narrative/exploration phases, two distinct clues, Core threshold and world handoff. An observing wrapper forwards the real procedural renderer and waits for sequential walk-left, settled idle-left and renewed walking after vertical input. It does not change gameplay state or replace renderer behavior. The route completed with pageErrors empty. The test-only two extra movement presses account for its 52-step receipt versus the previous 50-step route.
- The motion Node check is explicitly smoke-wired; the existing physical-browser check now observes motion as part of its route. Full hosted verification must be read at the final candidate tree.

This fixes movement-state routing to existing rendering paths. It does not add approved front/back directional artwork, establish gait smoothness, admit a field pack, validate Windows packaging, or establish human visual/player acceptance. No merge, release or public deployment. VISUAL_ACCEPTANCE=PENDING; HUMAN_PLAYER_ACCEPTANCE=PENDING; PROMOTION=NOT_AUTHORIZED.
