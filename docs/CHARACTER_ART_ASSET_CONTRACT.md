# Aetherwake Authored Character Asset Contract — V26

Status: **INTEGRATION CONTRACT ESTABLISHED / ASSETS NOT YET AUTHORIZED**

Purpose: close the remaining character-quality gap without silently replacing canon or coupling art production to gameplay logic. The current articulated renderer remains the runtime fallback until a character pack reaches `ready` and passes all gates below.

## Canon authority

The five protagonists are **Ender, Lyra, Ionia, Reson, Aepex**. The canonical Drive visual-bible references control silhouette, costume language, hair, accessories, and relative build. Legacy polished atlases that conflict with those references are not admissible substitutes.

## Required portrait package per character

- `portrait-atlas.png` — 768×512.
- Cell: 256×256.
- Layout: 3 columns × 2 rows.
- Expressions in order: neutral, talk, concern, focus, hurt, smile.
- Transparent background.
- One consistent key-light direction and head scale across all five characters.
- Eyes, hair mass, face shape, signature accessories, and costume neckline must remain canon-identifiable at 96px displayed height.

## Required field package per character

Frame cell: **64×96** transparent PNG. Separate horizontal strips avoid wasted atlas space and allow exact animation counts:

| Strip | Frames | File dimensions | Target playback |
|---|---:|---:|---:|
| idle | 8 | 512×96 | 8 fps |
| walk | 6 | 384×96 | 10 fps |
| talk | 4 | 256×96 | 6 fps |
| focus | 6 | 384×96 | 12 fps |
| attack | 8 | 512×96 | 15 fps |

All strips must share the same grounded foot line, character scale, palette, and camera orientation.

## Character silhouette requirements

- **Ender:** compact field-scholar; goggles; green/tan vest; focused stance.
- **Lyra:** lighter build; long red hair; layered rust/cream drape.
- **Ionia:** composed captain/engineer; blonde shoulder curls; structured gray/black tailoring.
- **Reson:** broadest silhouette; light shirt; red scarf/cap; heavy harness.
- **Aepex:** narrow dark industrial silhouette; asymmetry, tech rig, undercut/tattoo cues.

## Acceptance gates

A pack may change from `planned` to `ready` only when:

1. all declared PNGs exist and match the manifest dimensions;
2. no legacy off-canon atlas is used as protagonist authority;
3. five-character black-silhouette recognition reaches **≥80%** correct identification in a small human check;
4. portrait identity remains readable at the actual dialogue-box display size;
5. Chapter 1 visual suite and browser route remain green;
6. exact-head capture is regenerated and performance remains inside current budgets;
7. before/after evidence shows the authored pack improves character quality without reducing scene cohesion.

## Runtime integration rule

The current `modules/character-renderer.js` is authoritative until a manifest entry is explicitly `ready`. Integration must be fail-safe: missing or invalid authored art falls back to the procedural renderer rather than breaking Chapter 1.

## Promotion order

1. Ionia portrait pack → representative dialogue quality gate.
2. Ender portrait + field pack → protagonist visibility in world/combat.
3. Reson / Aepex / Lyra packs → lineup and future party surfaces.
4. Full five-character exact-head and human silhouette review.

This contract exists so the next visual improvement is an actual asset-quality tranche rather than another round of procedural-detail accumulation.
