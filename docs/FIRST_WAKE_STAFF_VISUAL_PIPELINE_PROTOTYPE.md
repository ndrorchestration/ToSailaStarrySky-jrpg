# First Wake → staff animation pipeline: native prototype admission test

**Status:** Read-only native Godot 4.7.2 *integration probe*, not a shipped gameplay feature. The `main` branch is still the legacy JavaScript game; the native `godot/` Chapter I migration scene and weapon studies are staged on a reviewed chain of **draft** branches. This file is on a new child branch of PR #479.

## What is actually tied back
The test invokes the authentic `res://scenes/first_wake_chapter1_review.tscn` and **its own** `take_formula_review_action("staffStrike")` method. Only the existing scene invokes `FirstWakeFormulaEncounter.take_action`; the observer never calls it. Before/after snapshots of the real formula state plus unchanged Chapter I state are passed to `first_wake_staff_visual_pipeline_observer.gd`.

The observer checks Ender's currently authorized staff, staff charge consumption of exactly 1, exactly one turn increment, stable target identity, observed (not reconstructed) formula damage, permitted authored Wind Shear retaliation and **no chapter progression mutation from the observer**. If accepted, it produces separate, read-only visual receipts from the existing equipment identity adapter, four-facing authored staff keyframes, bounded cinematic contact study and spatially aligned training disk. Every visual claim remains distinct from actual physical collision or formula damage.

A rejected/unmapped action, wrong actor, wrong weapon, extra fabricated turn, changed chapter snapshot, or invalid visual target produces **no visual receipt**. No weapon tree skill or party story energy gains executable authority.

## Real test coverage
`godot/tests/first_wake_staff_visual_pipeline_test.gd`:
1. Instantiates the actual Chapter I scene; checks initial Signal stage and Ender/Lyra party.
2. Opens the noncanonical Formula Review, verifies blocked `sharedDream`, executes a genuine `staffStrike` through the real scene, and checks observed HP/charges/turn changes.
3. Derives four directional read-only pose/target receipts **after** that true action, plus reduced-motion and spoofed-input rejection; checks observer never changes either scene state or encounter state.
4. Closes the review without changing story, advances three actual signal contacts to Crossing, opens the **existing Wind Shear hazard** through the current enemy adapter, executes one real authorized `staffStrike`, and verifies the recorded visual receipt without prematurely completing a chapter hazard or fabricating another turn.

`godot/tests/capture_first_wake_staff_visual_pipeline.gd` runs exactly one real Formula Review turn and captures a 1600×640 native split-screen screenshot: **actual Chapter I migration scene on the left**, nonexecuting authored staff pose and aligned target study on the right. A second capture uses reduced motion from the *same* observed action. The 1600×640 composite is assembled **inside Godot from two genuine GPU-rendered viewports**: the unchanged project's 960×640 Chapter I canvas and an independent 640×640 combat study viewport. It does not claim a 1600-wide playable main scene. Lossless PNGs stay on CI runner; downsampled lossy contact images and lossless frame hashes in GitHub Actions logs allow independent visual inspection. The capture contains no approved new Ender sprite or final game interface.

## Hard boundaries and migration gate
This is a sidecar observer proof, **not a live on-hit event subscription**. Snapshot validation alone is not cryptographic action provenance; the native integration test gains its provenance by directly invoking and inspecting the actual scene and checking its exact state. No new production scene changes; no automatic action dispatch, damage, target collision, enemy response, save write, class/skill permission, character affinity changes, canon promotion, main merge, release or external deployment. World-state observations are from the current **legacy Chapter I migration review**, whose timing/story still needs reconciliation with the creator's newly revised opening.

**Next smallest production step, after review:** expose an optional `action_resolved` *read-only signal* emitted by the authorized Chapter I turn controller, subscribe an isolated visual presenter, never allow the animation to determine formula results, verify no second dispatch and compare 2+ real viewport recordings. This signal, save/version compatibility, target physics/collision, real animation art, audio/camera and Windows host Defender security must be reviewed and approved independently.
