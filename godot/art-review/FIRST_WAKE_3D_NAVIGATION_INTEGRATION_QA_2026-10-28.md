# First Wake — physically navigable 3D dock / integration contract (2026-10-28)

**Status:** Standalone 3D engine implementation verified in **GitHub's official Godot 4.7.2 Linux runner**. Original First Wake native game is the protected F5 main scene. **Not merged, not artist-approved, not a Windows player build, not Chapter One's 3D conversion.**

**Code review:** [Draft PR #591](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/591) stacked on [draft PR #590](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/590).

## Real gameplay-engine increment

Unlike PR #590's camera-only spatial scene, this adds a real `CharacterBody3D` on the pier, using the actual Godot physics solver: WASD acceleration, gravity, `move_and_slide()`, foot support, physical travel-distance accounting, and four facing directions. A source-approved character GLB is still required. Until then the player is represented by a **turquoise ground cursor explicitly labeled NOT A CHARACTER** rather than fabricated Ender or a visually incorrect generic humanoid.

The pier has `StaticBody3D` collision on the full walking deck, stone arrival plaza, and edge-protection rails. This is deliberately isolated from the canonical 2D water `RigidBody2D`, flight, party, stories and saves. A three-point `Area3D` interaction harness now offers genuinely physical **E** inspections at the job notice, Ionia arrival, and Aureate Wake gangway. These emit **noncanonical review text** only. They do not recruit Ionia, trigger her real dialogue, board the ship, or grant plot-locked capabilities.

Controls in the **new branch's scene** `res://scenes/first_wake_3d_visual_slice.tscn`:
- **WASD:** real 3D foot movement
- **E:** inspect nearest intersecting spatial probe (not a fake story event)
- **Arrow keys:** independent camera orbit/zoom
- **C:** toggle camera follow
- **T:** toggle golden/blue hour
- **R:** reset review camera

The HUD states precisely that the turquoise cursor is not approved character art and the story has not been migrated.

## Verified exact-head engineering

On [GitHub Actions run #40708140207](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/actions/runs/40708140207) for head `f2597cd39d18bbae7052053969642b099fcfa26b`, **dedicated official Godot 4.7.2 CI PASS**:

- Source privacy and unchanged F5 launch check: PASS.
- Real native Godot project import and script compilation: PASS.
- Native `first_wake_3d_navigation_test.gd`: PASS. Simulated inputs move an actual `CharacterBody3D` across modeled dock and onto proximity volumes, requiring floor contacts and genuine edge collision; checks E inspection receipts and rejects claims of story integration.
- New native `capture_first_wake_3d_navigation.gd`: PASS. Three actual Linux OpenGL **960×640** frames captured for spawn, notice, and Ionia spatial checkpoint, with story-honest HUD.
- Captured frame artifact `first-wake-3d-navigation-qa-frames`, three PNGs and `SHA256SUMS.txt`: [download from the CI run's Artifacts section](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/actions/runs/40708140207).
- Existing PR #590 scene/camera, water/lighting and private GLB-slot structural test: PASS.
- Unchanged original Ionia-first native First Wake water splashdown, postflight agency, save/resume and legacy save isolation regression: PASS.
- Real OpenGL 3D camera rendering of inherited scene: PASS.

**Windows evidence boundary:** This branch has **not yet been verified on the owner's native Windows machine** because the remote desktop connector went offline. The desktop `PLAY FIRST WAKE - 3D Coastal Preview` shortcut still targets the earlier tested PR #590 worktree, **not this new PR #591**. Do not claim the newer playable movement is available through that shortcut until an exact-head Windows checkout is created, render/physics tested, and the shortcut explicitly retargeted.

## Cohesive progression toward actual Chapter One

The next production work is not a new placeholder pass. It must:

1. Attach creator-approved source-identical **rigged Ender and Ionia GLBs**, reviewed from all four viewpoints and moving at true in-game scale, to the existing art root; no generic replacement models.
2. Connect the spatial notice and Ionia/ship interactions to the **same authoritative narrative/session events** used by current First Wake. Preserve the Ionia-first sequence and actual save checkpoint, with a single source of truth. Do not maintain a second independent story implementation.
3. Replace the open-water, coast, ship and dock blockouts with actual detailed 3D assets/materials and cinematic lighting; verify both renderer modes against screenshot art acceptance and on minimum hardware.
4. Only once visual and behavioral parity are established, plan a safe switch of normal F5 player entry and separately verify Windows installer, Defender-on security and creator release approval.

**No main merge, character canon, original game save mutation, source art upload, publicly downloadable native installer or release approval took place.**
