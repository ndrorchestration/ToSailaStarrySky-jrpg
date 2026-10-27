# First Wake — Lyra/Talen reunion and three-mind fuel theory: isolated rehearsal

**2026-10-27 / STATUS: REVIEW-ONLY; NATIVE VERIFICATION PENDING.** This is not production recovery geography, accepted dialogue, a merged scene, or a finished Chapter I.

## Source authority

- [Creator-directed reboard](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/425): Ender seeks work; Ionia joins first; Aureate Wake flies, splashes down seaworthy; Lyra and five-year-old Talen introduced only after safe recovery; provisional shared theory follows.
- [First Wake playable hiring / preflight](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/430).
- [Physics-local splashdown](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/447), exact native execution PASS on `665a2b6439023afc0f77234b94a1eb05b4b170ba`.
- [Postflight diagnosis](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/455), exact native execution PASS on `474edad1bb892e950ae6ab552281a4c27e6648f0`.
- Review lines are shorter working dialogue candidates from [FW-08–10 script](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/blob/story/first-wake-flyer-splashdown-20261027/docs/story/FIRST_WAKE_REVISED_OPENING_DIALOGUE_2026-10-27.md). All require creator approval before canon promotion.

## Explicitly unresolved recovery geometry

The Aureate Wake is seaworthy after the brief test flight, but there is **no approved island, dock, beach, tow/sail route, rescue timeline, or family position**. It would be dishonest to render Lyra and Talen as physically aboard the endangered test flight or have them magically materialize after splashdown.

For that reason, the new `first_wake_reunion_theory_review.tscn` is a **separate, neutral QA rehearsal room**. It **does not appear during the launch scene** or automatically inherit an invented recovery destination. It is configured from the actual prior *local 2D* postflight receipt, which requires `postflight_diagnosis`, contact, stable buoyancy, and inspected depleted fuel reserve with only Ender and Ionia in story party. After that, it is still BLOCKED until a test harness explicitly supplies a *simulated*, source-tagged `isolated_qa_fixture` confirming safe crew contact and safe family contact. Extra keys, missing keys or false safety indicators are rejected. The marker `real_recovery_route_verified=false` remains unconditional.

**This fixture is a testing convenience, not security-grade proof or production authorization. Never route live game input or a save-load field into `authorize_qa_reunion_fixture`.** No geography is claimed or smuggled into the public script.

## Contained player-facing rehearsal

Once the explicit rehearsal fixture is supplied, E advances an intro dialogue covering Lyra, Ionia, Ender and Talen; `introduce_lyra_and_talen(true)` is invoked only after the full sequence. Talen is never a party member or combat mage. Story party transitions `[ender, ionia]` → `[ender, ionia, lyra]`.

Then the player can inspect three distinguishable evidence sources in any order using actions 1, 2, 3:
1. `phase_readings`: drift occurs under load.
2. `depleted_reserve`: specialized reserve empty and handling records incomplete.
3. `lyra_observation`: perceptible note doesn't settle.

Each observation is shown before it is recorded, and duplicate evidence is rejected. Any two independent clues permit a shared four-line theory conversation; until its final acknowledgement the state remains `family_reunion`. Completion advances only to `working_theory`. It is explicitly a hypothesis, not fuel chemistry, an identified source, an invented new power, or Denith's undisclosed final explanation. Taking a third clue **before** the conversation is supported, but no third-clue after-theory state migration is implemented.

## Native and design acceptance gates

- [ ] Actual Godot 4.7.2 import and headless regression PASS on exact PR head, including the full local water contact/diagnosis prerequisite, fail-closed unsafe reunion, full dialogue, Lyra-second join, all evidence ordering and no premature formula.
- [ ] Real 960×640 capture: legible family dialogue, zero footer collision/clipping, three clearly distinct clue affordances, reduced-motion interaction and no accidental representation of an approved port/coast.
- [ ] World recovery route and physical Lyra/Talen contact method separately approved before replacing the QA fixture.
- [ ] Canon-authorized final dialogue/portraits/art approved and implemented rather than transferring temporary review script as fact.
- [ ] Cross-scene durable party, save migration, and combat-authority tests added before production chapter integration.
- [ ] Windows installer remains blocked by the independent Defender custody/security requirement, and no binary release/merge approved.

This is an implementation milestone for **bounded dialogue, party chronology, evidence epistemics and UI rehearsal only**.
