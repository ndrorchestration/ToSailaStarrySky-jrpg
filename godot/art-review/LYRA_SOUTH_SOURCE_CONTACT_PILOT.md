# Lyra — south-facing source-geometry foot-contact pilot

**Status:** Original unapproved source-art annotation, not animator-certified planted feet or final gameplay art. Built on draft PR #474. All Chapter I chronology, Lyra's Water plus pink-spirit visual motif, selected jobs, and existing character assets remain unchanged.

## What was authored, and what was not

The six-cell Lyra south SVG has two separate dark-boot silhouette paths in **each** phase. This pilot reads those original editable polygons and **manually places two candidate interior shoe contact points per frame** in their original SVG path coordinates. The exact established inner path transform is `translate(8,24.6) scale(0.8)`; the source frame is 80×128 px. This creates **12 source-geometry annotations**, not the previous half-image-centroid approximation. The data tentatively calls screen-left Lyra's anatomical *right* shoe and screen-right her *left* shoe, and offers two-phase right/left contact windows (0–1, 3–4), leaving phases 2/5 undefined.

This mapping is **not creator-approved anatomical stance**, particularly under rotation or nontrivial perspective. It is a more grounded source-backed candidate with exact coordinates and palette checking, intended to accelerate the artist's review. No source SVG is modified, no sprite X-offset is applied, and no physical contact or toe pinning is faked.

`godot/scripts/lyra_south_source_contact_proposal.gd` contains the original SVG boot-polygon candidates and transforms. `lyra_south_source_contact_overlay.gd` displays an opt-in pink world-space drift tether while the actor actually walks south. Open `three_character_physics_walk_review.tscn`; press **Space** to walk and **T** for Lyra's proposed shoe paths. T is independent of **P** (raw alpha support) and **K** (screen-half hypotheses). All diagnostic toggles default OFF.

## Native fail-closed gates

`godot/tests/lyra_south_source_sole_audit_test.gd` requires: original exact Lyra SVG path, all 12 points rasterize to nontransparent boot-colored pixels; source-pixel position close to the existing alpha support region; explicit unapproved flags; invalid phase/foot/character rejection; real Godot south-direction movement producing measured candidate-contact drift; overlay toggling leaves the original physics/world and other debug modes untouched.

`godot/tests/capture_lyra_south_source_contact.gd` runs real Godot physics, freezes three actors at an identical physical tick and source-frame index, then captures **two original 960×640 Godot OpenGL screenshots** with markers ON/OFF. Both original PNG SHA-256 hashes and bounded private crops are logged; full native images remain runner-local because of the existing artifact quota.

## Next artist decisions

1. Review original boot silhouettes and decide anatomically correct named feet, true stance intervals, and which heel/toe should be tracked in all six source poses. **Do not extrapolate this south-only mapping to west/north/east.**
2. Align source pose contact-motion with physics stride and reauthor legs/boots if stance-window displacement is excessive. Re-run exact-head physical world-slip and native screenshots; a visual-only source anchor test does not certify gait.
3. Add lead-in/out motion, four-view continuity, proper sound/contact effects, accessibility motion settings, and player-scale visual QA before gameplay admission.
4. Preserve Lyra's Chapter One recruitment order, innate Water plot energy and optional learned magic. No merges, releases or final art approval.
