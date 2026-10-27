# Three-Protagonist Physical Walk Review — candidate only

**Date:** 2026-10-27. **Authority:** isolated Godot 4.7.2 technical field-motion proof. Stacked on Reson four-way draft #446, Aepex #439, Lyra #435, lineup #421/#409. Nothing from this review is admitted to canon, production gameplay, final art, recruitment progression, spells, equipment, save schema or export/release.

## Implemented contract

The separate `res://scenes/three_character_physics_walk_review.tscn` scene provides three **real CharacterBody2D** review actors (Lyra, Aepex, Reson). Press Space to begin a bounded closed 100+100+100+100 logical-pixel path with south→west→north→east views and independent authored 6-frame source atlases; Esc disables the route. Their displayed phase is `int(actual_physics_distance/12.5) % 6`. Each uses `move_and_slide()` rather than teleporting roots through timing-only animation. Only the isolated review scene loads this script, never Chapter One's First Wake main scene.

The review actors use a 6px circular foot collision shape, layer 2 / mask 1, with a separate StageTree unit-test obstruction using a real StaticBody2D on layer 1. A painted floor is **only** visual stage geometry; do not treat it as physics-verified terrain grounding or exact toe pixels.

## Evidence and falsifiability

`godot/tests/three_character_physics_walk_test.gd` checks opt-in default and source provenance; verifies that all three traverse four real directional legs and all six sprite phases per direction, bounded per-frame real world translation, total ~400 logical-pixel route length, uninterrupted unobstructed loop, bounded translation while a source atlas frame is held, and exact return-to-origin; then sets up a physically colliding StaticBody2D obstacle that must interrupt a separate Lyra actor and remain blocked. Stopping must reset phase and halt motion. This test prints measured displacement and held-frame translation, explicitly **not** certified foot plants.

`godot/tests/capture_three_character_physics_walk.gd` captures four actual 960×640 Godot OpenGL frames from the moving physics scene (one from each facing segment, with exact SHA-256 evidence). Inspection JPEGs are limited to 480×320 / 85KB and logged privately; original native-resolution PNGs remain runner-local pending an approved artifact-custody channel (GitHub Actions artifact quota issue).

## Human art and engineering gates still open

- Stillness and visual foot-ground cues under 1x scale; **pixel-identified planted-foot locations** are not established by atlas frame uniqueness, measured travel or contact circles. Evaluate stance/slide, arm swing, back hair/technology placement and ankle clearance in a true gameplay rendering.
- Artists must inspect actual 960×640 clips and all side/back transitions, including nonmirrored accessories, unapproved clothes and proportional continuity.
- Isolated test movement is **not** implementation of Lyra/Aepex/Reson as playable Chapter One actors; cannot unlock early party or change Ionia-first recruitment.
- Innate plot resonance remains independent of magic learned by jobs/classes. Lyra Water/pink spirit motif, Aepex Air, Reson Fire, all without automatically usable spells. Ender Spirit and Ionia Earth remain unchanged.
- No merge/release or creator character appearance approval without explicit authority.
