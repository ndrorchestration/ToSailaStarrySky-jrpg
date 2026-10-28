# Godot production direction and parallel-agent coordination

**Creator-selected 2026-10-24:** Stop expanding p5.js/JavaScript gameplay; continue development in **Godot 4.7.2 + GDScript**. This is the authoritative **forward development decision**, not retroactive proof that the full JRPG, save data, world, art or Windows release has already migrated.

## Branch/track separation (as last inspected)

- **`main`:** historical functioning JS/p5/NW.js game and documentation baseline. Do not destroy; use its content, equations and tests as migration reference.
- **Native Chapter I stacked line:** e.g. `feat/godot-first-wake-party-combat-authority-20261022`, reported head `74fe1bce7a8a02eb3cbf30f725fa2af0925ba670` by Hyperagent's local inspection. Verify remote head before each change. Stacked native work PRs #306–347 not assumed merged.
- **Hyperagent local UI candidate:** `work/godot-native-ui-validation-20261024`. Hyperagent reports branding, CanvasLayer modal occlusion, wrapped labels, repeatable test runner, CI aggregate and evidence (34 checks, nine native captures) **locally**, but **not yet pushed**. Treat as agent-reported and unadmitted until exact bytes/source/logs are available to verify.
- **Native planet/flight track:** [draft PR #364](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/364), head observed `567594e25fc0a1b9eb9f4d8b86b4080f5f8246b7` at this handoff, based on the native Chapter I line. Isolated Godot geometry, flight, globe; not a finished integrated world.
- **Earlier JS planetary studies:** draft [#349](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/349), [#363](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/363). Preserve as evidence/visual reference; **no additional JS gameplay development**.
- **Standalone higher-fidelity Godot artifact line:** tracked separately in Notion and #350. Do not reconstruct from textual hashes or assume the exact renderer ZIP is already in this GitHub repository.

## Safe integration sequence

1. Fetch branch/PR states and the *exact* sources (not just agent summaries); choose a common ancestry, avoid overwriting other agents' changes.
2. Stabilize Godot Chapter I: correct opening/quest/party/combat/save state, editor import, headless native tests, real scene captures.
3. Integrate Hyperagent's **actual** local patch once published; diff against native Chapter I and preserve test/evidence provenance.
4. Introduce planet/flight as separate scenes/systems with isolated world state; verify chapter and save compatibility **before** coupling.
5. Replace primitive art through creator-reviewed source/converted assets, genuine native screenshots and Blender/Godot visuals.
6. Performance/Windows export/installed-launch/player acceptance and release permission are distinct; no silent promotion.

## Evidence categories

- **SOURCE:** branch + commit SHA, changed paths, provenance.
- **NATIVE CONTRACT:** exact Godot 4.7.2 version, headless import, native tests, scene instantiation.
- **NATIVE VISUAL:** real Godot runtime frames, controls, pixel/occlusion and shader/lighting checks, exact capture manifest.
- **TARGET PLATFORM:** hardware/renderer/FPS/VRAM + Windows packaging / installed launch.
- **CREATOR ACCEPTANCE:** distinct human art/scene/gameplay approval.
- **RELEASE:** separately authorized action; default HOLD.

Documentation and canon descriptions do not upgrade any of these evidence categories. Notion/Drive may hold detailed receipts, but the GitHub branch/PR must link them explicitly when required. Verify the head again: these SHAs are dated pointers, not immutable branch locks.


## 2026-10-27 — Forest visual study → Chapter I GDScript policy bridge (REVIEW ONLY)

This append-only reconciliation supersedes the assumption that the separate forest prototype must be merged wholesale to test any production portability. Native Chapter I and the 3D flight study have **divergent Godot scene roots**.

- **Forest study source:** [draft #488](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/488), exact head `5fac28c5dd5159d742ffb102db71f70a8224cb34`. Native 4.7.2 [run 40611335217](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/actions/runs/40611335217) PASS, noncanonical standalone `godot/flight_slice/`. Source assets, local terrain shader, placement, LOD capture receipts and 960×640 screenshots remain draft and **visually unapproved**.
- **Separate native Chapter I candidate:** [draft #480](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/480), exact parent `46e15dbd94cedf964fdc008dad8528d8140dcbb6`. Contains the `godot/` Chapter I GDScript project, its own actors, 2D staging, gameplay and save contracts; it does **not** consume the forest source.
- **First actual portability proof:** [draft #504](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/504), first code head `54122a4e9f44ba8fc880c1cb65e4a55c8c6c5fde`; pure noncanonical `godot/scripts/forest_visual_bridge.gd` + new native SceneTree test and CI step. It tests 29/39 local-unit near/far hysteresis, one normal mesh change per update, instantaneous low-quality fallback, and fail-closed canon/collision/navigation/save/planetary-space admission. **No forest mesh or shader is imported; no gameplay scene is wired.**
- **Actual bridge execution:** Godot 4.7.2 native [run 40615514993](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/actions/runs/40615514993) PASS with `FOREST_CH1_BRIDGE_PASS`; [smoke 40615514956](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/actions/runs/40615514956) PASS at first code head. A later documentation-only head on #504 requires its own CI verification; never transfer checks between commits.
- **Separate Windows gate:** [run 40615514378](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/actions/runs/40615514378) was **NOT a Windows QA PASS**. The exact Windows preflight failed `WINDOWS_QA_HOST_DEFENDER_REALTIME_DISABLED`. A sibling job passing cannot override the custody/security failure. Do not disable or weaken this gate.
- **Full handoff procedure:** `docs/FOREST_VISUAL_PROTOTYPE_TO_PRODUCTION_GATE.md` on #504 and [Notion Forest Vegetation LOD integration gate](https://app.notion.com/p/407f5bad238b813eb8a7dabeddf5926b). Reusable is the **algorithm/evidence interface**, not the low-poly art or planar coordinate model.

**Next native game gate:** choose only an existing traversable environment, define world-surface and local-tangent-to-global-frame ownership, then add one isolated opt-in terrain-bound vegetation patch with identical collision/quest/save and actor foot anchors OFF/ON. Test native rendered 960×640 scenes, movement/occlusion, reduced motion, low quality, LOD transitions, and target Windows GPU/VRAM **before** creator art and player acceptance. No spherical biomes, Moon Bridge route, new settlement, ship mode, Chapter I canon, merge or release is admitted by this portable-contract test.

**Authority status:** `PORTABLE_POLICY=GODOT_NATIVE_EXECUTED_ON_EXACT_SOURCE`; `PLAYABLE_FOREST=NOT_INTEGRATED`; `PLANETARY_RUNTIME=NOT_INTEGRATED`; `VISUAL_ACCEPTANCE=PENDING`; `WINDOWS_SECURITY=BLOCKED`; `PRODUCTION_PROMOTION=HOLD`.
