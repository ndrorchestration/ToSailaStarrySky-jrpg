# Aetherwake — JRPG Combat Direction

**Status:** TARGET ARCHITECTURE — approved 2026-09-21  
**Migration state:** current 2D6/PbtA runtime remains temporary compatibility behavior until replaced safely.

## Decision

Aetherwake's production combat system will use a conventional turn-based JRPG model:

- stats and declarative ability formulas determine the core result;
- abilities normally execute when use eligibility and targeting are valid;
- RNG is secondary and bounded rather than the primary outcome engine;
- there are no PbtA-style full/partial/failure outcome bands in the target combat model;
- there is no player-facing dice-roll system in normal combat;
- d20 is not part of the selected target model.

The current 2D6 runtime is preservation/adaptation residue. It remains testable only so the playable build stays intact during migration.

## Target resolution pipeline

1. Validate actor, action ownership/unlock state, target, and resource affordability.
2. Commit resource costs.
3. Resolve hit/evasion only when the action is not guaranteed.
4. Compute base effect magnitude from ability power and actor scaling.
5. Apply target defense/resistance and elemental/type modifiers.
6. Apply bounded critical and damage-variance rules where the ability permits them.
7. Resolve status/debuff application chances independently.
8. Apply ordinary effects through the generic effect resolver.
9. Resolve triggers, counters, follow-ups, and combination-art hooks.
10. Write encounter results back through the normal persistence boundary.

## Ability-definition direction

Combat abilities should converge on explicit metadata such as:

- targeting and target count;
- resource cost(s);
- power or base magnitude;
- offensive/scaling stat(s);
- defense or resistance interaction;
- element/damage type;
- accuracy policy;
- critical policy;
- bounded variance policy;
- status/debuff application chance;
- effect list;
- cooldown/charge/Heat/other special resource rules;
- combination-art prerequisites where applicable.

Exact numerical formulas and global percentage ranges remain balance decisions and should be tuned from playtest data rather than guessed during architecture migration.

## RNG policy

Acceptable RNG roles include:

- accuracy/evasion;
- critical hits;
- status application;
- small bounded damage variance;
- enemy AI choice;
- loot and other non-resolution systems.

RNG must not reintroduce a hidden success/partial/failure band system.

## Migration rule for preservation-era abilities

Existing declarations such as `2D6+Might`, `2D6+Presence`, or `10+: +1 next roll` are historical evidence about the prototype, not target semantics.

When migrating an ability:

- preserve its gameplay intent and authored effect evidence;
- preserve established resource facts where explicitly supported;
- discard the 2D6 roll instruction and PbtA outcome-band placement;
- redesign the action in the JRPG formula schema;
- require a new target-system balance contract before execution is authorized.

Examples:

- **Overdrive Strike:** preserve heavy EMP damage and Heat generation; redesign accuracy, power/scaling, defense interaction, Heat timing, and cost under the JRPG formula model.
- **Patchwork Shield:** preserve ally-protection and Scrap interaction; redesign timing, target selection, prevention/transfer semantics, and resource behavior without outcome bands.
- **Spirit Thread:** preserve target-ally healing and the historical 1–3 Vit range as prototype evidence; establish production healing power/scaling and target rules separately.
- **Aether Pulse:** discard the synthetic 2D6 outcome model as target balance evidence; future tuning should evaluate formula power, scaling, defense/resistance, resource efficiency, accuracy/crit policy, and encounter time-to-defeat.

## Companion-action admission rule

Preservation-era companion declarations may retain legacy roll text and outcome
bands as source evidence, but those fields are not admissible production
contracts.

Before any companion action can be considered for execution, its candidate must
provide:

- a `jrpg-stat-formula` resolution binding with explicit formula identity,
  version, kind, and resolved parameters;
- explicit targeting and target-count policy;
- only bounded RNG uses allowed by the combat-system policy;
- explicit costs;
- executable effect descriptors;
- an execution adapter;
- a persistence policy.

A candidate containing legacy `roll` or `outcomes` fields fails admission.
Completeness is still distinct from authorization: a structurally complete
candidate remains non-executable until a later explicit integration gate.

## Compatibility boundary

Until the migration reaches live combat:

- current browser/runtime tests may continue to exercise the legacy 2D6 implementation;
- legacy probability tools may remain as historical runtime-reference utilities;
- no new production design should use 2D6 outcome bands as its target contract;
- documentation must clearly distinguish CURRENT LEGACY RUNTIME from TARGET JRPG COMBAT.

## First implementation milestone

The first runtime migration should replace one ordinary Ender action end-to-end with the formula pipeline while keeping the rest of combat on the compatibility path. That vertical conversion should establish the reusable formula schema, accuracy/crit/status policy boundaries, resolver integration, UI feedback, and regression tests before converting the remaining action set.
