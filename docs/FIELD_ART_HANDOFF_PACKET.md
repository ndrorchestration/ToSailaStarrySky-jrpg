# Aetherwake Field-Art Handoff Packet — Ender + Ionia

Status: **PRODUCTION HANDOFF / NOT ADMITTED**
Tracking: Issue #207
Runtime contract: `docs/CHARACTER_ART_ASSET_CONTRACT.md`
Production brief: `docs/FIELD_ART_PRODUCTION_BRIEF.md`

## Purpose

Turn the Ender + Ionia field-art lane into an artist-ready assignment with no ambiguity about frame count, pose intent, grounding, runtime scale, or admission. This packet does **not** authorize either character as field-ready.

## Non-negotiable export contract

Each frame occupies a transparent **64×96** cell. Keep the grounded foot line identical across every action and every frame. Do not bake in shadows, UI, labels, scenery, camera effects, glows, or dialogue elements.

| Action | Frames | Strip size | Playback target |
|---|---:|---:|---:|
| idle | 8 | 512×96 | 8 fps |
| walk | 6 | 384×96 | 10 fps |
| talk | 4 | 256×96 | 6 fps |
| focus | 6 | 384×96 | 12 fps |
| attack | 8 | 512×96 | 15 fps |

Use nearest-neighbor-safe pixel construction. Hair, accessories, coat hems, staff/tools, and feet must not cross a cell boundary.

## Runtime framing target

The art is judged inside the actual 960×640 game, not as an isolated sprite sheet.

- Ordinary field presentation: readable without dominating the authored environment.
- Dialogue staging: field sprites remain secondary to portrait and dialogue hierarchy.
- Combat: silhouette must remain readable against bright sky and detailed arena plates.
- Character height and foot line should remain stable enough that changing actions does not create visible vertical popping.
- Preserve clear negative space around head, hands, and signature equipment.

## Ender identity lock

Canonical requirements:
- age 22;
- slender-to-average build; not especially brawny;
- compact scholar-traveler silhouette rather than a battle mage;
- anxious/idealistic/intellectually oriented read;
- practical shipboard clothing;
- **very short dark copper-brown/auburn hair**;
- **bright green eyes**;
- light freckles;
- brass/bronze forehead goggles with green lenses;
- the creator-approved olive/green + tan/cream field-scholar clothing language from the selected reference;
- resonator staff or scholarly instrumentation may support the silhouette;
- avoid bodybuilder proportions, wizard robes, generic battle-mage posing, dark medium-length/tousled hair, or hazel/light-brown eye substitution.

### Ender frame direction

**Idle — 8 frames**
1. neutral grounded stance;
2. small inhale / shoulder rise;
3. settle;
4. slight weight shift toward lead foot;
5. goggles/head micro-turn;
6. return through center;
7. coat/strap secondary motion;
8. clean loop back to frame 1.

**Walk — 6 frames**
1. contact, lead foot forward;
2. weight acceptance;
3. passing pose;
4. opposite contact;
5. opposite weight acceptance;
6. opposite passing pose.
Keep the staff/instrument close enough to avoid silhouette noise but allow one readable secondary-motion arc.

**Talk — 4 frames**
1. listening/neutral;
2. restrained hand or head emphasis;
3. speaking emphasis;
4. return toward listening.
Ender should look thoughtful rather than theatrical.

**Focus — 6 frames**
1. plant feet;
2. attention narrows;
3. bring instrument/staff into working position;
4. peak concentration;
5. controlled release;
6. settle.
No generic spell-casting flourish.

**Attack — 8 frames**
1. anticipation;
2. load;
3. committed forward motion;
4. strike/release;
5. peak extension;
6. recovery begins;
7. regain balance;
8. return toward idle.
Keep the action practical and character-specific rather than a large heroic fighter pose.

## Ionia identity lock

Canonical requirements:
- age 28;
- captain and owner of the Aureate Wake;
- experienced young-adult captain/navigator with command posture;
- navigation, sky-lane, and Core expertise;
- blonde shoulder curls and structured gray/black tailoring consistent with the admitted portrait authority;
- elegant feminine silhouette without losing practical command presence;
- avoid elderly presentation, farmer archetype, or invented spellcaster identity.

### Ionia frame direction

**Idle — 8 frames**
1. composed command stance;
2. controlled inhale;
3. slight coat/hair motion;
4. weight shift;
5. horizon-check head turn;
6. return through center;
7. subtle hand/equipment adjustment;
8. clean loop.

**Walk — 6 frames**
Use the same contact/pass structure as Ender, but with more deliberate stride, upright torso, and command economy. Shoulder curls and coat edges may carry restrained secondary motion.

**Talk — 4 frames**
1. attentive neutral;
2. concise command gesture;
3. speaking emphasis;
4. return.
Avoid exaggerated gesticulation; Ionia should read as someone used to being heard.

