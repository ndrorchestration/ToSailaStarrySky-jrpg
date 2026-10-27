# Reson independent four-direction field-art study — candidate v1

**Status:** Art-review-only candidate, not accepted production sprites, animation, costume, weapon choice, playable battle actor or a story/element change. Stacked on Aepex #439 and Lyra #435 (ultimately the creator five-character preview #421).

## Source art

The existing south atlas `reson-south-sixphase-v1-unapproved.svg` is unchanged. Three original, editable SVG sources are authored at 480×128 (six 80×128 frame cells):
- `reson-north-sixphase-v1-unapproved.svg` — broad back/shoulder geometry, consistent shorter hair and military-athletic field gear without invented insignia.
- `reson-west-sixphase-v1-unapproved.svg` — distinct left-facing anatomical profile, original pads and glove/boot stance.
- `reson-east-sixphase-v1-unapproved.svg` — independently constructed right-facing profile, not a flipped texture.

Creator-locked identity: Reson is 25, tallest, strongest-looking, young, confident, weapon-master with fire as **innate story resonance**, whether or not the player develops combat magic. Do not portray him as old, frail, or a magician by default. The armored field clothing is a provisional art motif rather than an official uniform, military institution or equipped signature weapon.

## Controls / verification

In the isolated Godot 4.7.2 First Wake review stage, press L. Use **J** to cycle Reson's south → west → north → east. **H** cycles Aepex, **F** cycles Lyra, [ / ] scrubs shared pose phase, M toggles magnified/native-source scale, L/Esc closes. No additions to playable combat, dialogue, world navigation or saved-state contracts.

`godot/tests/reson_fourway_review_test.gd` checks unique original source names, actual 480×128 Godot imported textures, four directions × six distinct baked frame pixels, absence of sprite horizontal mirroring, visibility exclusivity, phase synchronization, review zoom, invalid-input handling and physics-safe return to the dock.

`godot/tests/capture_reson_fourway_review.gd` captures four actual 960×640 native Godot OpenGL screenshots at an identical anchor and animation phase, with derived bounded log inspection crops. Original full screenshots stay runner-local where GitHub Actions artifact quota prevents delivery.

## Acceptance gates

The 4×6 atlas contract does **not** certify a planted-foot walk, equipment transitions, performance at 960×640, character art quality or final likeness. Examine all directions for coherent short hair, head depth, hands, shoulder volume, proportions against Aepex and Ender, no perspective distortion or armor/interpenetration. Require actual physics-driven gait, native screenshot comparison, source custody and explicit creator visual approval before any field-pack promotion. This review does not change combat affinity or automatically grant spells.
