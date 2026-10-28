# First Wake — actual opt-in 2D ↔ 3D shipboard walkthrough (2026-10-28)

**G3-candidate implementation in an unmerged Godot 4.7.2 draft only. Not approved Chapter I production art or canonical ship access.**

## Implemented player-facing slice

Open `res://scenes/first_wake_optional_shipboard_3d_review.tscn` in the Godot editor and play it **instead** of changing `project.godot`'s existing `run/main_scene`. This new Node root instantiates the **actual existing playable** `first_wake_job_preview.tscn` and the physically tested `aureate_wake_metric_bridge_study.tscn`. The normal 2D storyline stays active at launch.

After Ender legitimately reads the job notice, Captain Ionia hires him and he enters **engineering**, an unobtrusive B review hint appears. Pressing **B** then displays the actual interactive 3D geodesic-helm / ordinary open-foredeck scene. It is not a video, image-plane mockup, fictional quest transition or change to production First Wake. **B** returns to the *same instantiated 2D engineering scene*, with exact story/party/inspections/Ender checkpoint preserved. Re-entry is explicit and never armed by an early B press.

Once inside the review: **WASD / arrows** move the anonymous physically driven adult capsule; **E** operates a nearby real hinged/physics-blocking hatch; **F** near the provisional helm console displays only a *static no-flight-controls* observation; **G** switches among metro-proxy and exact-original-source clear / low-glare glass art variants. Nothing can launch the ship, modify an engine core, invoke Resonance, confer an ability, add Lyra or set an irrevocable story flag. A 2D `CanvasLayer` in the original preview must also be hidden and restored explicitly so existing dialogue/quest text does not cover the ship.

## Strict eligibility and saving contract

The opt-in admission method checks all of:
- Existing First Wake's **room is engineering**, not dock or story job-search.
- Story step is **engineering or preflight**.
- Actual roster is exactly **Ender + Ionia** (not Lyra yet).
- No mandatory dialogue is open.

This is a **read-only transient scene swap**. It neither adds a field to the strict `tstss.first-wake.revised-opening.review.v2` checkpoint nor upgrades the previously fail-closed production admission manifest. 2D processing/input is disabled while in 3D, 3D processing/input is disabled after returning. The wrapper scene's `transient_review_contract()` explicitly denies saved story state, flight controls and production readiness.

The anonymous crew is a human-sized physics capsule, **not named protagonist art or final skeletal animation**. The same-world third-person camera inherits the original physically occlusion-tested positioning; its true hardware/performance on Windows is not yet accepted.

## Executable proof

- `godot/tests/first_wake_optional_shipboard_3d_test.gd` loads the *actual new root scene*; checks refusal before hire/during dialogue; obtains eligible hired state through the **existing versioned checkpoint validator**, not a forged roster or direct step assignment; then proves genuine 3D view and actor/hatch/helm/glass operation, collision denial and return to the identical 2D checkpoint. It checks story, save and Resonance isolation, repeatable entry/exit, no latent premature opt-in, and two independent render/input modes.
- `godot/tests/capture_first_wake_optional_shipboard_3d.gd` produces **four real Godot 960×640 screenshots**: 2D Ionia-first engineering before entry, physically moved actor at 3D helm, physically moved actor on 3D open deck, and return to unchanged 2D engineering. Same engine, same actual scene and screenshot SHA receipts; no still-image substitution.
- The dedicated [native CI workflow](../.github/workflows/godot-first-wake-optional-3d-shipboard.yml) uses the pinned official Godot 4.7.2 binary, strict import/physics failure checks and real software GL. Inherited [#553](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/553) maritime art, #549 real rail physics, #540 source glass, #531 walking control and main First Wake production gate remain separate verification inputs.

## Still blocked

The 3D scene is **opt-in and review-only**, not the native project's default entrypoint. It uses a provisional 3.50m hull beam, 3.20m visual dome, unchanged anonymous review actor and review-only maritime rail treatment. It has no five-protagonist full occupancy, final Ender/Ionia 3D art, animation locomotion blend tree, gameplay helm/quest engine, environmental glass certification, actual ship flight/seaworthiness/wing motion, deck child safety or accessibility sign-off.

Final cinematic scene staging, real character art, animation/UX QA, representative GPU FPS/VRAM, installed Windows with intact Defender security and the creator's explicit canon/merge/release approval are separate requirements. Never silently merge or promote this G3 candidate or disclose late ship lore.

**Evidence status:** only mark native and screenshot checks passed after reading the exact-head workflow run and artifact. The new scene is not the same as the historical default `first_wake_chapter1_player_preview.tscn`.
