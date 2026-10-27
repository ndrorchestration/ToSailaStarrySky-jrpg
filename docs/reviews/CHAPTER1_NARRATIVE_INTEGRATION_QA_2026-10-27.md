# First Wake — Chapter I narrative integration QA

**Status:** SOURCE CANDIDATE / REVIEW ONLY. No canon promotion, merge, Windows release, creator visual acceptance, or player acceptance.  
**Track:** Godot 4.7.2 / GDScript, isolated review branch stacked on [native Chapter I PR #347](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/347).  
**Bounded source baseline:** `74fe1bce7a8a02eb3cbf30f725fa2af0925ba670`. This document is public-safe; restricted late-game information is intentionally omitted.

## 1. Why this increment exists

The native Chapter I pilot already carries **Signal → Crossing → Contact → Choice → Wake → Done**, authored contact dialogue, a real Wind Shear encounter, party-state authority, versioned save validation and a legacy epilogue resolver. This is a migration-review scene, not a finished Chapter One journey. A known defect of the *historical* resolver is that default stats (`hull=100, morale=50, integration=0`) resolve `path_a`, `path_b`, and `path_c` to `epiline_1` **The Clear Departure**. For `path_b` and `path_c`, the ending label can contradict the action just performed.

**Review-only change:** `first_wake_choice_receipt.gd` derives the exact authored choice label and outcome from the already-persisted `choice_path` and `choice_variant`, preserving the selected action on the Done scene and on a completed-chapter save restore. The narrow, demonstrable `epiline_1` departure conflict for nondeparture paths is labeled **LEGACY ENDING CONFLICT — REVIEW ONLY**. It does not automatically certify any other path/ending pair as consistent.

**Untouched:** `resolve_legacy_epilogue`, old content, endings, Chapter I stage/choice ordering, outcome variants, party rights, save schema, save migration and gameplay state. No new lore or replacement finale text is introduced.

## 2. Evidence categories

| Claim | Status | Evidence required |
|---|---|---|
| Six authored `choice_path × variant` outcomes are preserved | SOURCE / TEST AUTHORED | Exact-head native `first_wake_choice_receipt_test.gd` result |
| Default path-B/C departure contradiction is surfaced | SOURCE / TEST AUTHORED | Pure receipt test + rendered Done captures |
| Selected authored outcome visible after Done and Done-save restore | SOURCE / TEST AUTHORED | `first_wake_chapter1_review_test.gd` + native 960×640 screenshot |
| Legacy first-match resolver unchanged | SOURCE, inspect diff | Legacy content test must continue to PASS |
| No unapproved companion combat authority | SOURCE, no intended mutation | Native party authority + Wind Shear scene regression |
| Player understands and feels the choice | **NOT ESTABLISHED** | Uncoached playtest and creator acceptance |
| Canonical Chapter I finale | **NOT ESTABLISHED** | Explicit creator-approved scene and resolution contract |

This review does **not** claim native tests executed merely because a CI step exists.

## 3. Chapter I story integration — incomplete production requirements

| Beat | Established story / previous work | Native production gap | Acceptance |
|---|---|---|---|
| Arrival and berth | Authored opening sequences 00–03; Ender new to the ship, Ionia captain, work nook/berth | Full native opening sequence not in reviewed dock FSM scene | Player can walk, repair berth and identify why Ender came aboard |
| Talen and belonging | Sequence 04, Talen asks whether Ender is staying; miniature ship prop | Port approved household scene, noncombat, no unreleased child phenomena | Talen reads as a five-year-old family member, never a quest hostage |
| Lyra and Wrong Song | Sequences 05–06, discoverable exploration, Lyra joins first | Port free-roam discovery and separate observations | Distinguish Lyra's sensed wrong frequency and Ender's structural observation |
| Ionia and practical stakes | Sequences 07–09 and later Contact | Continuous authored scene handoff, navigation, household stakes | Ionia's responsibility is consequential without giving her premature combat turns |
| Signal investigation | Three authored signal hooks | Natural multi-order discovery rather than marker checklist alone | Evidence remains observation, not prematurely confirmed cosmology |
| Crossing and Wind Shear | Wind Shear native combat bound; two other hazards intentionally noncombat | Camera, stakes, avoidance/aid, pacing, player recovery | Ender + Lyra presence preserved, unauthorized actions fail closed |
| Storm decision | Current three paths: early departure / hold dock / wide shield | Path-specific outcome persistence and ending alignment | All six variants retain their authored meaning; no misleading epilogue |
| Domestic aftermath | Home & Family ending proposed in Notion | Creator-approved scene and dialogue are **not yet migrated** | Revisit Ender's berth or shared space with a changed detail; human consequence visible |
| Onward flight handoff | Planetary flight and worldmap in separate draft tracks | Connected scene transition and save handoff | No silent shift to unfinished globe prototype or restricted navigation |
| Optional private actions | Charter/route/household clue proposals | No admitted native Act I implementation | Optional discoveries enrich relationships without blocking the main route |

## 4. Requested narrative decisions — leave open

1. **Production epilogue rule:** Preserve the legacy ordering *as a migration oracle* but separately approve a new path-consistent presentation/resolution policy. Do not change canonical endings automatically.
2. **Domestic closing scene:** Review the already-authored Home & Family Pass; approve precise playable actions/lines before implementation. Proposed image: Ender's berth/handmade ship prop or shared room recognizes his new place aboard.
3. **Finale encounter:** Chapter One has hazards and a storm choice, but no approved boss. Decide whether the storm-system crisis itself is the climax rather than inserting an unsupported enemy.
4. **Godot UI candidate:** Another agent has reported local-only native UI work. Reconcile actual published source first; avoid merging alternative UI layers blindly.
5. **World/dock topology and packaging:** Creator terrain direction and Windows Defender security acceptance remain separate gates.

## 5. Native verification protocol

Run the existing official Godot 4.7.2 pinned workflow on the **exact review head**, including:
- real import, new `first_wake_choice_receipt_test.gd`, existing content/epilogue contract;
- Chapter I scene contract and completed-save restore;
- companion action denial, Wind Shear clear/retaliation and no progress on defeat;
- captured native Done frame showing action/outcome and the flagged legacy conflict at 960×640;
- real Windows packaging/installation/security checks, creator inspection and uncoached player test **only when separately authorized**.

Nothing in a passing test automatically merges the review candidate, changes creator canon, clears the Defender hold, or authorizes public distribution.

## Authority

- [Current public-safe canon and reveal policy](../../docs/CANON_AND_REVEAL_POLICY.md)
- [Godot migration coordination](../../docs/GODOT_MIGRATION_COORDINATION.md)
- [Narrative & Canon](https://app.notion.com/p/3e0f5bad238b812bac52c594d1465c29)
- [First Wake Home & Family Pass](https://app.notion.com/p/3e2f5bad238b812eafe4e0d891d45cf8)
- [First Wake Opening Storyboard](https://app.notion.com/p/3e2f5bad238b81c99b51cfbce1bba583)
- [First Wake Chapter I Acceptance Matrix](https://app.notion.com/p/3ecf5bad238b8103b313f79ea816a9b5)
