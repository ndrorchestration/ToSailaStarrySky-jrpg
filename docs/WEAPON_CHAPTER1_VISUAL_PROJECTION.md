# Chapter I — weapon visual projection (native review pass 3)

**Status: IMPLEMENTED READ-ONLY SCENE INTEGRATION / NOT ART ACCEPTANCE / NO NEW WEAPON EQUIP FEATURE.**

## Grounded authority

- Native Chapter I has a current **Ender** production-formula subset: `staffStrike`, `uncoverTruth`, `hold`, `rest`; Lyra and Ionia have no authorized actions in this review contract.
- The presently documented Ender weapon silhouette is a full-length, straight staff with midpoint wrap and two ferrules.
- Review-only staff/sword/pike/rifle catalogs and their physical skill tree proposals must not expand Chapter I combat authority.
- Plot-character affinities remain independent of jobs, levels, spellcasting and weapon discipline.

## Integration

- `weapon_battle_visual_projection.gd` is a pure, read-only bridge from **already-accepted** Ender formula actions to the existing choreography sampler.
- `weapon_battle_visual_chip.gd` draws the **actual current equipped staff identity** inside `first_wake_chapter1_review.tscn`'s existing battle overlay. The staff silhouette source is shared with mastery and choreography previews.
- The Chapter I scene calls the projection **only after** the existing actor authority check and formula resolver return successful `staffStrike`. It displays an `attack` frame sequence, returns to `idle`, and does not grant new abilities.
- `uncoverTruth`, `hold` and `rest` retain neutral staff presentation. Rejected actions and no-charge strikes do not replay weapon animation.
- The visual panel is hidden during exploration, after closing an encounter, and after loading any durable save. No serialized visual state, new input bindings, formula edits or encounter state changes.
- Reduced-motion visual frames can be driven by `set_weapon_visual_reduced_motion(bool)` in the native review scene. A final UX settings binding remains future integration work.

## Important distinctions

This provides **battle-scene equipment representation and an accepted action animation** for the one currently known authorized actor/weapon pair. It does **not** implement equipping a new weapon on Ender, assign weapons to Lyra/Ionia, migrate an inventory system, or grant proposed weapon-tree skills as executable actions. The standalone 4-family choreography lab remains where alternate equipment is reviewed independently of the canonical scene.

The visualization intentionally uses **geometric draft art**, not approved character-specific directional animation. The existing actor presentation and directional Ender review assets remain unchanged.

## Test and rendered evidence

The extended pinned Godot 4.7.2 workflow exercises:

1. Existing 12-skill mastery contracts and 16 family/action choreography combinations.
2. The real Chapter I scene with Ender's equipped staff: idle -> accepted strike -> impact -> idle; unauthorized skills, invalid loadouts and depleted charges rejected; reduced-motion constraints; save/cancel isolation; actual Wind Shear battle entry.
3. Six actual 960×640 OpenGL/Xvfb frames: normal formula ready, formula impact, formula reduced impact, formula closed, authored Wind Shear ready and Wind Shear impact.
4. Existing project regression workflows separately.

A capture hash difference proves **frame distinction**, not that a screenshot has been visually inspected or that its art is acceptable. Keep producer-art assessment and Windows security/environment acceptance independent. Runner-only captures are not published when artifact storage is restricted.

## Next prioritized slice

- A provenance-resolved, explicit art layer/pivot contract per established Ender direction; build directional staff-hand attachment **without changing approved source art**.
- Render hit/action events only from the authorized formula bridge and add exact boundary tests (one successful resolution -> at most one visual trigger).
- Verify camera framing, overlap, pixel readability, accessibility, and performance on native builds; add real manual visual review.
- Propose a separate backwards-compatible equipment slot/save migration only after ownership, class rules and creator decisions are reconciled.
