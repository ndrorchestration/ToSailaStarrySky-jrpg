# First Wake vessel identity and boarding entrance — authority reconciliation

Date: 2026-10-18
Status: CHARACTERIZATION / DESIGN-DECISION REQUIRED / NO CANON RETCON

## Verified narrative identity

- `README.md` introduces Ender aboard **the Aureate Wake**, the last solarpunk airship.
- `modules/character-canon.js` and `docs/CHARACTER_ART_DIRECTION.md` identify Ionia as captain and owner of the Aureate Wake.
- `modules/first-wake-opening.js` dock_walk says "The Aureate Wake waits ahead" and the following `berth_task` proceeds directly to fixing Ender's berth.
- `modules/world.js` describes the boarding destination as the Aureate Wake.

## Verified implementation identity

- `modules/first-wake-visual-stage.js` docks and renders the `AetherDragonflyVisual` hero craft for this opening.
- `docs/VISUAL_BIBLE.md` explicitly requires dock scenes to reuse `AetherDragonflyVisual` rather than draw a separate ship, and `docs/CHAPTER1_2_5D_REMEDIATION.md` specifies Dragonfly silhouette in the initial reveal and boarding approach.

## Unresolved equivalence

The reviewed records do not explicitly establish whether **Dragonfly** is (a) the Aureate Wake's vehicle design/class or nickname, (b) a visual-system shorthand to be renamed, or (c) another craft whose introduction is being conflated with the Wake. The strongest supported reading is that the Dragonfly rendering is intended as the *visual stand-in* for the vessel that the narrative calls the Aureate Wake, because both are assigned to the same exact scene; that is an implementation inference, not an authoritative canon naming equivalence.

DO NOT rename the Aureate Wake, replace the Dragonfly renderer, invent a second ship, change boarding progression, or assert an equivalence as established canon without creator approval.

## Creator decision / acceptance

1. Identify the intended canonical relationship between `Aureate Wake` and `Dragonfly` in one statement, naming the boarding craft.
2. Identify the boarding entrance on the admitted ship silhouette (port/starboard and approximate hull feature/position), with required clearance and occlusion order.
3. Approve a design direction for scene composition that makes the last step of Ender's dock-walk point visually to that entrance, not just toward a hull or docking rig.
4. Only then create a bounded, preview-only candidate with exact-head 0/4/8 screenshots, confirm human-scale landmark coherence and run the full automated Chapter 1 gates.
5. Preserve G4/independent player visual acceptance PENDING and field art NOT_READY until reviewed.

Related: draft PRs #288/#289, boarding readability issue #291.
