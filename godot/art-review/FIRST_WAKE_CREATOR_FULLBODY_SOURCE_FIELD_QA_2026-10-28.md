# First Wake — Original full-body field-scale review (October 28, 2026)

**Status:** exact creator artwork **rendered in native Windows Godot**, technical opt-in swap PASS, static art **UNAPPROVED** for production animation, unmerged. This is the next step after the high-fidelity Ender/Ionia portraits and painted dock sky.

## Artist identity and source custody

The user explicitly rejected the older provisional four-way Godot sprites. The replacement visual target is the supplied **Five-Character Fantasy Expedition Concept Sheet**, with the correct protagonist mapping: Ionia = blonde naturalist captain, Ender = green-goggled inventor/Rift Scholar. Captions printed in the source illustration are not gameplay class changes.

Two **private transparent 1-pose** figures were extracted from the creator-supplied 1672×941 concept sheet using a reversible offline OpenCV GrabCut script in the creator's Windows *Aetherwake / Verification Sandbox*. Unlike the prior anime placeholders, these show correct full-body outfit silhouette, facial identity and accessories. They are exported to the isolated Godot worktree only:
- `res://art-review/creator-field-review/ionia_field_static_review.png` (205×535 RGBA, native file SHA-256 `a37f1cde79fbee7b70d2f25ad9b1625fac1c8340f9c162b54f9333491d203f84`)
- `res://art-review/creator-field-review/ender_field_static_review.png` (199×535 RGBA, native file SHA-256 `7d95d72e6d8953b0db594511cb2705947925363025e737d2710bc247ee43ec4b`)

**The PNG images are not committed to public GitHub**; source files remain on the creator's Windows device. Some extracted edges still need hand-cleanup. No new art is claimed to be from a final animation sheet.

## Playable behavior — opt-in P key

The real First Wake dock actors are still the original `CharacterBody2D` instances; press **P** on the dock to switch both characters to locally available creator-art full-body static standees. Press **P** again to restore old walking visuals. Text clearly identifies this as **STATIC** with no authored gait. Missing PNGs fail closed, preserving the existing field art. Hidden old directional sprites are not mirrored, repainted or deleted. The original gameplay launch is unchanged. When the player moves with the static study enabled the standee follows real physics, but its legs **do not animate**. This is a quality **reference-proportion** study; it is not an approved walking sprite.

## Exact native evidence and boundaries

- Windows isolated worktree code head **`909d7dc3b9b6d5a72e28e27f0f954b3c49184ecc`**.
- Official Godot 4.7.2 Windows OpenGL 3.3 Compatibility on Intel Iris Xe, authentic 960×640 screenshots.
- Native static art toggle regression **PASS (14 checks)**, native full First Wake real water/saves regression **PASS (48 checks)**, source-image import and render PASS.
- Full source-cutout screenshot SHA-256: `3c64c6aa1f7a973e5680a4109265ccbb661ac285a61c96fbeb855dc55b24a90e`.
- Exact rollback old-walker screenshot SHA-256: `bd11c81f1bbc07db6760ae52579cf2da240d8b6ecc54b9f289d757a38cae3547`.
- Actual two-frame comparison HTML, SHA custody receipts, offline extractor script and local Windows launcher shortcuts are saved in the creator's *Aetherwake / Verification Sandbox / FirstWake-Field-Art-Comparison-20261028* folder. This **does not publish** the artwork to GitHub, alter the original desktop worktree, or change the First Wake save.
- Official source-optional Godot CI independently compiles and checks that missing private artwork cannot break play. The local real-art screenshots are distinct evidence from synthetic/no-image CI.

## Why this is not a production FIELD_PACK

There are **two static source poses total (one per protagonist)**. There are **no new separately authored N/S/E/W poses**, and **zero authored walking animation frames**. No developer should report these as 4×6 animated atlases or as an approved field-art replacement. Proportions/hair/costume are now a far better match to the visual reference, but at 960×640 the field figures are smaller than the cinematic portraits and the painterly cutout edges/photographic shading contrast with the simpler dock.

## Next required visual promotion

1. Hand-clean the alpha cutout silhouettes and judge native boot planting, shadows and source-size visibility independently.
2. Author **genuine distinct transparent** south/north/east/west art and at least six convincing walking phases per orientation. Align with the *correct* source identities, not the old SVGs. Preserve each edit's original source and author/review notes.
3. Once animation source custody and creator appearance approval pass, move from the **P opt-in** preview into canonical First Wake character render code, retaining the real story/physics/save tests.
4. Improve coastline/pier material fidelity and render again with the revised moving actors.
5. Windows installer/Defender and publication remain independent security/release holds. Nothing merged, published or canon-changed by this branch.
