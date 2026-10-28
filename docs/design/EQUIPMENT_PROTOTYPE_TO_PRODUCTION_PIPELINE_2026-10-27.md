# Equipment lifecycle: prototype-to-production admission gates

**2026-10-27 · PROPOSAL / documentation only.** This is a public-safe handoff, not an authorization to change story canon, ship interiors, final item names, numerical balance, persistent saves, art approval, merge, or release.

**Source authority:** [AGENTS](../../AGENTS.md), [Godot migration](../GODOT_MIGRATION_COORDINATION.md), [canon/reveal policy](../CANON_AND_REVEAL_POLICY.md), [character/art](../CHARACTER_AND_ART_AUTHORITY.md). Godot 4.7.2 + GDScript is the forward engine; JavaScript main remains the historical runtime reference.

## Verified source and evidence

The unmerged draft equipment chain is [#347](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/347) → [#412](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/412) → [#423](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/423) → [#444](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/444) → [#449](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/449) → [#462](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/462) → [#481](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/481). Source-bound #481 head: b16a3938964b46b2d0c868217237893b5712cb32.

- [Native Godot First Wake #40608702670](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/actions/runs/40608702670): SUCCESS at exact head, including inventory conservation, inspector, equipment/combat, chapter/save authority tests.
- [Real native rendering #40608702775](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/actions/runs/40608702775): SUCCESS, 960×640 current/preview/confirmed HUD and gear frames, pixel-difference checks. Full screenshots are runner-local; artifact-storage quota prevents review distribution. Passing pixels is not artist approval.
- [Legacy smoke #40608702788](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/actions/runs/40608702788): SUCCESS.
- [Exact Windows QA #40608702782](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/actions/runs/40608702782): security preflight BLOCKED by Defender real-time disabled, despite separate functional-prerequisites success.
- Public main observed as 79b48718b0c8b5e7f0ae4d811d5ae12e1a436a09, **without the Godot directory**. Do not merge these diverged native drafts wholesale, infer a complete runtime, or disturb JavaScript saves.

## Reusable architecture / admission matrix

| Godot study source | Keep as reusable contract | Production gate still required |
|---|---|---|
| battle_equipment_loadout.gd | Actor, slot, weapon-family and stable item IDs | Approved data registry and per-job/level permissions for five protagonists |
| battle_equipment_trial_inventory.gd | Atomic ownership and zero-duplication gear swaps, invalid transfer rollback | Real roster-backed acquisition and persistent inventory; not seeded practice bag |
| battle_equipment_inspector.gd / _panel.gd | Read-only preview, before/after comparisons and commit, modal input isolation | Scalable accessible shared menu, controller UX, no conflicts with pause/cutscene |
| battle_equipment_attachment.gd / _visual.gd | Independent weapon, grip, armor and accessory socket layers | Creator-approved animated field/battle sprites and per-direction attachment data |
| battle_equipment_training_profile.gd | Deterministic stat/defense input and tests of real practice VIT loss | Approved battle balance, damage taxonomy and real enemy integration |
| Native tests + framebuffer receipts | Continuous evidence of state, authority and visual changes | Portable review assets, target GPU/performance, human art/player acceptance |

**Do not promote test content:** inlaid staff, chest-guard, travel charm and their provisional +4/+8/+6 values, 12-point pressure dummy, loot economy, final lore names, item rarity, or unrestricted class abilities. The creator-directed weapon families are Ender staff, Lyra chakram, Ionia mace, Reson sword/rifle and Aepex martial arts; five story energies must remain independent of job-selected magic.

## P-01: smallest end-to-end equipment lifecycle test

**Proposed fixture:** a deliberately noncanonical study station in a test-deck scene (not a canon Aureate Wake room or new Chapter I beat).

1. Interact with station and read the validated, temporarily owned trial items.
2. Preview a different item. Assert no actual ownership, visuals, HP/VIT, turn or save change.
3. Confirm legally. Assert old item returns to bag, new item is equipped, same item ID drives UI and animation socket, no turn spent.
4. Enter noncanonical practice battle. Verify outgoing strike damage and physical/aether counterpressure from that exact loadout.
5. Exit and re-enter the field/station: equipment state and bag quantities are identical in session; no duplicate avatar/roster copy is created.
6. Reset or restore old Chapter I snapshot: trial items disappear back into their initial sample state, with no incompatible save upgrade.

**Candidate production seam:** ItemRegistry → Inventory/Loadout authoritative roster record → atomic EquipmentTransaction → read-only GearInspector → CharacterRenderAdapter and BattleStatResolver → versioned SaveCodec (last step only after separate approval). Combat does not own permanent items. Reject forged, foreign, mismatched, zero-stock, duplicate, interrupted or double-commit transactions. Test fail-closed authored Wind Shear and blocked magic/resonance actions.

## Promotion tests, independent gates

| Gate | Required evidence | Current verdict |
|---|---|---|
| P0 Source/parity | Exact branch/commit, current docs, parity with authoritative formulas, story/save joins and ancestry | Existing separate contracts PASS; combined integration NOT RUN |
| P1 Actual playable loop | Godot scene interaction, owned inspection/confirm, real rendering + combat results, zero-turn equip | Staged in separate review [PR #509](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/509); exact-head native verification required before PASS |
| P2 Transition/party | Field/menu/battle/loadout consistency, five-cast negative permissions, save-independent session continuity | Cross-scene integrated test NOT RUN |
| P3 Durable data | Versioned roster-backed items, old-save migration, corruption/backup recovery, rollback and duplicate rejection | Not designed/authorized |
| P4 Visual/accessibility | Approved source art, 4-direction sockets, pose/lighting/occlusion, gamepad, text scaling, focus, reduced-motion and creator inspection | Provisional art; final acceptance OPEN |
| P5 Platform/player | Windows exact security and installed launch, representative GPU FPS/frame pacing, cold player test, owner approval | Windows gate BLOCKED; human study NOT RUN |

Each checkpoint requires exact SHA, real Godot 4.7.2 editor import/tests, deterministic expected/observed results, genuine native frames with accessible evidence custody, asset provenance and separate signed-off design/visual/player decisions. A passing test is not proof of premium art.

## Documentation change register

| Document/record | Update required |
|---|---|
| This equipment pipeline plan | Keep exact SHA, passed vs held gates, roster/state boundaries and end-to-end P-01 recipe |
| docs/GODOT_MIGRATION_COORDINATION.md | Link equipment as its own native draft line; forbid silent merge with planet/ship/other Chapter I tracks |
| docs/AGENT_HANDOFF_INDEX.md | Route equipment, armor, inventory and UI work to this plan before implementation |
| docs/NOTION_SOURCE_INDEX.md | Link existing public-safe development Notion ledger and gate summary only |
| godot/BATTLE_EQUIPMENT_REVIEW.md (unmerged #481) | Link this main-branch handoff; distinguish temporary item ownership from durable player inventory |
| godot/README.md | Remove obsolete feasibility-only claims once exact current native baseline is reconciled; do not claim complete migration |
| docs/DEVELOPMENT.md and native save docs | Clarify old JavaScript release/runbook versus future Godot, draft real inventory schema and migration **after authorization** |
| Item registry, jobs, combat and visual asset manifests | Propose explicit approved permissions/balance, socket/source sheets, direction/pose/state matrices |
| Chapter I storyboard and cold-playtest plan | Treat station as noncanon test insertion; do not overwrite opening, join order or story clues; test discoverability and feedback |
| Notion development/working equipment records | Log exact PRs/runs, gates, creator decisions and open dependencies; no private content copied into public repo |

**Cross-track note:** the independently staged Chapter I/Aureate Wake cinematic handoff [#492](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/492) is NOT proof of equipment integration. Treat branch reunion as a separate reviewed ancestry, scene and story-parity exercise; never reveal restricted later-game navigation content.

**Decision:** build one new reversible Godot P-01 equipment test scene on an isolated branch based on exact draft #481, run native end-to-end, obtain creator UI/art review, then independently gate real acquisition, persistent saves and authorized battle effects. Until then: END_TO_END=NOT_RUN; REAL_INVENTORY=NOT_IMPLEMENTED; ART_ACCEPTANCE=PENDING; WINDOWS_SECURITY=BLOCKED; MERGE=HOLD; RELEASE=HOLD.

## 2026-10-27 prototype implementation handoff

The noncanonical [P-01 station/battle lifecycle draft #509](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/509) stacks on #481, adds a separate opt-in native Godot scene, field study station, inspector/ownership transitions, deterministic battle proof, return and legacy-save reset checks. It leaves the original Chapter I scene's test flag default false and does not upgrade art, item lore, source of truth or saves. [Repository smoke #40615950748](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/actions/runs/40615950748) completed SUCCESS; [Godot native #40615950706](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/actions/runs/40615950706) and [real native GL #40615950690](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/actions/runs/40615950690) were still in progress when this note was written. Do not cite an in-progress run as verification; the protected [Windows #40615950688](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/actions/runs/40615950688) still fails the unchanged Defender real-time preflight. Subsequent exact-head checks supersede this *dated* run-status snapshot but not the adoption gates.
