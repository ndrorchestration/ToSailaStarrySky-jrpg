# Native weapon mastery and equipment visuals — first pass

**Status:** PROPOSAL plus isolated Godot implementation. No approved combat actions, class unlocks, or final sprites are claimed.

**Engine:** Godot 4.7.2 Standard / GDScript. **Base:** [PR #347](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/347) at `74fe1bce7a8a02eb3cbf30f725fa2af0925ba670`.

## In the review

- **Four physical weapon families:** staff, sword, pike, rifle; three tiered techniques each (12 proposal skills).
- **Prerequisite unlocks:** practice points, training rank, prior technique. Previously learned skills are retained when changing the displayed weapon; only the equipped family's skills appear in the skill preview.
- **Actual Godot graphics:** a selectable original geometric silhouette for each weapon, from the same runtime equipment ID. Ender's staff retains a full-length straight shaft, midpoint wrap and two brass ferrules.
- **Interactive review UI:** `res://scenes/weapon_tree_review.tscn` at 960×640. Use Previous/Next, Training Rank and the skill buttons. This is a review fixture, not a new game menu.
- **Combat isolation:** executable actions remain **zero** for this proposal; production Chapter I retains the established Ender-only formula authority and its existing save codec.

## Authority boundaries

**ESTABLISHED:** Ender's staff art anchor; Reson has rifle/pike/sword vocabulary. The five protagonists retain their plot energies independent of chosen jobs, skills and access to spellcasting.

**PROPOSAL:** exact item models, techniques, ranks, practice points, names, silhouettes and UI. Their physical or nonmagical characterization is deliberate: element/spirit affinities are *not* requirements for wielding a weapon.

**OPEN:** final starting items of Lyra/Ionia/Aepex, job permission matrix, armor, ammunition, combat math, equipment switching policy, equipment saves, directional field/battle sprites and creator acceptance.

An older isolated equipment-system branch describes candidate starting items. This PR **does not promote that unmerged source to canon**.

## Verification and next gates

Native CI workflow `godot-weapon-tree-review.yml` imports the project and runs `godot/tests/weapon_skill_tree_review_test.gd` in the official pinned Godot version. The test checks tree uniqueness, unlock gates, point accounting, learned-skill retention, family filtering, visual selection and fail-closed executable-action flags.

Full project import, native rendered screenshots, 960×640 legibility, keyboard/controller navigation, reduced-motion settings, art acceptance, actual combat formula integration and save migrations remain **separate gates**. The synthetic geometric icons are design-review placeholders, not final animated art.

To try locally, open `godot/project.godot` in Godot 4.7.2, then run `godot/scenes/weapon_tree_review.tscn` as the current scene (F6). Do not change the project's default Chapter I scene to do so.
