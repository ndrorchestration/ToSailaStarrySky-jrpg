# Tidebound Promise — isolated native Dual Art v0.1

**STATUS: IMPLEMENTED IN REVIEW ONLY / PROPOSAL ART / NO PRODUCTION AUTHORIZATION.**

This increment extends the design-only [Party Resonance catalog](PARTY_RESONANCE_DESIGN_V0_1.md) with a standalone playable Godot 4.7.2 scene. It **does not** authorize Lyra's production spell/turn access, merge into First Wake, grant mastery, change save formats, or canonize the art name or balancing numbers.

## Run the standalone study

Open `godot/project.godot` in the Godot 4.7.2 editor. Open `res://scenes/resonance_dual_review.tscn` and run **Current Scene (F6)**. The project default scene and Chapter I are untouched.

| Input | Result |
| --- | --- |
| **1** / Raise shared ward | Ender and Lyra commit their two actions, spend 1 *review-only Focus* each and create a four-point ward |
| **2** / Enemy strike | Resolve one eight-point review strike against Ender |
| **B** / No-ward test | End the player phase without shielding, for tactical comparison |
| **R** / Reset | Replay both branches from the same starting HP and Focus |
| **M** / Motion | Toggle ambient micro-motion; reduced motion defaults ON and has no flashing/camera shake |

Mouse-accessible buttons and readable text labels duplicate all commands; the two large sigils are abstract placeholders, not character sprite likenesses.

## Transaction and effect semantics

- A static preview in `party_resonance_catalog.gd` remains *DESIGN_ONLY*, `canExecute=false` and `try_execute` always returns a denial.
- `tidebound_promise_review.gd` is a **different, opt-in local combat fixture**, containing 12 HP / 2 Focus per character, one turn and one enemy strike. Focus **is not** Arete, Echoes or any canonical resource.
- The review adapter demands both characters be present/alive/able, each have at least 1 Focus, and that the fixture remain in the player phase; the existing design catalog must validate.
- A successful activation reserves both actions and both Focus costs together from one staged copy of the party dictionary, then commits the ward and moves to the enemy phase. Any denied activation leaves a byte-for-byte-equivalent state snapshot.
- Ward intercepts up to **4** damage from a single enemy strike; residual damage is distributed to the targeted participant (ceil half) and other living participant (floor half). One enemy strike consumes the ward even if capacity is not exhausted; a second strike in the same fixture is blocked.
- Example 8 incoming: `4 absorbed + 2 Ender + 2 Lyra`. No ward: `8 Ender + 0 Lyra`. Both paths consume one party-phase turn; only the ward path consumes Focus.
- A battle restart restores the complete original fixture. It does not serialize into Chapter I saves.

## Files and native QA

- `godot/scripts/tidebound_promise_review.gd` — locally isolated combat fixture, costs, admission, bounded absorption/sharing and rollback.
- `godot/scripts/resonance_dual_review.gd` + `godot/scenes/resonance_dual_review.tscn` — standalone genuine Node2D scene and accessible text/button UI.
- `godot/tests/tidebound_promise_review_test.gd` — deterministic valid/invalid cases, both reservations, equal-cost accounting, one-hit ward, comparison to baseline.
- `godot/tests/resonance_dual_review_scene_test.gd` — scene startup, controller buttons, result text, reduced-motion toggling, baseline replay and untouched First Wake authority.
- `godot/tests/capture_resonance_dual_review.gd` — opt-in authentic 960×640 native GL-Compatibility opening, active-ward and resolved stills, checked for actual frame differences.
- `.github/workflows/godot-first-wake-pilot.yml` and `.github/workflows/godot-visual-review-capture.yml` — run headless contracts plus renderer-side still capture in existing pinned-engine pipelines.

**Version status:** Native contract and scene tests passed at earlier review commit `e1af5220211745ee8e87684d76fe211554ee54b2`, hosted run [40576592333](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/actions/runs/40576592333), plus repository smoke. Subsequent renderer-capture edits need **new-head execution verification**; do not transfer prior run status without checking it.

## Explicit unfinished gates

1. Actual production combined-art authorization, mastery/unlock gate and Lyra's action contract.
2. Shared `AbilityDefinition` normalizer and typed costs/resistance/field resolver for real encounters.
3. Round-by-round turn scheduler, interruptions, target invalidation and rollback under full battle concurrency.
4. Real party scene integration, save migration, UI navigation and balancing over multiple battles.
5. Character-specific approved animations, cinematic sound/particles/cut-ins and creator-approved likeness.
6. Real native render review, accessibility/user testing, platform build and release acceptance.

An unmerged draft PR is not approval of any of the above. Public implementation intentionally avoids restricted celestial lore.
