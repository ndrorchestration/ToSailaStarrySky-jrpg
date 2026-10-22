# First Wake Chapter I world-depth visual review — 2026-10-22

**Exact runtime/evidence source:** `378d7d0f46c31588307007faad8817341f8a8dc5`  
**Viewport:** 960×640  
**Status:** engineering visual review only. Creator visual acceptance and external player acceptance remain **PENDING**.

## Verification
At exact runtime source `378d7d0f...`:

- Chapter I world-depth presentation contract: PASS
- Chapter I presentation contract: PASS
- full Playwright smoke: PASS
- fresh seven-frame player-evidence capture: PASS
- capture manifest browser errors: none

All previously verified Chapter I gameplay-state behavior remains intact in the smoke suite.

## What changed

### Wake Dock
The map remains the same 32×32 authored/collision world. This pass changes presentation only.

- terrain gets deterministic color/value variation instead of a uniform tan field;
- floating-reach collision rim now reads as a darker cliff/edge rather than generic wall tiles;
- debris crates receive shadow, face detail, and small aether-status accents;
- the player and NPC sprites are modestly enlarged **only during rendering**; collision coordinates are unchanged;
- Ender's world staff retains a distinct side carry with brass ferrule accents;
- a central plaza ring makes the spawn/handoff position easier to parse;
- Wakeheart's berth receives visual-only rail/pylon staging;
- worn curved routes visually connect the central plaza to the four authored contact positions;
- labels identify **WAKE DOCK** and the **AUREATE WAKE // BERTH** without adding new quest/canon state.

The first attempt used per-tile horizontal highlights and straight contact routes. Fresh screenshots showed those as repetitive striping and an artificial X. Both were removed before this candidate: highlights are now sparse/deterministic and routes use curved Bezier geometry.

### Combat stage
Combat mechanics and resolution are unchanged. Rendering now deliberately stages the fight instead of inheriting the tiny world-map coordinates.

- Ender is placed on the left side of a raised berth combat plane;
- the enemy is placed opposite and rendered at a larger readability scale;
- the background has layered storm sky, cloud banks, horizon light, deck perspective, seams and grounding shadows;
- the scene retains location identity as **WAKE DOCK // STORMFRONT EDGE**;
- Ender's combat representation is a grounded coat/boots/face silhouette rather than a generic glowing orb;
- his staff is visually separated from the body with brass ferrules and aether glow;
- the staff-charge effect is repositioned beside staged Ender rather than hidden under the left HUD.

## Direct screenshot findings
Compared with PR #335:

- the Wake Dock frame has more spatial hierarchy and recognizable sub-areas;
- the player and contacts are easier to find at native 960×640;
- the world is still unmistakably prototype pixel art, but no longer reads as one flat undifferentiated field;
- the combat frame now reads as a two-sided encounter with visible stage depth;
- Ender is clearly visible in the encounter rather than largely lost behind the HUD;
- the Sky-Predator remains fully visible and unobstructed.

## Boundaries
This pass does **not** establish:
- creator visual acceptance;
- final character-art acceptance;
- final environment art;
- production 2.5D rendering;
- completed Godot migration;
- external player fun/beauty/inspiration validation;
- public release authorization.

The terrain, characters and combat subjects remain procedural/prototype art. The intended next art-quality jump is a real native sprite/environment pipeline, not endlessly polishing these primitives.
