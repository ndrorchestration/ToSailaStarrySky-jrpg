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
| P1 Actual playable loop | Godot scene interaction, owned inspection/confirm, real rendering + combat results, zero-turn equip | **PASS as isolated P-01 Godot study** on [#509](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/509) exact SHA `9a05d6e01f51eb7321cf25dd1662517407df02bf`: [native + six-frame proof #40617103034](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/actions/runs/40617103034). Not a production level or integrated canon scene |
| P2 Transition/party | Field/menu/battle/loadout consistency, five-cast negative permissions, save-independent session continuity | **PASS, narrow volatile practice-session identity test**, [draft #520](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/520) exact tested code SHA `fb088adad6acd0664cebd16649f20c9cdef7d785`, [Godot #40624655094](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/actions/runs/40624655094). Does **not** establish five-character battle/production progression |
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

## Exact P-01 verification supersession — 2026-10-27

[Review-only PR #509](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/509) exact tested HEAD **`9a05d6e01f51eb7321cf25dd1662517407df02bf`** passed [independent Godot 4.7.2 lifecycle proof #40617103034](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/actions/runs/40617103034). Native trace marker: `TSTSS_EQUIPMENT_LIFECYCLE_PASS`, confirming controlled test-only field E-interaction, read-only item preview, owned commit, field/battle review-rig item parity, noncanon +4-power staff delivering 9-point practice strike, 10/9 physical/aether practice mitigation, conservation after return, and reset on existing chapter-save restore. Six real 960×640 Godot frames captured (baseline, inspector, preview, equipped field, battle, returned field), local hashes recorded and direct pixel assertions passed: `TSTSS_EQUIPMENT_LIFECYCLE_NATIVE_RENDER_PASS`. Original ownership/inspector/pressure regression suite also PASS in the same proof. [Full Godot First Wake regression #40617103190](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/actions/runs/40617103190), [legacy smoke #40617103053](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/actions/runs/40617103053) and [native Ionia visual review #40617103037](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/actions/runs/40617103037) separately completed SUCCESS. [Exact Windows QA #40617102933](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/actions/runs/40617102933) completed FAILURE at the unchanged Defender real-time preflight (functional-prerequisites subjob PASS).

**Correct classification:** `P1_NONCANON_INTEGRATION=PASS`; `P1_HUMAN_PLAYER_INTERACTION=NOT_RUN`; `REAL_ENDER_FIELD_SPRITE_ATTACHMENTS=NOT_IMPLEMENTED`; `P2_FULL_PARTY_CROSS_SCENE=NOT_RUN`; `P3_DURABLE_ITEMS=NOT_AUTHORIZED`; `P4_CREATOR_ART_ACCEPTANCE=PENDING`; `P5_WINDOWS_SECURITY=BLOCKED`; `MAIN_INTEGRATION=NOT_MERGED`; `RELEASE=HOLD`. Native actual PNGs remain runner-local unless separately recovered; pixel assertions don't prove beauty, legibility or artist signoff. The test station is noncanonical study geometry only. Later full Chapter I regression and protected Windows CI have separate exact-head statuses; the bounded proof is not a substitute for any release gate.

This section supersedes the earlier in-progress status snapshot for **this** exact commit only. New commits need new evidence.

## P-02 shared volatile equipment state — verified, 2026-10-27

New [draft equipment session PR #520](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/520), stacked on native P-01 #509, implements `godot/scripts/battle_equipment_session_review.gd` and `battle_equipment_session_review_test.gd`. It holds five independent **starter-family** actor loadout records and one Ender **noncanonical** owned practice bag, then admits only isolated study scenes through a prevalidated common reference handoff. It does **not** create a permanent party inventory, item acquisition, save schema, new party turn, class/job ability, new Chapter I narrative beat or shared planetary/ship scene.

At exact source SHA `fb088adad6acd0664cebd16649f20c9cdef7d785`, [official Godot 4.7.2 P-02 proof #40624655094](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/actions/runs/40624655094) completed **SUCCESS** (all 8 steps). Log: `TSTSS_EQUIPMENT_SESSION_PASS`. Real test frees one scene, loads a new Godot scene, proves same object identity for Ender equipment and bag, after-battle 9-point practice staff and 10/9 mitigation, fail-closed cross-actor forgery, no temporary data leak into Chapter I v1 save and safe reset on old save restoration. Same run preserves existing P-01 lifecycle, inventory, loadout and save scene tests.

**Admission classification:** `P2_VOLATILE_SCENE_HANDOFF=PASS`, but `FIVE_CAST_PRODUCTION_COMBAT=NOT_IMPLEMENTED`, `ITEM_INSTANCE_OWNERSHIP=NOT_IMPLEMENTED`, `ACQUISITION_ECONOMY=NOT_DESIGNED`, `DURABLE_SAVE_MIGRATION=HOLD`, `ART/PLAYER_ACCEPTANCE=PENDING`, `WINDOWS_RELEASE_SECURITY=HOLD`, `MERGE=HOLD`. Future production P-03 must draft a *separate* authorized versioned item/roster/save contract, including old saves, atomic writes and corruption recovery. No branch/PR can promote test-only stat bonuses or private story information.

## 2026-10-28 P-03a offline save-contract proposal (not active player persistence)

[Draft P-03a PR #535](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/535), stacked on P-02 [#520](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/520), stages a separate Godot 4.7.2 item-instance serialization and test-slot recovery proof. **Do not promote until its current exact-head test completes SUCCESS.** The new `tstss.equipment.study.v0` is a **review-only contract**, not a production migration. It accepts five starter-family identity rows and exactly nine developer-fixture item-instance records with single ownership, compatible actor/slot/location and no unauthorized provenance. It denies duplicate IDs, ghost-equipped references, malformed chapter story, altered schema and invented loot.

**Important anti-grant policy:** valid existing `aetherwake.first-wake.chapter1.v1` saves may produce a `legacy-pending-authorization` envelope containing **no roster and zero items**. Only an explicitly opted-in developer fixture encoder represents temporary gear from P-02. A real player save cannot silently receive starter gear, owned loot or item-instance identities by migration inference. The live v1 save codec/store/path are untouched; the isolated file test uses only `user://aetherwake-tests/equipment-p03-study.json` with candidate staging, hash/backup validation, corrupt-primary recovery and rejection if all generations are invalid.

**Production P-03b still required:** creator decision on initial item rights, real item-instance ID creation and provenance, authorized shop/drop/quest acquisition, immutable transaction receipts, strict versioned roster+ownership schema, migration of existing player saves with meaningful compatibility and fallback, atomic write/power-loss contract, rollback and Windows player-file restore. Do **not** equate P-03a schema proof with live durable inventory or playable content. P-04 approved field sprite/socket composition and P-05 Windows/player acceptance remain independent.
