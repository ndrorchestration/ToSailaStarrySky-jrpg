# Chapter I native authority and adoption register — 2026-10-28

**Status: dated, public-safe evidence register; NOT a runtime branch, new canon decision, approval to merge, or release.** Refresh all moving PR heads and Actions receipts before citing as current. In case of contradiction, explicit newer creator decisions and the [public canon/reveal policy](CANON_AND_REVEAL_POLICY.md) outrank historical implementations. **Do not place restricted late-game narrative details in this public register.**

## Which source is actually running?

| Lane | Exact observed reference | Authority and limit |
|---|---|---|
| `main` preservation line | `79b48718b0c8b5e7f0ae4d811d5ae12e1a436a09` (inspected 2026-10-28) | The historical JavaScript/p5/NW.js browser + older desktop runtime is on `main`; **Godot is not in main**. Preserving historical source/checksums does not make it the current forward game direction. |
| Public README correction | [draft #556](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/556) `8f09ebddb69144d0d778d8a2718ca919afa23258` | New Godot-first public homepage copy, separate from preserved legacy run commands, with [passing docs/JS smoke](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/actions/runs/40641134838). **Not yet on main.** |
| Connected playable native chapter opening | [draft #547](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/547) `eae84a63d370d64bc5a11b049df4abb958301394` | Godot `first_wake_game.tscn` connects Ender's job search, Ionia hiring, engineering, original-source 3D Wake, real local 2D water-contact/flotation, controllable postflight inspection and separate v1 checkpoint. [Native Godot test 48 checks passed](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/actions/runs/40636277938). Not player-accepted or merged. |
| Native ship/camera/engine warning | [draft #546](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/546) `35603fd1eadfda5585db0a4ba570e63469caca14` | [Original 3D ship/warning GL evidence](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/actions/runs/40634568090) passed. Visual scene is **not** a production hydrodynamics simulation or creator-approved final artwork. |
| Windows native installer functional prototype | [draft #551](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/551) `4da9e450e91adbdc9216f650e3fda2c1acf3c0f2` | [Windows functional job](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/actions/runs/40639023133) PASS: a real `ToSailTheStarrySky-Setup.exe` compiled, installed, launched a native window, maximized/restored, refused duplicate installation and uninstalled. The **independent Defender-on security job failed due to runner realtime protection OFF**. Setup output runner-local; no approved new-Godot public download or release link. |
| Follow-on Chapter I story/shoreline | [draft #548](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/548) `8bd149b153e0ab417c4c5314ee08336df3cdf267` and [draft #552](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/552) `838e987f10b1be72d1e2ea38b451e2860517e7eb` | Subsequent story beats, local approach and line/berth gates are developed on a **separate stack**; they do not automatically become part of #547 or a distributable build. |
| Further visual/acceptance candidates | [draft #553](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/553) `684f3bb41e1aa41a112f29e294834c621fcda1cf`, [draft #554](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/554) `86b3b5b7f75d80bf832501ee04226c06a3ec2227`, [draft #555](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/555) `40e086d04c641ee98cd8bed69f8d2c1021cb0930` | Distinct ship art, QA criteria and open-water visuals; **individual proof is not combined production promotion**. Verify content/source/test/visual and dependency ancestry separately. |

## Source precedence and opening boundary

- **CREATOR CANON / public-safe:** Five authored playable protagonists **Ender, Lyra, Ionia, Reson, Aepex**; this is an identity roster listing, **not the revised recruitment sequence**. The First Wake opening starts with Ender alone and Ionia hiring him; the brief first flight ends in a controlled physical splashdown, and Lyra/Talen enter afterward. Do not expose unresolved fuel or later mysteries ahead of their story beat.
- **LEGACY EXECUTABLE:** The preserved JavaScript signal/crossing scenario has an older Ender → Lyra → Ionia bootstrap. It remains truthful **for the old executable and its historical tests**, not the new Godot story. `SPEC.md` preserves that precise evidence and `tests/runtime-ssot-contract.test.js` must verify the distinction. **Do not migrate old save states blindly.**
- **IMPLEMENTED candidate:** The new Godot local `RigidBody2D`/`Area2D` splashdown and separate checkpoint provide an *engine-tested* bridge, not the full planetary ocean, final visuals, all-party combat, finished chapter or player-accepted install.
- **PROPOSAL/OPEN:** All remaining precise recruitment gates, unapproved character/ship/art assets, global world parameters, premium visuals and proprietary music provenance require their own review. Passing automated tests alone does not settle authorial decisions.

## Integration & end-user release gates (all independent)

1. Fetch **exact source/head** for chosen common branch; reconcile conflicting chapter/scene/save architecture instead of merging drafts indiscriminately.
2. Run Godot editor import, native gameplay/physics/save tests, visual GL capture and inspect actual target-scale images.
3. Verify complete source-bound Windows EXE and Setup file, installed-game launch, maximize/fullscreen, save/relaunch, uninstall and per-user ownership.
4. Obtain a trustworthy **Defender realtime-on** Windows security check with exact installer checksum and provenance; do not weaken host safety or instruct a user to bypass Windows security.
5. Obtain human playable first-flight acceptance, artist/author approvals, performance/accessibility review, rights for any installed artwork/music, and **explicit creator approval** of any merge, tag, prerelease or public installer download.
6. Only after a real release asset exists and is approved, link the actual verified `ToSailTheStarrySky-Setup.exe` from the public README. **A workflow receipt, draft GitHub Release or old Aetherwake installer is not a download link to the new game.**

## Documentation routing

- [README](../README.md): new public game and download overview (currently in [draft #556](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/556)).
- [Canon and reveal policy](CANON_AND_REVEAL_POLICY.md): creator-directed public-safe opening and restricted-content boundaries.
- [Godot migration coordination](GODOT_MIGRATION_COORDINATION.md): branch integration and native engine obligations.
- [Development guide](DEVELOPMENT.md): forward-Godot gates plus the preserved historical JS verification record.
- [Legacy technical specification](../SPEC.md): intentionally old JS semantics, exact checksums, and runtime interpretation—not the new chapter's party order.
