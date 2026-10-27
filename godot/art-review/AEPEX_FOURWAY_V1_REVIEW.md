# Aepex four-direction character-art study v1 — review only

**Track:** Godot 4.7.2 / GDScript, stacked atop Lyra draft #435 and the five-person review #421. Status: **unapproved original candidate art**. No change to story/canon, skills, spellcasting, recruitment, equipment, save files, playable actor motion, or final field art.

## Source/provenance

The south-facing original six-contact-phase atlas from #421 is retained unchanged. Three separate new editable original SVG atlases (480×128, six 80×128 frames each) have been authored:
- `aepex-north-sixphase-v1-unapproved.svg` — rear undercut, separate jacket and belt topology, diagnostic device and asymmetric tattoos.
- `aepex-east-sixphase-v1-unapproved.svg` — right-facing anatomical profile, visible shaved undercut and sleeve/wrist technology.
- `aepex-west-sixphase-v1-unapproved.svg` — independent left-facing profile, side-specific accessory layout, **not** a horizontally flipped east texture.

Appearance anchors: Aepex is a lean, muscular 27-year-old technical/information-systems specialist; visibly tattooed, angular sharp undercut, second-tallest protagonist. Diagnostic interface is a **candidate motif of computer expertise**, not a fixed job, automatic magical power or creator-locked prop. Side and rear costumes, colors and arm placement remain proposals.

## Reversible Godot review

Open First Wake Godot native pilot, press **L** for five-character review, press **H** to cycle Aepex south→west→north→east. **F** independently cycles Lyra. **[ / ]** scrubs each character's six frame studies, **M** toggles review zoom versus native-source scale; **L/Esc** closes. Nothing changes the live scene when preview is hidden. Exactly one Aepex directional source may be visible.

- `tests/aepex_fourway_review_test.gd` checks all source paths, Godot-baked image resolution, six nonduplicate frames for each direction, cross-direction visual distinction, no mirror flags, source-group identity, exclusive visibility, scrub/cycle controls, scaling and reversible world physics pause.
- `tests/capture_aepex_fourway_review.gd` captures four genuine 960×640 native OpenGL frames at identical positions, phase 2, with four size-limited screenshots crops in private CI logs. Full original screenshots stay on the runner due the pre-existing artifact storage quota.

## Acceptance boundaries

A single still or six distinguishable baked poses is **not** proof of a natural planted-foot gait or animation frame-rate compatibility. Still require: native real movement versus grounded foot travel, four-view identity/style critique at 960×640, proportion continuity with Ender, Ionia and Lyra, acceptable face shading, appropriate environmental lighting, creator visual acceptance, and complete evidence/source custody. The proposed costume or screen device is **not canonized** by this art experiment. No merge or release approval.
