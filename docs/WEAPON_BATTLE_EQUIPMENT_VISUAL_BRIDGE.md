# Chapter I — weapon equipment visual bridge (native review only)

**IMPLEMENTED SOURCE:** An isolated Godot 4.7.2 battle-screen *visual* adapter stacked on [PR #424](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/424) and underlying [PR #415](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/415). It does not amend the active Chapter I scene.

## Contracts and provenance
- `godot/scripts/first_wake_party_combat_authority.gd` remains sole actor action authority. At review baseline it authorizes `ender/staffStrike`, `ender/uncoverTruth`, `ender/hold`, `ender/rest`; it does **not** authorize new tree techniques, additional actors or alternate equipment.
- `godot/scripts/first_wake_combat_formula.gd` remains formula authority. Both it and the party permission contract must validate before an action is *visually mapped*. A mapped intent is **never executed** by the bridge.
- `weapon_battle_visual_adapter.gd` maps precisely one permitted intent to a physical visual: **Ender + full_length_staff + staffStrike -> attack**. There is no inference from elemental affinity, learned weapon skill, equip family or party presence. `uncoverTruth`, `hold`, `rest` have valid formula rights but no reviewed choreography mapping in this adapter.
- `equipment_sandbox_pose` demonstrates each family's equip-dependent silhouette, action and motion, with no actor identity and no ability to issue a command. Sandbox weapons do **not** equip Ender, Lyra, Ionia, Reson or Aepex.
- The actor's appearance in the screen is a neutral mannequin with unapproved original geometry, *not Ender's canonical artwork*. The training target is a noncanonical practice prop.

## User interaction
Open `res://scenes/weapon_battle_equipment_review.tscn` directly as the Godot editor current scene (F6). The display starts in **read-only Ender staff-action intent mode**, locked to the staff. Toggle to anonymous **equipment sandbox mode** to cycle staff, sword, pike and rifle; select the four physical action poses, scrub the clock, step 0.1 s, play or enable reduced motion. Switching back restores Ender's staff visual and the restricted actor/action mapping.

A local `FirstWakeFormulaEncounter` is constructed solely for *read-only* demonstration of static training target HP and staff charge metadata; no `start`, `take_action`, encounter transition, damage, resource spending, inventory equip mutation, quest/save I/O, new formula authorization or actor participation is performed. Any UI state and visual time changes leave that model's HP, staff charges and turn count unchanged.

## Verification boundary
`godot/tests/weapon_battle_visual_adapter_test.gd` rejects spoofed actors, unknown weapons, unauthorized/unmapped actions, invalid clocks, cross-weapon action visual leakage, accidental execution metadata, and combat snapshot mutation. It instantiates the actual Godot scene and checks weapon changes, mode return and reduced-motion state. Prior weapon skill-tree and choreography tests are rerun in pinned **Godot 4.7.2**.

`godot/tests/capture_weapon_battle_equipment_review.gd` captures four genuine **960×640** comparison frames with SHA-256 receipts: Ender's authorized staff action intent (as a mannequin), anonymous sword, anonymous pike and reduced-motion pike. Real engine rendering validates distinct states, **not pixel-art quality or artistic approval**. Full frame distribution may be blocked by GitHub Actions artifact quota. Windows security preflight, unrelated story canon reviews and player-facing packaging remain separately gated.

## Open integration gates
1. Confirm Chapter I screenplay/party timing conflicts with creator-approved opening revisions **before changing** any canonical encounter scene or participant.
2. Define actual battle equipment slots, allowed owners, saved equipment schema and migration rollback proof.
3. Produce provenance-checked directional character and weapon layers; check hand-to-weapon attachment pivot, stance, foot-contact, depth sorting and motion accessibility in genuine rendered frames.
4. Provide separate authorized dispatch and hit-event adapter, formula conservation/resource tests and Windows QA evidence before playing this animation as an actual `staffStrike` in combat.
5. Obtain creator visual approval, gameplay gate approval, merge and release decisions separately. **Nothing in this review licenses these actions.**

## October 27 rendered visual QA — observed, not accepted

The first actual 2×2 native contact sheet surfaced **HUD collisions and drifting hand-to-weapon placement** which unit contracts and PNG hash checks did not detect. These were repaired in-place with:
- Restricted authority/status copy to the left column; target HP on a separate right status rail; physical cue and non-execution disclaimer on distinct lower rows.
- Higher-contrast theme styleboxes for native selection buttons, including the locked current actor equipment field.
- Family-specific physical grip anchors (staff midpoint, sword lower hilt, pike shaft, rifle trigger grip) transformed with equipment rotation around the actual mannequin hand. A GDScript regression checks sword-hilt attachment at a rotated impact pose.

A **second real Godot CI contact sheet** verifies improved layout separation and visual equip distinction. Remaining independent aesthetic limitations: noncanonical low-detail geometric mannequin, static torso and legs for most action phases, simplified weapon silhouettes, simplistic contact trails, uncertain directional/protagonist pivot requirements, and no animation polish/audio/hit reactions. These require authored character rigs and independent creator acceptance, not test-name promotion.

The 2×2 lossy montage is emitted into CI logs only as clearly labeled original geometry at half-size per frame; full-resolution frame hashes remain runner-only and are **not substitute proof of final sprite detail**. No proprietary/unaccepted character likeness is introduced.
