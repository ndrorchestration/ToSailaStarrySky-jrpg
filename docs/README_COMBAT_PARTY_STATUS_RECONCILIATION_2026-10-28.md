# README combat and party status reconciliation — October 28, 2026

**Scope:** Review-only documentation correction on the stacked To Sail the Starry Sky Godot Chapter I draft. No game code, action definitions, combat permissions, character narrative canon, levels, saves, workflows, or installer distribution are changed. README must not be used to promote browser legacy code to the current Godot combat or narrative authority.

## Findings removed from README

| Obsolete public assertion | Evidence boundary / correction |
|---|---|
| The current game has one eight-slot action menu with Resonator Staff / Shared Dream / Mycelial Ledger / Wind Ward / Aether Seal etc. | The eight-slot `ACTION_ORDER` belongs to historical browser `modules/ability-defs.js`, not a current playable Godot menu. The native `first_wake_combat_formula.gd` is a narrow four-action subset with external authority; other abilities remain separate, blocked or unresolved. |
| Wind Ward / Aether Seal / Rest unlock at stated story levels. | `modules/progression-defs.js` is the browser preservation progression contract. No new unlock levels are claimed for the revised Godot Chapter I. |
| Native Godot production combat has full status/turn/party action coverage. | `godot/scripts/first_wake_party_combat_authority.gd` is fail-closed and specifically exposes no Lyra/Ionia formula turn. `combat_ability_contract.gd` normalizes metadata with `canExecute=false`; it is not an executor. |
| Ender recruits Lyra first in current First Wake. | Superseded in the **revised draft** by `godot/scripts/first_wake_revised_opening_contract.gd`: Ender alone → Ionia employed preflight → physical local splashdown and recovery → Lyra/Talen family introduction and Lyra joins second. The old Crossing party contract remains historical and is **not silently mutated** by documentation. |
| Resonance names are playable combo-spell unlocks for the current party. | `first_wake_resonance_roster_gate.gd` checks story presence only; `first_wake_resonance_composite_preflight.gd` produces preflight receipts with `canExecute=false`, `canUnlockArt=false`. `resonance_dual_review.gd` is a standalone permitted training fixture, not the live narrative battle command. |
| Old browser Preview 0.1 installer is the current Godot build. | October 6 browser package results are historical evidence, not current Godot release authority. On the reviewed stack independent Windows Defender custody preflight remains blocked even while native smoke and render CI passes. |

## Current public-status model

- **Native implementation:** separately pinned Godot 4.7.2 scripted review scenes, small combat formula and encounter experiments, revised Chapter I story route, local physics water/berth review, source-tracked salvage and opt-in v3 checkpoint.
- **Prototype contracts:** non-executing cross-party Art metadata, roster/turn preflights, standalone lab demonstration, and archived browser compatibility modules.
- **Story canon vs staging:** five named protagonists and their respective narrative Lights remain distinct from playable school/Art permissions; the creator-directed Ionia-first Chapter I review is draft/unmerged, not an instruction to rewrite original main.
- **Undelivered:** production-ready five-character turn economy, creator-approved weapon/armor/skill/Resonance trees and spell levels, final in-game assets, supported installer release.

**Primary source files inspected on review base SHA `7ae50c697f6e74dc2dee5c36bea881c5d8bdfc1a`:** `README.md`; `modules/ability-defs.js`; `modules/progression-defs.js`; `godot/scripts/first_wake_combat_formula.gd`; `godot/scripts/first_wake_party_combat_authority.gd`; `godot/scripts/vertical_slice_encounter.gd`; `godot/scripts/first_wake_revised_opening_contract.gd`; `godot/scripts/first_wake_resonance_roster_gate.gd`; `godot/scripts/first_wake_resonance_composite_preflight.gd`; `godot/scripts/resonance_dual_review.gd`; `docs/design/AETHERWAKE_COMBAT_DIRECTION_DECISION_2026-10-21.md`; `docs/FIRST_WAKE_SALVAGE_V3_CHECKPOINT_PILOT.md`.

## Acceptance boundary

Verify the README on the **exact PR SHA**, confirm all relative Markdown links point to tracked repository files, confirm stale eight-slot action/level claims and the Lyra-first "current" assertion are absent, and confirm the original Chapter I/main files, release settings and combat runtime are unchanged. GitHub Actions docs smoke may prove repository health but **does not certify** game design or artistic acceptance. Do not merge or publish a new installer without creator authorization.
