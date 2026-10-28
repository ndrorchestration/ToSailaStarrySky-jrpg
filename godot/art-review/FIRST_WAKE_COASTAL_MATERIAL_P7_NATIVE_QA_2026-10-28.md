# First Wake — Coastal material and pier-depth visual pass P7 (October 28, 2026)

**Status:** Rendered and measured in actual Windows Godot; production artistic acceptance **pending**; Windows installer/security **still on HOLD**. This is a review-only, stacked draft and is **not merged**.

## Visible change in the playable Chapter One introduction

Starting from verified creator-correct Ender/Ionia source-art rendering and the real painted coastal sky, the opening dock's **existing geometric deck** now receives deterministic visual detailing:

- Perspective-interpolated, golden-hour plank shading without changing the trapezoid coordinates or walking bounds.
- Distinct, bounded plank-grain strokes; subdued knots, wear scars, brass fastening points and material breakup.
- More textured mountain haze and fine reflections across the existing sea surface. No artificial terrain gate, sea navigation physics, collision, or ship/story capability is added.
- Player-facing **M** key toggles the refinements ON/OFF while in the dock. Original pier renderer remains the exact reversible fallback. **P** toggles the private source figures; **L** compares creator-figure sunset lighting; **V** compares dialogue portraits.

All detail is rendered directly inside the actual Godot `res://scripts/dock_depth_review.gd` `CanvasItem` using bounded deterministic draw operations, not a concept illustration or separate mockup. No source image is baked into, committed to, or modified by the new material pass. Full scene remains 960×640 and window-resizable as before.

## Exact tested code and source custody

**Native tested source head:** `849ea9c48ae91e493ccab4d0c75e6724ce67b731`. Follow-on workflow and documentation commits are code/test-output-only and do not change this rendered material implementation.

**Environment:** official Godot **4.7.2.stable.official.ed1daf0bf** on the creator's connected Windows development device, **Intel Iris Xe OpenGL 3.3 Compatibility**. The real, creator-supplied private Ionia/Ender JPEG portrait crops and alpha-cleaned source figure PNGs were present in a detached QA worktree; the user's original development checkout was not edited.

Authentic creator source-matte SHA-256:
- Ionia: `37d7cc3c852bbf5497e94e38502fb8aa35512f5492cf9a12abdf0eff49b11c49`
- Ender: `8127ec4b87086027887c145fbde72704c61ad1d20d44395b111b3145d98660ca`

The source-custody-gated `res://tests/capture_first_wake_dock_material_real_art.gd` is intentionally **local-only** (cannot pass public CI without private art). It loaded the actual flyer and Ionia dock interview and captured native 960×640 rendered frames, toggling M on/off with unchanged character positions, actual story/dialogue progression, and current creator art.

| Evidence | Verified result |
|---|---|
| Real native import and material-control test | PASS, 21 assertions |
| Creator art actor controls, provenance/fallback, collision and source-light checks | PASS, 30 assertions |
| Complete First Wake true water contact, postflight control, save/resume and legacy isolation | PASS, 48 assertions |
| Real rendered P7 pier/material ON (SHA-256) | `f4055868bc939f5faf6b3e797b4272a5bfb5b28167e259b3964443f986ffd36b` |
| Real rendered original pier/material OFF (SHA-256) | `397a7dbd6ce5affd484f4d9fab84c8dc5fbd7d8b2af84df0e14c88a23b2dfc0c` |
| Sampled material ROI (x172–802, y407–512), stride 3 | **5,726/7,350 changed samples**, mean per-channel normalized difference **0.02383** |
| Sampled true creator portrait ROI (x740–912, y155–335) | **0 changed samples** |
| Party, flyer, checkpoint, physics and scene | UNCHANGED in these native tests |

**Local Windows evidence:** `Desktop/Aetherwake/Verification Sandbox/FirstWake-Dock-Material-P7-20261028` contains both full native PNGs, checksum `EVIDENCE.json` and `OPEN-TRUE-GODOT-COMPARISON.html`. Desktop/Aetherwake shortcuts:
- `PLAY FIRST WAKE - Coastal Material P7` launches this detached Godot review checkout. During the dock, press **M**, **P**, **L** or **V**.
- `SEE FIRST WAKE - Coastal Material P7 Comparison` opens the native before/after art inspection page.

The art and screenshots are **private local user evidence**, not publicly pushed repo assets. Do not infer a publicly downloadable game installer from these shortcuts.

## Review limits and priorities

The new weathering helps the pier feel less uniformly flat, but the entire coast remains a stylized prototype. This does **not** constitute cinema-quality final environment approval. The current Ender/Ionia *field* figures are two true source-correct **static** poses, not original 4-way six-phase walking animations. The Aureate Wake ship, sea, interior engineering room, lighting/environment transitions, and later protagonist reveal gates require independent final art quality passes.

**Next actual quality work:**
1. Author transparent **four-direction** source-faithful Ender/Ionia poses and genuinely distinct walking cycles rather than mirrored/translated source stills; retain editor layers, provenance and visual review.
2. Refine coastline silhouettes, pier accessories and native scene composition while preserving interactable gates and collision widths; then compare actual engine captures and measured frame cost.
3. Only once appearance is approved, promote code/assets into main and build user-installable Windows release subject to separate Defender-on security acceptance.

**No merge, canon rewrite, asset-publication, installer release, or Windows Defender security boundary weakening was performed.**
