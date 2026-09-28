# Aetherwake Equipment & Weapon System — Working Authority

Status: **PARTIALLY LOCKED / IMPLEMENTATION DESIGN**

## Locked character weapon identity

| Character | Main weapon | Secondary / ranged |
|---|---|---|
| Ender | Fighting staff | OPEN |
| Reson | Sword | **Assault-style rifle — LOCKED** |
| Aepex | Martial arts | OPEN |
| Ionia | Mace | OPEN |
| Lyra | Chakram | OPEN |

These are the characters' starting/main martial identities. Do not silently replace them because a later job/class can equip another weapon family.

## Magic independence

Magic and class abilities are not inherently tied to a weapon.

Ender's staff is a practical fighting staff. He does **not** require a wizard staff, rod, or focus to cast Rift Scholar magic. The same principle applies to other characters unless a future individual skill explicitly names a weapon-family requirement.

Weapon bonuses may modify magic or abilities, but that is equipment behavior rather than a casting prerequisite.

## Current open decisions

The following remain deliberately unresolved:

- Ender secondary/ranged weapon.
- Aepex secondary/ranged weapon.
- Ionia secondary/ranged weapon.
- Lyra secondary/ranged implementation, including whether her chakram ultimately fills both close and ranged roles.
- Detailed job/class weapon-permission matrix.
- Armor-family permissions.
- Exact auto-equip scoring algorithm.
- Final crafting/upgrade economy and component tiers.

Do not promote earlier brainstormed twin handguns, crossbow, ranged staff tools, or chakram ricochet behavior into canon until explicitly approved.

## Design direction retained for later system work

The current intended architecture remains compatible with:

- job/class-based weapon permissions;
- swappable equipment rather than permanently character-embedded weapons;
- an FFT-style **Best Fit / Auto-Equip** option;
- standard weapons acquired through shops, drops, treasure, quests, and exploration;
- party-developed upgradeable weapons that can grow into strongest-overall character options;
- rare unique finds that may remain excellent specialist equipment or become components for high-tier party upgrades.

These are system-design directions, not yet complete numeric/economy specifications.

## Art-production consequence

Character silhouette/animation work should now assume:

- Ender staff combat poses;
- Reson sword combat poses plus rifle-ready secondary support;
- Aepex martial-arts combat poses;
- Ionia mace combat poses;
- Lyra chakram combat poses.

Do **not** build permanent secondary-weapon silhouettes for Ender, Aepex, Ionia, or Lyra yet.

## Boundary

This document does not admit assets, finalize job balance, define final loot tables, or authorize secondary weapon choices beyond Reson's rifle.


## Ender starter staff production binding
Detailed visual/animation candidate: `docs/ENDER_STARTER_STAFF_PRODUCTION_BRIEF.md`.

The locked rule is weapon family + function: **fighting staff, physical combat weapon, magic-independent**. The brief's exact construction/material/name details remain provisional until visually accepted.
