# Godot production direction and parallel-agent coordination

**Creator-selected 2026-10-24:** Stop expanding p5.js/JavaScript gameplay; continue development in **Godot 4.7.2 + GDScript**. This is the authoritative **forward development decision**, not retroactive proof that the full JRPG, save data, world, art or Windows release has already migrated.

## Native First Wake development state — 2026-10-28

**Current coordination register:** [Chapter I native source/evidence/authority](CHAPTER_I_NATIVE_AUTHORITY_STATUS_2026-10-28.md). Every branch reference is a dated snapshot, not a moving proof. Creator-directed opening: **Ender seeks work → Captain Ionia joins before flight → physically confirmed controlled ocean landing → Lyra and Talen introduced later**. The older Lyra-first `Signal → Crossing` build remains preserved on `main`, not as a template for the forward native Chapter I party or saves.

- **Native connected game:** [draft #547](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/547) `eae84a63d370d64bc5a11b049df4abb958301394`, [native Godot first-flight/physical splashdown/checkpoint CI PASS](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/actions/runs/40636277938); not in `main`.
- **Native original ship/warning:** [draft #546](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/546) `35603fd1eadfda5585db0a4ba570e63469caca14`, separate image/physics authority.
- **Windows installable proof:** [draft #551](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/551) `4da9e450e91adbdc9216f650e3fda2c1acf3c0f2`, functional Windows Setup.exe/launch/maximize/uninstall **passed**, but **independent Defender-on security custody failed**, signing/player acceptance absent and no installer publicly downloadable.
- **Different story/visual stacks:** [draft #548](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/548), [#552](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/552), [#553](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/553) and [#555](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/555) address subsequent beats and ship/coastal art; none automatically merges into #547 or confers release readiness.
- **Public status correction:** [draft #556](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/556) fixes the stale legacy-first README, with [smoke PASS](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/actions/runs/40641134838), but `main` still shows the old README until approved merge.

**Do not blindly merge native stacks**: inspect ancestry, reconcile legacy/new story state, human-verified art, installable output and distinct source test receipts first. Main's branch protection was observed **off** on 2026-10-28; review branch-protection policy independently with the repository owner; do not silently modify it here.

## Historical 2026-10-24 branch/track snapshot (not live authority)

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
