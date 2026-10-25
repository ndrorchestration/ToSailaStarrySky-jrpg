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
