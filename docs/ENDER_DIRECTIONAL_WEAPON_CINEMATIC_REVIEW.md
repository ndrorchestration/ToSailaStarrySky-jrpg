# Directional Ender weapon & contact timing — isolated native visual review

**Authority:** Creator-approved appearance reference remains `godot/art-review/ender-approved-reference.png`, original SHA-256 `619517944ebe12b295bf5f780abb1a49bce2449230654fb8c49b11e8380546fd` (see `godot/art-review/APPROVED_ENDER_SOURCE_ALIGNMENT.md`). This branch **does not modify or replace** it. Existing east PNG, separate unmirrored west SVG, south SVG and north SVG are prior **unapproved directional walking candidates**, not accepted finished character or attack art.

## Implementation
- Standalone `godot/scenes/weapon_directional_cinematic_review.tscn` at native 960×640 for F6 review. Default Chapter I scene and saved data are unchanged.
- Independent layer `weapon_directional_character_review.gd` selects north/south/east/west art from the already-staged candidate files. All display **frame 0**. Animated battle poses are not fabricated from unrelated walking frames; modest transforms are review-only framing, not an animation deliverable.
- All referenced directional candidates include a drawn staff. In character mode, the original neutral mannequin and independently drawn geometric weapon are **hidden** to prevent double weapons. The mannequin and geometric staff remain available through a reversible one-button A/B.
- `weapon_cinematic_contact_review.gd` computes a smooth, bounded impact beat during the staffStrike *visual intent*. Peak zoom 2.2%, stage displacement under 3px, and a small noncanonical practice-target glint — no camera-axis flip, no gameplay hit, no damage, no enemy response, no HP update. Reduced motion removes framing movement and glints entirely.
- `weapon_training_contact_marker.gd` draws a purely optical, reduced-motion-safe practice target marker. Its `hitAuthorized=false` result never confers battle authority.

## Canon / gameplay guardrails
Current review bridge from draft PR #442 maps only **Ender + full-length staff + staffStrike** after checking Chapter I party and formula authority, and returns `combatCommandIssued=false`. No other party character, class, weapon or magical affinity is granted an attack. Story energy remains independent of chosen jobs. No plot revisions, new actor identity, sprite admission, actual weapon equip, encounter mutation, saves, network, release or merge.

## Native evidence
CI with digest-pinned official **Godot 4.7.2** rechecks original skill trees, previous choreography and the read-only battle adapter, then exercises directional art provenance and non-execution. It renders six actual 960×640 comparison shots: east, west, south, north at impact, reduced-motion east, and the mannequin fallback. Hashes of authoritative lossless PNGs are recorded in CI. A 3×2 *lossy*, downsampled contact sheet of these review candidates is written into private-ish job logs for visual inspection; frames are otherwise runner-only.

**Do not claim** source identity approval, directional animation art approval, combat animation authoredness, complete sprite atlas, production cinematography, player battle UI acceptance, publishable PNG delivery or Windows release proof merely because tests pass.

## Art acceptance and implementation next
1. Inspect the rendered 3×2 sheet against the verified creator-approved portrait: boots, staff grip, goggles, face, handedness and costume, at game-scale and 1×. Record direction-specific discrepancies.
2. Only then author *new distinct* physical attack pose sheets with per-body independent staff/hand attachment and layer order, preserving the approved character identity.
3. Add purposeful torso rotation, anticipation, contact, recovery, target reaction and subtitle-accessible non-audio cues with controlled tests.
4. Admit character-specific animation playback to actual combat only through a separate authority-gated dispatch integration and unchanged formula resource/turn accounting.
5. Resolve current authored Chapter I screenplay/party timing source conflicts before modifying any active scene. Windows Defender QA and creator release approval remain separate security/release gates.
