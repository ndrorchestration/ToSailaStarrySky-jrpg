# First Wake — two-area material search with tracked custody (review v0.3)

**Status:** add-on DRAFT to native-verified [PR #552](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/552). Does not approve new coast geography, fuel chemistry, equipment item names, save schema or a launch. **Exact-head native CI required before calling this validated.**

## The chapter gap

The earlier continuous playable route completed the safe Lyra/Talen reunion and multi-person working theory, then entered an engine-room workshop where two anonymous "STOCK" and "PART" objects sat beside the core. Although the Godot interaction was physical, that did not provide the requested sense that the crew had **found** the materials in different locations and carried them back.

## New candidate gameplay

1. **Lyra is already safely recruited** through the full family dialogue and the crew has completed the independent two-clue shared theory. That is the sole entry point from Chapter I, at the theory table. The same `first_wake_revised_opening_contract.gd` object is forwarded; no alternate fake crew chronology.
2. A native **960×640 walkable salvage scene** opens at a distinct provisional **quay-side stock cache**. The player must physically approach the cache and interact to pick up `recovered_supply`. An in-memory receipt records item ID, `quay_review`, player custody and the actual scene interaction. The object changes state visually.
3. The player walks to a transition point and enters a separate **stores annex review** area with distinguishable geometry and a replacement-part pickup. Only a nearby `depot_review` source interaction can award `recovered_part`. No item spawns or auto-completes on entering the room.
4. The player walks back from the depot to the quay and approaches a distinct **return-to-Wake station** with both items carried. The scene checks two unique receipts from two different areas and the repair core's `install` state. It passes **the same in-memory `Core` instance** and identical `Opening` into the workshop. The workshop refuses a forged, incomplete, mismatched or pre-installed handoff and starts at installation; it does not award duplicate workshop pickups.
5. At the original engine-room assembly, the player explicitly installs both pieces, conducts a controlled restart, **still fails phase-lock**, then hears Ionia's anxious Denith memory, tests the interval/hold hypothesis, receives Lyra's separate observation and Ionia's captain authorization, and obtains **bench candidate only**. No live relaunch, magical refueling or combat Art.

### Gameplay design rationale

The player performs a small **outward-and-return traversal** rather than pressing E twice at the repair bench. The two required items are deliberately anonymous to protect future author approval of exact material types and sources. Environmental art is readable procedural staging; the coast and depot are not named places. Source receipts are actual in-engine memory objects driven by scene interaction, **not durable or cryptographically trustworthy inventory records**. The supplied source string `world_pickup` remains review-level contract syntax and must be replaced by an engine-integrated inventory/custody system before production promotion.

### Exact source contract

- `godot/scenes/first_wake_salvage_review.tscn`, `scripts/first_wake_salvage_review.gd`: visible walkable temporary quay/stores environments, region transition, item proximity, two area IDs, explicit return to ship, bounded in-memory custody report and no canonical properties.
- `scripts/first_wake_core_alignment_review.gd`: the bounded review core now remembers the exact `Opening` object that created it; not serialized to v1/v2.
- `scripts/first_wake_core_alignment_scene.gd`: adds `configure_with_salvage_core` for pre-collected material and rejects wrong story, premature stage, missing items, prior install, or duplicate handoff. Its isolated F6 fixture is preserved for backward compatibility; the actual connected route never uses those workbench item pickups.
- `scripts/first_wake_postflight_family_review.gd`: at end of shared theory, enters salvage rather than bypassing exploration.
- `tests/first_wake_salvage_review_test.gd`: negative and positive real scene interactions, wrong area/too far/duplicate refusal, return path, source receipts, same story + core and flight/combat denial.
- Existing `tests/first_wake_postflight_family_review_test.gd` and `tests/first_wake_main_entry_to_water_review_test.gd` now cross the **two-region pickup and ship return path** before the installation, mandatory failed retest and Denith-shanty bench sequence.
- CI uses the pinned Godot 4.7.2 editor and fails on `SCRIPT ERROR` and missing positive receipts even when Godot exits 0.

## Still missing for Chapter I production

Actual mapped coastal geography and traversable linked world zones, puzzle/choice and weather variety within scavenging, distinct approved component names/quantities, real carried inventory/weight and installation animations, save/restore for in-progress salvage, accessibility and guided navigation, animated Lyra/Talen, official shanty soundtrack and sound/meter synchronization, persistent postflight story progression, actual ship propulsion return and Windows Defender release custody. **No production inventory, musical composition, underlying fuel physics, or canon change is implied by this exploratory mechanics study.**

**Accept only on evidence:** exact source SHA native regression suite PASS; user-reviewable screenshot/video frames still needed (prior renderer artifacts runner-local due to quota); uncoached player testing and creator sign-off separate. No merge or release.
