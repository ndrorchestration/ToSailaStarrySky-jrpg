# Five Lights — Godot character visual review board (candidate only)

Status: **IMPLEMENTED AS REVIEW TOOL / NOT APPROVED ART**. Built on the existing Godot Ender/Ionia art-research line; no gameplay, job, save, canon reveal, ship, or final field-pack changes.

## How to review

Open `godot/project.godot` in Godot 4.7.2, launch the First Wake pilot and press **L**. Press **[** or **]** to scrub six imported contact frames of Ender and Ionia. Press **L** or **Esc** to close; the live actors' physics are suspended while the board is open, and resumed afterwards. The test `godot/tests/character_lineup_review_test.gd` checks stage isolation, provenance, phase wrapping, and consistent return to the original actor coordinates.

The left-to-right order **Ionia · Ender · Aepex · Lyra · Reson** matches the creator's five-person reference identification; **this does not state party-recruitment order**. Existing review textures are sourced unchanged from `ender-south-detailed-staff-v2-candidate.svg` and `ionia-front-sixframe-candidate.svg`. They are **not** final art. Aepex, Lyra, and Reson are **gray faceless shape blocking**, not designed sprite frames; their shapes are illustrative hints at relative stature only, **not a locked height chart**.

## Creator-established identity and production checks

| Character | Innate story resonance | Visual continuity to enforce on production art |
|---|---|---|
| Ionia | Earth | 28, blonde shoulder-length curls, green eyes, capable young captain; study navy/white/gold outfit direction rather than generic farmer. |
| Ender | Spirit | 22, slender adult, short auburn/dark-copper hair, green eyes, brass green-lensed goggles, olive/cream field clothes, satchel, **full-length midpoint-wrapped staff with brass ferrules**. Creator-approved appearance reference is not approval of a movement atlas. |
| Aepex | Air | 27, second-tallest; lean/angular muscular posture, sharp undercut, visible tattoos, technical **and computing** literacy; final costume/weapon choices stay under review. |
| Lyra | Water | 24, **long red hair**, adult mother of Talen; **pink spirit-energy visual motif may coexist with Water**, but does not turn her into a generic priestess. |
| Reson | Fire | 25, tallest and broadest, youthful military-athletic weapon master; rifle-type firearm, pike and sword vocabulary; no made-up unit insignia. |

**Critical separation:** every protagonist carries innate plot resonance even when a chosen job/class/skill progression gives them **no usable spells**. The board records story identity, **not combat-elemental abilities or automatically awarded jobs**. The older character-art documentation has superseded unspecified traits: use `docs/CHARACTER_AND_ART_AUTHORITY.md` on `main` and creator Notion source before production admission.

## Remaining visual work / no false green

1. Compare live native atlas playback, original layered image source, proportional footing, occlusion and lighting against approved Ender likeness and Ionia identity. Six named frames are not gait acceptance.
2. Author Lyra/Aepex/Reson original **four-direction field sprites** and portrait turnarounds from reviewed design sheets. Preserve source layers, ownership/provenance, neutral poses and exact conversion receipts.
3. Test all five at intended 960×640 logical presentation, including their distinct silhouettes, highlights, hair/tattoos/accessories, environmental palette and accessible contrast. Capture **actual Godot frames**, not concept renders misrepresented as screenshots.
4. Review source/animation via creator signoff; retain draft status until that happens. No PR merge, release or promotion of silhouette placeholders.

Reference: [creator character and art authority](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/blob/main/docs/CHARACTER_AND_ART_AUTHORITY.md) and [visual bible](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/blob/main/docs/VISUAL_BIBLE.md).
