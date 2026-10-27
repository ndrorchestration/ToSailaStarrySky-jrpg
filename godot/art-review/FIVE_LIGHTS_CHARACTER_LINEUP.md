# Five Lights — Godot character visual review board (candidate only)

Status: **IMPLEMENTED AS REVIEW TOOL / NOT APPROVED ART**. Built on the existing Godot Ender/Ionia art-research line; no gameplay, job, save, canon reveal, ship, or final field-pack changes.

## How to review

Open `godot/project.godot` in Godot 4.7.2, launch the First Wake pilot and press **L**. Press **[** or **]** to scrub six candidate phases for all five characters. Press **M** to toggle between magnified comparison and exact native-size atlas presentation. Press **L** or **Esc** to close; the live actors' physics are suspended while the board is open, and resumed afterwards. The test `godot/tests/character_lineup_review_test.gd` checks stage isolation, five individual source paths, six distinct native SVG-import frames for each of the three new studies, review zoom versus native-size toggle, phase wrapping, and consistent return to the original actor coordinates.

The left-to-right order **Ionia · Ender · Aepex · Lyra · Reson** matches the creator's five-person reference identification; **this does not state party-recruitment order**. Existing Ender and Ionia textures remain unchanged: `ender-south-detailed-staff-v2-candidate.svg` and `ionia-front-sixframe-candidate.svg`. Three new **original editable six-phase south-only candidate atlases** replace the previous gray silhouette blockouts in the review stage: `aepex-south-sixphase-v1-unapproved.svg`, `lyra-south-sixphase-v1-unapproved.svg`, `reson-south-sixphase-v1-unapproved.svg` (each 480×128, six 80×128 cells). Their costumes, palette accents, expressions, and implied gear remain **review interpretations, not creator locks**; **none** are admitted final production artwork. The new files do not imply north/east/west movement, casting, playable recruitment, or a complete height chart.

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
2. Expand these new original **south-facing six-phase SVG studies** into independently authored north/east/west directional studies and portrait turnarounds only after reviewing proportions, anatomy, and outfits. Keep source SVG, ownership/provenance, neutral poses, and exact conversion receipts; no mirrored tattoos/gear or magically granted jobs.
3. Test all five at intended 960×640 logical presentation, including their distinct silhouettes, highlights, hair/tattoos/accessories, environmental palette and accessible contrast. Capture **actual Godot frames**, not concept renders misrepresented as screenshots.
4. Review source/animation via creator signoff; retain draft status until that happens. No PR merge, release or promotion of silhouette placeholders.

Reference: [creator character and art authority](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/blob/main/docs/CHARACTER_AND_ART_AUTHORITY.md) and [visual bible](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/blob/main/docs/VISUAL_BIBLE.md).

## New asset production note (2026-10-27, candidate only)

These three SVG studies were authored as original editable source paths for this branch; they do not derive from another game's sprites. Their artwork is **not approved** and is not bound to combat equipment or class. Lyra's restrained pink accent is **spirit-energy iconography alongside her Water affinity** (not proof of a second combat element). Aepex's wrist diagnostic unit depicts computing expertise without inventing a class/weapon. Reson carries no fabricated military patch, heraldry or fixed signature weapon.

Every newly added atlas contains a distinct per-frame pose group, color-shaded outfit layers and a separate left/right leg/contact phase. Frame distinction is tested from **baked Godot texture pixels**, not only XML node counts. No footplant, stride-speed, true world animation, stylistic uniformity, or creator approval is asserted by this test. Exact native Godot 960×640 screenshots and a bounded 480×320 log preview remain a separate visual gate.
