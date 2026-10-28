# First Wake — Player-controlled harmonic chart (review v0.2)

**Source:** [draft PR #533](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/533), stacked on [two-lock repair benchmark #517](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/517) and the [creator-directed Denith/shanty story #510](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/510). Draft and unmerged.

## Existing playable review problem

In the first review workshop, pressing E beside the phase chart advanced `analyze` automatically with a hardcoded correct melody fixture. Native tests showed that logic was ordered, but **the player did not actually discover the correspondence**. The interaction was narrative automation, not a meaningful investigation.

## Improvement in v0.2

1. Ender still must physically gather two anonymous placeholder items, inspect/fit the stock and part, and watch the controlled restart fail before Ionia's anxious humming and Denith-memory repetition can happen.
2. When Ender walks to the chart, interaction opens `HarmonicAnalysisReadablePanel`. Movement pauses and the screen displays the **observed** relative phrase contour and instrument phase changes in text; it does not pretend to transcribe a real performance or read live sensors.
3. Three hypotheses are shown as readable text, each with interval pitches and beat holds. Keyboard **1/2/3** or gamepad **X/Y/B** selects a hypothesis; **E/pad A** explicitly compares the selected interpretation to the abstract chart. **C/right shoulder or Esc** closes the panel without advancing the core.
4. Incorrect interpretations have short, descriptive nonpunitive feedback. They do not remove material receipts, grant an Art, skip Lyra's observation or unlock a flight, and they may be retried. No microphone, hearing acuity, exact audio reproduction or rhythm performance is required. No automatic correct answer on pressing E.
5. Only the correct independently selected interpretation advances from Ender's `analyze` stage to Lyra's `observe` stage; the later Ionia captain-approval and core bench verification remain separate. The final outcome is still only a **review bench alignment candidate**, explicitly never a production flight authorization.

## Technical behavior and tests

- `godot/scripts/first_wake_melody_analysis_review.gd` owns modal state, selected option, attempt count, feedback and calls the existing `Melody.verify` and `Core.ender_matches_review_phrase` only after a valid selected hypothesis. It is separate from story and combat authority.
- `godot/scripts/first_wake_core_alignment_scene.gd` binds the existing input policy to modal selection and confirmation and labels a 960×640 visual overlay. The workshop remains accessible by opening its isolated scene directly, not through production `run/main_scene`.
- `godot/tests/first_wake_melody_analysis_review_test.gd` verifies early-stage refusal, absent/invalid selection, wrong short hold, wrong interval, descriptive retry, cancel/reopen, no core-state mutation on failure, correct interpretation, no replay, relative pitch transposition and no flight/combat/audio evidence.
- `godot/tests/first_wake_core_alignment_scene_test.gd` now verifies the actual Godot scene's visible panel, player-movement pause, rejected auto-solve, failed alternatives, restored movement on cancel, and a **physical InputEventKey choice and confirmation** that advances only to Lyra.
- The pinned 4.7.2 native workflow runs these two new/updated checks, plus existing saves, party/Resonance, original workshop, scene transition and visual regressions. New test steps explicitly inspect combined logs for `SCRIPT ERROR`, not only program exit codes.

## Authority and further development gates

The test fixture's pitch steps `0,+2,+5,+3`, holds `1,1,2,1` and phase vector `0,+2,+6,-2` **are not the final sung shanty or authoritative core engineering**. The menu's hypotheses are laboratory examples and will need replacing with creator-approved original music and samples measured against a real Godot audio/visual presentation. A later design might let the player place note cards or tune mechanical ratios instead of simply choosing from three text proposals.

The workshop's earlier splashdown/family reunion remains **scripted as a test fixture**, because the real Chapter I path through ocean landing is not implemented in this branch. The physical items remain anonymous 2D placeholders rather than approved salvaged materials or real persistent inventory custody. No v1/v2 save migration, public art approval, chapter canon dialogue finalization, new combined Art permission, ship launch, merge or release. Windows Defender custody remains a separate unresolved release gate.

**Acceptance requirement:** exact new-head native Godot job PASS, no runtime script errors, both new puzzle/scene checks PASS, smoke and existing renderer regressions PASS, and independent player/creator review of chart readability and dramatic timing before any production promotion.