**Focus — 6 frames**
1. assess;
2. orient to instrument/horizon;
3. engage navigation/Core tool;
4. peak diagnostic attention;
5. confirm;
6. settle.
This is technical/captain focus, not spellcasting.

**Attack — 8 frames**
Until a final weapon is canonically established, keep the animation compatible with a practical defensive/tool-based action and avoid silently defining a permanent weapon. The silhouette must not imply a spellcaster identity.

## Cross-strip continuity checklist

Before export:
- same head height and body scale across all strips;
- same palette and costume colors;
- identical foot baseline (validator permits at most 1px total variance across the character pack);
- at least 1px horizontal/top clearance from every 64×96 cell edge; no frame clipped by cell edge;
- no accidental one-pixel outline-color drift;
- goggles/hair/shoulder silhouette recognizable at runtime scale;
- transparent alpha outside the sprite;
- no embedded shadow;
- no anti-aliased fringe against transparency;
- action transitions do not visibly resize the character.

## Review sequence

1. Produce a **single-frame silhouette proof** for Ender and Ionia before animating all 32 frames per character.
2. Review those proofs beside the current authored dock, cabin, dialogue, and combat evidence.
3. Only after silhouette approval, animate the five strips.
4. Export the ten exact PNG strips.
5. Run `npm run verify:field-pack-readiness:strict`. This verifies production-file completeness **before** any manifest promotion, including exact dimensions/alpha plus cell-edge clearance and ≤1px grounded-foot-line variance within and across actions.
6. Regenerate exact-head runtime evidence and compare against the provisional bridge art at actual runtime scale.
7. Run the human silhouette-recognition check using `docs/FIELD_SILHOUETTE_RECOGNITION_KIT.md` with at least 5 independent participants and require ≥80% overall correct identification.
8. Generate the per-character receipt skeleton with `npm run prepare:field-art-admission:ender` / `:ionia`. The generator requires a clean exact-head worktree, hashes all five production strips plus the exact visual-evidence manifest, and writes `assets/characters/v1/admission/<character>.json`. Then complete the still-PENDING human/runtime fields from actual evidence. The runtime receipt must separately show PASS for the visual suite, browser route + replay, exact-head evidence capture, visual performance, and before/after cohesion review.
9. Only after mechanical completeness, runtime review, and silhouette evidence pass, change the manifest status to `ready` / `field-ready`.
10. Run `npm run verify:field-pack-admission` as the post-promotion fail-closed admission check.
11. Re-run Chapter 1 visual/browser/performance verification and regenerate final exact-head evidence.
12. Run the broader human/player G4 acceptance procedure separately; field-art admission does not close G4.

## Required filenames

`assets/characters/v1/ender/field-idle.png`  
`assets/characters/v1/ender/field-walk.png`  
`assets/characters/v1/ender/field-talk.png`  
`assets/characters/v1/ender/field-focus.png`  
`assets/characters/v1/ender/field-attack.png`

`assets/characters/v1/ionia/field-idle.png`  
`assets/characters/v1/ionia/field-walk.png`  
`assets/characters/v1/ionia/field-talk.png`  
`assets/characters/v1/ionia/field-focus.png`  
`assets/characters/v1/ionia/field-attack.png`

## Admission boundary

A visually appealing sheet is not sufficient. The pack remains **NOT READY** until file dimensions, alpha, canon identity, runtime readability, regression tests, exact-head evidence, performance, and human acceptance gates are satisfied.

`AETHERWAKE_FIELD_PACK_READINESS=NOT_READY` remains the controlling state until those gates are met. Mechanical completeness may reach `COMPLETE_NOT_PROMOTED` before admission; that intermediate state is intentionally non-authorizing.


### Provenance rule
Do not edit, optimize, recompress, crop, or regenerate an admitted strip after its review receipt has been created. Any byte change produces a different SHA-256 and intentionally invalidates the receipt until the new artifact is reviewed and rebound.


### Exact-head finalization rule
The receipt records the reviewed candidate head. Admission may then be committed exactly once as a **bounded child commit** containing only the character admission receipt(s) and manifest-state transition. That one child is mechanically permitted; unrelated or later commits are not. Exact evidence-manifest bytes must remain unchanged.


## Ender creator-lock update — 2026-09-28
The corrected visual montage was approved by the project owner after specifically correcting Ender's hair and eye color. For production field art, treat **very short dark copper-brown/auburn hair** and **bright green eyes** as locked likeness traits. These supersede older contradictory references that described Ender's eyes as hazel/light-brown or depicted darker/tousled hair.

This approval locks identity direction only. It does not itself admit any field strip, close G4, or change `AETHERWAKE_FIELD_PACK_READINESS=NOT_READY`.
