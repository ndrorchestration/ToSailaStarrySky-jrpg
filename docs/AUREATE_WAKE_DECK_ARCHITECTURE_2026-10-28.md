# Aureate Wake: maritime foredeck art and occupied sightline prototype

**2026-10-28 — G2 ART/PHYSICS STUDY — DRAFT, UNMERGED, NONCANONICAL DIMENSIONS**

This prototype stacks on the source-derived icosphere/railing collision study [draft PR #549](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/549) at exact parent `73446fd369082ee06d48028ca8a3db819edc1e6c`. It uses Godot 4.7.2 and does **not** add a playable 3D ship to the main Ionia-first Chapter I scene.

## Visual change: railings as ship architecture

The previous **26 box-mesh rail visuals** are hidden, but their corresponding existing `StaticBody3D` rail and infill collision shapes remain intact. An original, opt-in dedicated `AureateMaritimeRailArtReview` child draws:
- Gently swept dark-timber handrails, golden/brass uprights, patinated sea-glass-green cables and pale nautical tension braces. Port, starboard and nose have five thin rails at the same 0.18m increments as the real existing collider. This is **not** a new physically curved hull or marine-safe barrier design.
- Warm-metal archway trim framing the existing 1.24×2.10m **provisional** physical hatch, mounted outside the known 1.74m human-sized walk corridor.
- Original source-derived PR #471 icosphere shell and exact-source PR #482 native shader, preserving the existing review-only low-glare option and **no glazing collision, no pressure or weather rating**.

A QA-only `set_design_review_enabled(bool)` reveals/hides the legacy fence visually for A/B screenshots; it does not alter the collider layer, physical floor, door, saved game state or abilities. The old visuals and new artistic proposal cannot change the stage of production admission.

## Executable gate

`godot/tests/aureate_wake_deck_architecture_test.gd`:
- verifies 26 old mesh boxes are hidden and intact rail collision remains, art geometry built, and A/B change reversible;
- performs **actual Godot PhysicsDirectSpaceState3D shape-intersection checks** of *two separate adult-sized cabin crew stations*, helm center and foredeck center. These are **illustrative temporary stations**, not all-five-protagonist occupancy or Talen acceptance;
- casts actual physical side-rail rays at all five heights and view rays from helm to open bow at three provisional eye positions, then closed/open hatch sightline;
- instantiates actual Ionia-first playable Chapter I and confirms unchanged Ender-only opening party, save state and locked Resonance.

`godot/tests/capture_aureate_wake_architecture.gd`: **three authentic 960×640 Godot Compatibility software-GL frames**, same-camera legacy fence vs original maritime design, and a higher ship-wide perspective including geodesic dome. Requires measurable pixel changes, saves SHA256 receipts to the scoped native artifact.

The dedicated [CI workflow](../.github/workflows/godot-aureate-wake-deck-architecture.yml) verifies official digest-pinned Godot 4.7.2, native import, physics and GL. Inherited PR #549 ico physics, PR #540 source-identical shader, PR #531 real walking/hatch/camera and original Chapter I smoke must remain green. Windows QA retains the preexisting Defender custody policy.

## Not accepted

There is still no real crew animation/protagonist art, five-person complete layout, gameplay helm, true sealing, pressure hull, wing sweep collision, ship-motion hazards, certified handrail infill or ship-related narrative flags. The new art is a first pass meant to improve the visual language without weakening the proven collision. Physically correct guardrails for children and accessibility are **separate** verification needs. Creator chooses the final ship proportions, materials, character positions and aesthetics; the prototype cannot declare canon.

**Next gates:** inspect native images; refine the railing silhouette and deck volume without source drift, then review occupancy and actual dynamic camera inside authored geodesic dome. Only after creator approval and independent Chapter I gameplay QA may a controlled 3D transfer be proposed. No merges/releases.
