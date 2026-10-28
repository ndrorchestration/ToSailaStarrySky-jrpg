# First Wake — Shipboard Recovery Readiness (Chapter I review)

**Status:** SOURCE CANDIDATE; not a creator-approved rescue, navigational solution, production cutscene, Windows release or completed Chapter I.

**Parent:** [Native-tested reunion and fuel theory PR #464](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/464) at exact `cd13dd7156e48409b75f82469d02b4878dbfe12c`. Creator-directed chronology and family constraints: [PR #425](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/425).

## One physically and narratively honest increment

The current local 2D splashdown confirms **buoyant stable contact**, but does not prove a traversable sea route, working communications, or safe reunion. The new `first_wake_recovery_readiness_review.tscn` is a **shipboard-only, playable diagnosis/checklist**. From the validated postflight reserve stage the player presses the existing remappable **F** action to open this scene on the Aureate Wake. Each of the following requires both lines of an Ender/Ionia conversation before evidence is recorded:

| Action | Observable, provisional finding | NOT established |
|---|---|---|
| 1 — Crew accounting | Ender and Ionia are accounted for; further hull inspection is needed | Universal hull soundness, future sea safety |
| 2 — Engine isolation | Unstable harmonic engine is offline; evaluate nonflight recovery separately | Safe sail/tow route or restored engine |
| 3 — Contact-plan preparation | A factual status message has been drafted | Radio/rune delivery, receiver, location, time of arrival |

Order is free. Duplicates and premature completion are rejected. Completing all three yields **READY FOR ROUTE REVIEW** with immutable flags: `actual_sailing_route_verified=false`, `safe_family_meeting_verified=false`, `message_delivered=false`, `recovery_success_certified=false`, `fuel_formula_verified=false`, and `route_status=awaiting_creator_geography`. It does not progress the main Chapter I story FSM or confer party combat authority.

## Cross-scene integrity

The downstream **QA-only** Lyra/Talen reunion rehearsal now additionally requires that the *same flight and story state* have a complete recovery-readiness receipt. The existing synthetic `isolated_qa_fixture` remains an explicit, separate gate and is still **not** production proof of meeting safety. No live scene automatically invents a location or launches the family encounter. This test arrangement is meant to enforce source honesty until the creator settles the voyage, tow or rescue geography and any required transmission/meeting interaction.

## Executable acceptance test

The existing exact-head native `first_wake_reunion_theory_review_test.gd` now runs a full chain:

1. Reject job-only, preflight, airborne, unlanded, uninspected or prematurely completed context.
2. Physically measure local `RigidBody2D` ocean contact and stable buoyancy.
3. Complete fully acknowledged postflight diagnosis with Ender and Ionia.
4. Require shipboard crew/engine/message checks, in nondefault order; reject duplicate/early evidence and false claims of sailing, delivery or reunion.
5. Attach the same-source readiness state, reject duplicate/foreign sources.
6. Admit only the explicitly named QA meeting fixture; then complete family dialogue, recruit Lyra second, leave Talen nonplayable, and form a 2-of-3 working (not verified) fuel hypothesis.
7. Existing Wind Shear, saves, old Chapter I migration and current party authorization contracts must continue passing.

**Native Godot 4.7.2 verification:** pending until exact-head hosted run is inspected. Passing this bounded test is not proof of cinematic ship navigation, a completed chapter, actor/art finalization, performance, Windows Defender compliance, or player acceptance.

## Separate blockers

- **Creator-approved recovery method and reunion geography:** OPEN. No port, sea lane, tow distance, sailing travel time, route safety or communications method has been selected.
- **Production world/ship integration:** the local 2D review is not the existing planetary globe, weather system, native ship art, 3D landing physics or deck/interior camera.
- **Family scene acceptance:** revised dialogue is a working script candidate, not locked VO, sprites, staging or emotional QA.
- **Persistence:** no changes to the versioned production Chapter I save schema; recovery checklist is isolated scene state only.
- **Windows security:** separate Defender custody preflight remains unapproved; no merge/release/publishing.
