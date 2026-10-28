# Magic VFX environment lighting — native review v0.3

**Status:** IMPLEMENTED isolated 2D Godot look-development study; **ART NOT APPROVED, GAMEPLAY NOT INTEGRATED, RELEASE HOLD**.

**Evidence source:** `feat/godot-magic-vfx-showcase-20261027` at executable source commit `9b1f43291060f589b3d8c9fd6618496a36500d75`, stacked on draft PR #411. This is not a merge into Chapter I or the planetary renderer.

## Established creative boundaries

Creator-approved protagonist narrative energy remains **Ender—Spirit; Lyra—Water with pink spirit-light; Ionia—Earth; Reson—Fire; Aepex—Air**. Energy identity is independent of magic classes/jobs, spell entitlement and battle execution.

This study does not expose hidden narrative locations, grant magic mastery, change dialogue, touch saves, change physics collision or mutate battle status effects.

## What the scene actually draws

Run `res://scenes/magic_vfx_environment_review.tscn` in the **Godot 4.7.2** project.

- Real GPU `PointLight2D` with procedural radial `GradientTexture2D`; color tracks the selected protagonist, capped intensity. The lighting affects a neutral stone witness swatch.
- Real `LightOccluder2D` with `OccluderPolygon2D` on a stone foreground column; draw-over ordering blocks portions of the spell behind the column. This is *CanvasItem* layering, not a 3D depth buffer or volumetric raymarch.
- The existing original five-sigil VFX scene remains the reuse source, with explicit static cinematic phase seeking and reduced motion default ON. Geometry is review-only, not canon geography.
- Keys: **1–5** affinity; **LEFT/RIGHT** cinematic phase; **L** light; **O** foreground/occlusion; **M** reduced motion; **ESC** exit.
- No screenshot postprocessing, broad exposure flashes, intrusive shake, third-party assets or source sprite mutation.

## Actual native evidence and defect lineage

- [Godot 4.7.2 native scene and smoke checks](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/actions/runs/40595540142) **PASS** at `9b1f43291060f589b3d8c9fd6618496a36500d75`, including `STARRY_SKY_MAGIC_ENVIRONMENT_PASS`.
- [Godot GL Compatibility real-frame capture](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/actions/runs/40595540149) **PASS**, including `STARRY_SKY_MAGIC_ENV_CAPTURE_PASS`. The renderer wrote **10 960×640 native PNGs**: five affinity-lit compositions, foreground baseline, foreground absent, shadow casting absent, light absent, and a deterministic impact frame. Every image has a SHA-256 in the job log.
- The native comparator verified **different pixels** when toggling physical light, foreground draw-over, and shadow casting at their respective controlled witness regions. This establishes observable Godot 2D image differences, not visual quality or physical accuracy of all spells.
- Initial study commit `7003f851` failed native QA: the occluder test incorrectly treated inherited CanvasItem visibility as the local `visible` property; a neutral swatch placed under a light/shadow setup yielded no observed light difference. Fixed with inherited visibility checking and an unobstructed direct-light witness in `37dab999`. Cast-shadow A/B was added and verified in `9b1f43291060f589b3d8c9fd6618496a36500d75`.
- Original source SVG assets remain review candidates; screenshot files are runner-local because Actions evidence artifact distribution is constrained by existing quota/custody. Hashes alone do not make images visible for creator art approval.
- Separate exact-Windows-QA may fail its unchanged **Defender real-time protection preflight**. Preserve that independent security hold; no releases were produced.

## What is not verified

No actual 3D light, collision-aware spells, terrain-normal mapping, full 2.5D occlusion with actors, camera choreography in Chapter I, shader effect on planetary curvature, hardware FPS/VRAM, frame-time budgets, final spell timing/audio or art acceptance. Those are distinct next-stage gates.

## Next reversible integration experiment

A *new isolated review branch* can attach the visual-only adapter to a noncanonical dummy encounter or neutral Chapter I testing prop, under a real camera. Confirm deterministic position/depth projection and measure rendered readability against static actors with one real native capture per affinity. Keep the existing combat authorization and narration-energy boundaries fail-closed; do not wire actual spell execution or story resonance to these preview visuals by default.
