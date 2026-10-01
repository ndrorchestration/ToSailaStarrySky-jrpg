# Aetherwake Weapon Mastery & Technique Architecture — Proposal v0.1

**Status:** PROPOSAL / DESIGN-ONLY / NOT CREATOR-LOCKED / NOT RUNTIME AUTHORITY  
**Refreshed:** 2026-10-01  
**Provenance:** preserves the still-useful weapon-skill architecture from historical PR #144 without replaying its stale README/SPEC/Magic-System edits.

## Purpose

Define a future weapon-technique progression model that fits Aetherwake's current shared combat architecture without inventing a second combat engine or overriding the locked starting weapon identities.

This document does **not** authorize weapon mastery in the runtime, assign final job permissions, define auto-equip scoring, or convert any proposal into character canon.

## Existing authority this proposal must respect

Current locked starting/main martial identities remain:

- Ender — fighting staff;
- Reson — sword, with assault-style rifle as locked secondary/ranged support;
- Aepex — martial arts;
- Ionia — mace;
- Lyra — chakram.

These identities are owned by `docs/EQUIPMENT_WEAPON_SYSTEM.md`. A future mastery system may add techniques and progression; it may not silently replace those creator-directed identities.

Magic and weapon use remain independent unless an individual technique explicitly requires both.

## Shared execution contract

Spells, weapon techniques, job techniques, items, hybrid arts, Dual Arts, Triple Arts, and other admitted combat actions should converge on the existing shared pipeline rather than create parallel resolvers:

```text
source catalog
  → normalize to AbilityDefinition
  → validate admission / prerequisites
  → resolve formula family
  → emit typed effects
  → effect resolver mutates state
  → UI / persistence consume the same definition
```

Weapon content should extend the current ability/formula/effect substrate. It should not introduce a second damage, status, or targeting engine merely because the source is martial rather than magical.

## Weapon mastery as a distinct progression axis

**Proposal:** each supported weapon family may eventually own a five-rank technique progression.

This is intentionally separate from:
- magic-school mastery;
- character level;
- job mastery;
- equipment quality.

A martial/magic hybrid may require both weapon and school prerequisites, but one must not be silently inferred from the other.

### Proposed five-rank shape

| Rank | Working purpose | Design test |
|---|---|---|
| **1 — Handling** | Establish the family's basic verb and readable handling identity. | Does it immediately feel different from another weapon family? |
| **2 — Extension** | Add reliable reach, stance, guard, mobility, setup, or resource utility. | Does mastery change available decisions rather than only coefficient size? |
| **3 — Specialization** | Establish the mature build-defining loop. | Can the player deliberately build around the family's identity? |
| **4 — Mastery** | Add advanced counter, Break/Stagger, routing, stance transition, armor interaction, mobility, or combo behavior. | Does the system gain a new relationship rather than just more damage? |
| **5 — Signature** | Admit a signature/master technique or transformation of the family loop. | Does the capstone express mastery without invalidating every lower-rank technique? |

These rank names are working design labels, not creator canon or final UI terminology.

## What weapon techniques should emphasize

Martial techniques should primarily create decisions through:

- stance;
- reach and threat area;
- movement and repositioning;
- guard pressure;
- Break/Stagger;
- counters and retaliation windows;
- combo routing;
- armor or barrier interaction;
- sustained physical pressure;
- timing and recovery;
- weapon-family identity.

They should not become "spells with cheaper resource costs."

## Interaction policy

Do **not** maintain an exhaustive weapon-family × weapon-family matrix merely because combinations are mathematically possible.

Prefer three layers:

1. **Weapon-family tactical identity** — what each family reliably does.
2. **Explicit matchup/counter rules** — only where a matchup materially changes play.
3. **Weapon × magic crossover hooks** — only where the relationship creates meaningful behavior.

Examples of crossover categories that remain compatible with current magic boundaries:

- Elemental / Arcane imbues;
- Resonance timing, vibration, shatter, or harmonic guard-break;
- Correspondence reach, routing, projectile geometry, or redirection;
- Aether-powered conductors, barriers, resonators, or engineered weapons;
- Lumen targeting, visibility, refraction, or radiant interaction without redefining Lumen as Holy.

Proposed magic domains remain unavailable for weapon crossover until those domains are separately admitted.

## Reuse rule

The existing magic mastery/access/study work provides a useful **pattern**, not a data model that weapon mastery must copy wholesale.

A later weapon system may reuse:
- explicit ranks;
- fail-closed prerequisite checks;
- pure access evaluation;
- explicit learning/training transactions;
- stable persistence ownership.

It should keep:
- weapon mastery separate from magic-profile state;
- acquisition costs and teachers OPEN until designed;
- runtime admission separate from design-catalog existence.

## Relationship to jobs and equipment

Current open decisions remain open:

- job/class weapon-permission matrix;
- armor-family permissions;
- exact Best Fit / Auto-Equip scoring;
- final loot/crafting/upgrade economy;
- unresolved secondary weapons other than Reson's locked rifle.

A future job may affect weapon access, training rate, technique availability, passives, or equipment permissions. A job should not automatically become the sole owner of a character's durable weapon mastery unless explicitly designed that way.

## Minimal future implementation order

If this proposal is later approved for implementation, the lowest-risk sequence is:

1. define weapon-family registry/status vocabulary;
2. define one normalized weapon-technique `AbilityDefinition` shape;
3. normalize one existing physical action as a compatibility proof;
4. create one weapon-family Rank 1–5 design catalog;
5. implement pure mastery/access validation;
6. define training/acquisition rules separately;
7. define persistence/version ownership;
8. admit one family into runtime behind focused tests;
9. only then widen UI, jobs, hybrid arts, and additional families.

## Explicit non-goals

This proposal does not establish:

- final weapon-family roster;
- final rank names;
- exact technique names;
- damage coefficients;
- mastery XP curves;
- training costs;
- teachers/quests;
- auto-equip scoring;
- final job permissions;
- armor rules;
- new character weapon canon;
- runtime save-schema changes.

## Promotion rule

No part of this proposal becomes runtime or creator canon merely by being documented.

Promotion requires:
**creator/design approval → bounded data contract → persistence ownership → executable candidate → automated evidence → human/player review where presentation/feel is involved.**
