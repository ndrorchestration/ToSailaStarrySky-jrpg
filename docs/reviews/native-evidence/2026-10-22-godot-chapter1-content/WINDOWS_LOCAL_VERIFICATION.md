# Godot First Wake Chapter I content authority — Windows local verification
**Date:** 2026-10-22  
**Exact exercised head:** `acfd62eb1f04901bae33bb5ce28afda32e652c79`  
**Base:** PR #337 / `feat/godot-first-wake-chapter1-fsm-20261022`  
**Scope:** operator-local native migration/content evidence only.

## What migrated
The native Godot stack now has a dedicated content authority:

`res://scripts/first_wake_chapter1_content.gd`

It binds the current packaged Chapter I source for:
- 3 Signal labels and contact mappings;
- 3 Crossing hazard labels/stats;
- all four first-contact identities/titles;
- **20 authored first-contact dialogue lines** (5 each for Ionia, Wakeheart, Lyra, Verrick);
- 3 storm-path labels and descriptions;
- both `10+` and `7-9` authored outcome texts for every path;
- dynamic player-objective copy;
- the six packaged epilogue identities/texts;
- the current ordered packaged epilogue resolver.

The progression FSM remains separate from content/presentation authority.

## Important resolver boundary
The packaged runtime does **not** select an epilogue from path+variant alone. It evaluates hull integrity, morale, engine integration, and path in ordered trigger sequence.

The native migration mirrors the actual current packaged order. It does not silently implement a nearby legacy comment implying a different "best ending" priority. That discrepancy remains a separate design/reconciliation question.

For deterministic review only, the scene injects explicit metrics:
- hull integrity: 72
- morale: 58
- engine integration: 64
- choice variant: `10+`

Under the current packaged resolver these yield:
- path A → `epiline_1` / **The Clear Departure**
- path B → `epiline_3` / **Verrick's Weather Ledger**
- path C → `epiline_6` / **The First Chord**

## Godot 4.7.2 verification — PASS
Authorized host: `neontic`  
Godot: `4.7.2.stable.official.ed1daf0bf`

Results:
- `AETHERWAKE_GODOT_CHAPTER1_CONTENT_PASS`
- `AETHERWAKE_GODOT_CHAPTER1_FSM_PASS`
- `AETHERWAKE_GODOT_CHAPTER1_SCENE_PASS`
- `AETHERWAKE_GODOT_CHAPTER1_NATIVE_RENDER_PASS`

The scene test confirms path C's deterministic review resolves the authored `10+` outcome and `epiline_6 / The First Chord`, rather than a migration placeholder.

## Native 960×640 renderer — PASS
Real OpenGL 3.3 Compatibility frames:

| Stage | SHA-256 |
| --- | --- |
| Signal | `3ea9d4ee5b1f2167f4a82ead3857d1f8405294f8e0f0315e7e2018db03934f7a` |
| Crossing | `88715b774a2bdfb4b2778d6a0d7852a8206f70d5ed35b5d0e9fb30fa5e17d2f6` |
| Contact | `6781b643507d7967474ac66a9ada4ac00c6729e4f3350e83011d6d77ef1fa1f9` |
| Choice | `f7f4688de666fbb68a51b17c5b885094f895b099e747280425e052f0d1195f13` |
| Wake | `16df678bde0a9329ee488635aea0566622297c5612dda874aeb2280e0ff2143f` |
| Done | `f60497bb0a91ae3acaee5f7a30334b878549848f87fbaee6acdf69c44caa10a7` |

Direct review confirmed:
- Choice visibly uses the three authored packaged labels;
- Wake visibly shows the selected `Project shield / Cover the berths [10+]` consequence text;
- Done visibly resolves **CHAPTER I COMPLETE / The First Chord** with authored epilogue copy;
- active party remains Ender + Lyra + Ionia at the decision/Wake/Done boundary.

## CI
The native Godot workflow now invokes `first_wake_chapter1_content_test.gd` alongside the existing Chapter I state/scene contracts.

## Boundaries
This is a meaningful content migration advance, not completed production migration.

Still unresolved:
- full follow-up/class/deep dialogue corpus;
- production dialogue UI/advance behavior;
- production combat formulas and encounter scene migration;
- persistent save/party integration;
- final sprites/animation/environment art;
- Windows Godot export/install package;
- hosted execution (current hosted no-step runner/startup failures remain separate);
- creator visual acceptance and external-player acceptance;
- issue #293 disposition and public release authorization.
