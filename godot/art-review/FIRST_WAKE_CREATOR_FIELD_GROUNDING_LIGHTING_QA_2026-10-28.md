# First Wake — creator-correct field grounding and coastal lighting (2026-10-28)

**Status:** Native Windows **technical PASS**, real creator matte-v3 screenshots **verified**, final visual appearance **REVIEW HOLD**, full directional walking artwork **ABSENT**, Windows installer security **HOLD**. This work is an isolated, reversible visual study stacked on [PR #585](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/585).

## The playable visual difference

The two source-faithful, cleaned creator portraits (Ender and Ionia) already render as 1-pose transparent characters on the actual Chapter One dock with P. This patch enhances **only** their opt-in presentation:

1. **Field scale:** from a 535px source resized at 0.18 (96.3px tall) to **0.21 (112.35px tall)**. Center is computed from the actual source texture height, keeping the sole at the existing actor's foot origin.
2. **Ground contact:** adds a five-layer subdued oval contact shadow under each creator-matte figure. The old approved-for-regression fallback shadow draw remains unchanged for non-preview actors.
3. **Cinematic source material:** native `CanvasItem` shader samples the actual creator texture and applies a restrained upper-left golden-hour tint and lower-boot ambient blue bounce. The shader is **not a baked new texture, not a replacement for correct art**, and never affects character collision or save logic.
4. **Native visual A/B:** press **P** on the dock to opt into creator-correct static source figures, then **L** to compare sunlight on/off. Press P again to restore the earlier walking sprites and their previous shadows. The existing **V** toggle controls the independent dialogue portraits. The source art stays private and is never supplied to public CI.

Neither user-supplied source PNG, full-body artwork, role, appearance, state/canon, movement physics, dialogue, recruitment, crew composition nor genuine flight landing was changed. The shader is deliberately subtle. No fabricated N/S/E/W views or synthetic gait cycles were added.

## Actual proof (independent of public code-only CI)

**Executable source head:** `e653f8b21fe9effb1f59c9ece601819208f4bcc0`. The subsequent CI/docs commits do not alter this rendered gameplay or material code.

**Windows device:** official Godot **4.7.2.stable**, Intel Iris Xe Graphics, OpenGL 3.3 Compatibility; original Ionia and Ender source-matte-v3 files installed in an isolated detached Git worktree, source SHA-256 validated in the existing script. The creator's normal desktop checkout is separate and unchanged.

| Check | Evidence |
|---|---|
| Headless import and shader validation | PASS |
| Grounded character source, foot-anchor, real `CollisionShape2D`, art rollback and keyboard P/L tests | **30 checks PASS** |
| Real native 960×640 GPU capture with the private Ionia and Ender mattes, sunlight on | PASS, PNG SHA-256 `397a7dbd6ce5affd484f4d9fab84c8dc5fbd7d8b2af84df0e14c88a23b2dfc0c` |
| Same exact native scene with sunlight off, through actual L input | PASS, PNG SHA-256 `e71da6c22b8942b9d5ddf806aa56a757319a812a7718a8c88907266e7ba2af2e` |
| Original fallback walk sprites | PASS, identical previous PNG SHA-256 `bd11c81f1bbc07db6760ae52579cf2da240d8b6ecc54b9f289d757a38cae3547` |
| Full First Wake genuine water contact, postflight control, save/resume and legacy save isolation | **48 checks PASS** |

A pairwise per-RGB-channel absolute frame comparison over 960×640 native screenshots (not concept art) produced:

- Ender character region (x410–475, y350–465): **0.146 mean RGB units**, with 2,726 changed individual RGB-channel samples.
- Ionia character region (x648–704, y350–465): **0.285 mean RGB units**, with 3,983 changed individual RGB-channel samples.
- Stable dock control region (x160–310, y397–485): **0.0 mean**, zero changed channels.

This establishes that the shader produces a small but real in-engine source-art effect, restricted to the opt-in character material. It does **not** establish independent aesthetic sign-off.

## Local custody / visual inspection

Three authentic native 960×640 PNGs, an SHA-256 `EVIDENCE.json`, and a before/after HTML gallery are saved privately at the creator's `Desktop/Aetherwake/Verification Sandbox/FirstWake-Contact-Lighting-20261028`. A double-click `SEE FIRST WAKE - Contact Lighting A-B` shortcut in the Aetherwake desktop folder opens them. The established `PLAY FIRST WAKE - Compare Character Art` shortcut launches the isolated test build with P and L available.

**No private source artwork or rendered screenshot is committed or released through this public repository.**

## Artist evaluation and future production

Although character portraits now render with improved contrast/grounding, **the field figures remain two static source poses (one per actor)**. There are **no separately authored north/south/east/west views, no true walking gait phases**, no finalized weapon/gear continuity and no approval against a realistic 2.5D environment. The geometry and textures on the current pier remain visibly less detailed than the creator's cinematic portrait references. These are independent art hold gates even though native tests pass.

Next prioritize true creator-faithful transparent four-direction source poses, physically grounded boot contact, six individually authored walking phases per direction, native moving screenshots and creator appearance approval. Avoid fake mirrored views, clock-only pose cycles or pulling rejected old SVGs into the approved art pack. Windows Defender/installer release approval remains separate; no merge or release authority was exercised.
