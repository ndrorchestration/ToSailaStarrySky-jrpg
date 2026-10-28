# Neutral battle visual lab — real formula → weapon + enemy view

**Status:** isolated Godot 4.7.2 prototype, **not** production scene, canonical Chapter I placement, approved art, save authority, melee collision or Windows release. This draft intentionally builds on [staff-visual #493](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/493) and takes **only three presentation files** from [enemy art #410](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/410). It does **not** copy the old Lyra-first crossing scene or roster state.

## Included isolated review route

- `godot/scenes/neutral_battle_visual_lab.tscn` — real 960×640 Godot Node2D scene.
- `godot/scripts/neutral_battle_visual_lab.gd` — sole action host using the existing production-formula subset controller `FirstWakeFormulaEncounter` and existing `FirstWakeCurrentEnemyAdapter`. It loads the existing `windShear` profile **as a lab fixture**, with no quest, party, save, ship, scene-transition or player progression.
- `godot/scripts/neutral_enemy_weapon_visual_cue.gd` — read-only **post-resolution** snapshot adapter. Validates actor/action/equipped staff, current enemy identity, HP/staff charge/turn deltas and real action log; deduplicates accepted visual receipts. A snapshot is **not a cryptographic or signed event**, and this adapter can never call the battle controller or claim a hitbox.
- Existing read-only `weapon_battle_visual_adapter.gd` and `ender_staff_combat_keyframe_review.gd` provide the provisional directional staff pose; extracted `first_wake_wind_shear_visual.gd` and its original two 320×92 atlases show the elemental.
- Lab controls: **Enter** to start, **1** for a real authorized staff action within this neutral fixture, **R** to reset. Or run the supplied native tests. No menu or full-game entrypoint has changed.

### One actual action, two visual reactions

```text
neutral Godot scene (review-only)
  └─ authentic FormulaEncounter.take_action("staffStrike") [called once]
        └─ before/after immutable snapshots
              └─ neutral_enemy_weapon_visual_cue [observes only]
                    ├─ existing staff/keyframe presentation [visual only]
                    └─ existing enemy art state [visual only]
                         hit -> already-resolved Gale; reduced motion -> static
```

A visual receipt reports `turnDelta=1`, observed HP loss, one actual enemy turn, one staff charge consumed, `canExecute=false`, `saveWritten=false`, `storyPlacementApproved=false`, `spriteApproved=false`. Duplicate receipts, invented extra turns, forbidden actions, invalid actors and unsupported weapons fail closed. **No player counterplay or pre-attack telegraph has been created.**

## Verification and visual evidence

**Native executed source head:** `f1c84147366e968d05a294d6b0582e4fcf7d66f5`.

- [CI run 40623979189](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/actions/runs/40623979189) **PASS** with real Godot 4.7.2 editor import, inherited formula/party/staff regressions, `TSTSS_NEUTRAL_BATTLE_VISUAL_LAB_PASS` and `TSTSS_NEUTRAL_BATTLE_VISUAL_RENDER_PASS`.
- Four actual **960×640 engine PNGs**, with source-hashed, bounded public-safe JPEG previews in log (no artifact storage upload):
  - idle `0d86fff981bfa17e15346f3b4f9b7d10d3457aee300ac0328fc177fb924b0f1e`
  - observed hit `b202a23f97b8457ce5d35aecfe2685503ed608bb25d91657cdb3cf14ef9dd05f`
  - already-resolved Gale `72bbefbf31db04419b64c401ea0ded5088507bc1c69a314a3664d094c2895ea2`
  - reduced motion `e80080edeaaffb3e9d109b8ed1f305a4e3eeb07f4b84c31dfd81d651ac7a18e6`.
- **Actual visual review:** legible character+enemy silhouettes, real HP changing 14→6, distinct Gale effect, static reduced-motion pose, no obvious overlapping readouts. **Outstanding:** staff's optical contact is spatially far from the enemy, and the current geometric staff actor is **unapproved**. This verifies a visual *contract*, not melee collision, reach, final camera composition or polished contact effects.
- Keyboard-review addition in follow-on commit has its own exact-head run; verify before recording as passed.

## Production admission sequence (not yet implemented)

1. **P1 contract:** this neutral lab is the narrow executed joint visual proof. Isolate a reusable production-safe, **versioned** combat resolution consumer rather than treating test-sidecar snapshots as signed events.
2. **P2 visual:** establish an authentic contact choreography consistent with the staff's physical span and enemy distance; no fictitious physical hitbox. Capture directional 1× and 1440×960 scaled views, text/HP contrast, camera/atlas transitions, and accessibility.
3. **P2 story:** reconcile forward [Ionia-first Chapter I reboard #425](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/425), [native #430](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/430), and [read-only story projection #491](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/491). The legacy first-wake scene still shows Ender+Lyra first; **Wind Shear encounter timing is OPEN**. Do not merge it into the new opening.
4. **P3 production:** exact-ancestry integration, actual camera/environment/weather composition, target CPU/GPU/FPS cost and memory, accessibility/player review, Windows Defender custody, creator art/canon/gameplay acceptance, authorized merge/release.

**Verification language:** SOURCE and NATIVE CONTRACT/RENDER **PASS** in one neutral fixture; HUMAN VISUAL, STORY PLACEMENT, TARGET GPU and WINDOWS SECURITY **NOT APPROVED**. No gameplay balance, world canon, main branch merge or release changed.
