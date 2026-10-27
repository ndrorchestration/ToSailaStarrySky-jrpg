# Resonance / JRPG shared ability-admission seam — v0.2

**Status:** Isolated Godot 4.7.2/GDScript engineering candidate on [draft PR #413](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/413). No production skill or roster admission, combat engine replacement, save migration, merge, release or canon promotion.

## Why this increment

The first playable Tidebound Promise scene contained local checks and direct resource deductions. Extending that pattern to every Dual and Triple Art would fork cost logic and grow an independent combat engine, violating the established shared AbilityDefinition/formula design. This increment moves **metadata and atomic reservation planning** into reusable, pure native contracts, while leaving First Wake's actual JRPG formula resolver and its authority untouched.

## Authority separation

1. Creator-approved five Lights: Ender Spirit; Lyra Water (pink spirit-energy accent); Ionia Earth; Reson Fire; Aepex Air. These remain independent of equipped jobs and learned spell-school access.
2. `first_wake_party_combat_authority.gd` **alone** controls admitted native formula actions. It still grants no formula turn to Lyra/Ionia and blocks Shared Dream/Wind Ward.
3. `combat_ability_contract.gd` **normalizes** both the four existing native JRPG formula metadata records and four proposed Resonance Art definitions into one schema. Every returned definition has `canExecute=false` and requires its existing external authority/resolver. It never grants new production permissions.
4. `party_action_reservation.gd` accepts only explicitly `reviewOnly=true` state, a valid `DESIGN_ONLY` Dual/Triple definition, player phase and the typed local *Focus* fixture resource. It preflights every participating actor (alive, available, nonnegative finite integral fixture values, enough Focus), returns a deep-copied staged party plus individual receipts, or rejects with no state mutation. Focus is **not** Arete or Echoes.
5. `tidebound_promise_review.gd` now consumes that shared **staged plan**, committing both actors' actions and Focus deductions at once only on successful preflight; it retains its existing local one-hit ward effect. No default scene or production combat dispatcher imports this review adapter.
6. The original proposal catalog keeps `DESIGN_ONLY` definitions and `try_execute()` fails closed.

## Explicit shared metadata fields

| Field | Purpose |
| --- | --- |
| `id`, `version`, `sourceKind` | Stable action identity and type (`formula`, `dual`, `triple`) |
| `runtimeStatus`, `canExecute` | Nonauthorizing status; `canExecute` always false |
| `participants`, `sigils` | Combination membership and validated immutable Lights |
| `targeting`, `effectIntent` | Declared targeting and distinct emergent behavior; no applied effect |
| `resolution` | Metadata to route to existing `jrpg-stat-formula` or blocked `design-only`; not an execution call |

**Design choice:** The reservation step takes an explicitly typed `focus` fixture cost as a separate argument, rather than laundering an invented Arete/Echo cost into canonical ability definitions. Wider typed economies, loadout/job checks, and production authorization must be specified and approved before widening this contract.

## Tests and regression

Run after a genuine Godot 4.7.2 Standard import:

```sh
godot --headless --path godot --editor --quit
godot --headless --path godot --script res://tests/combat_ability_contract_test.gd
godot --headless --path godot --script res://tests/party_action_reservation_test.gd
godot --headless --path godot --script res://tests/tidebound_promise_review_test.gd
godot --headless --path godot --script res://tests/resonance_dual_review_scene_test.gd
godot --headless --path godot --script res://tests/first_wake_party_combat_authority_test.gd
```

The existing pinned CI workflow invokes all five tests. New tests cover formula metadata identity, unknown/blocked abilities, spoofed status and resolution, duplicate/swapped actors or mismatched Sigils, exact two-person action/focus receipts, no-alias plan results, invalid state/types, partner incapacity/insufficient Focus, and unchanged state on all denials. **Do not claim PASS until the new exact SHA's hosted steps actually finish.**

## Narrative integration checkpoint — open reconciliation

A newer creator-directed Chapter I opening has **Ionia aboard first** and **Lyra joining sometime after the ocean splashdown**, with Lyra's son introduced in subsequent story material. The older native Crossing party source still models `["ender", "lyra"]` with Ionia after Crossing. This is a **timeline/implementation divergence**; a passing technical test on the older path does not approve it as final narrative canon. Tidebound Promise currently has no Chapter I join-time trigger and must not be put into the pre-Lyra party. Keep it in an isolated encounter study pending storyboarding/party-state migration and creator review. Do not leak restricted lore.

## Still open

- Creator approval of exact combination names/effects, unlock scenes and relationship gates.
- Canonical typed action-cost economy and how to distinguish dual actions from base single-actor turns.
- Shared runtime effect resolver, status/field duration, damage/resistance semantics and target rules.
- Multi-encounter action scheduling, cancel/interrupt/resume and save/load recovery.
- Full approved art and character animations, true native gameplay UI, performance and accessibility/player acceptance.
- Independent review of unmerged PR lineage and Windows Defender/release boundary.

Authoritative architecture remains **native Godot forward development**; no new JavaScript gameplay. This document is public-safe and entirely proposal/implementation-boundary material.
