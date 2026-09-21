# Aetherwake Magic System Foundation

Status: **implementation scaffold on a feature branch; Aether Sense is the first established runtime technique, while all other foundation spells remain unauthorized proposals**

This document describes the first code-owned foundation for Aetherwake's broader magic system. It preserves the existing combat/progression baseline while making the authored Ender magic structure explicit and machine-checkable.

## Established character facts

Ender's formal native job is **Rift Scholar**.

His established innate magical affinities are:

- **Aether**
- **Resonance / Harmonic**
- **Correspondence**
- **Lumen**

The affinities are established authored facts. The detailed spell trees below remain design proposals until separately approved.

Companion affinities and native jobs remain explicitly **UNKNOWN** where creator canon has not settled them. The runtime must not infer a school or job from temporary preservation-era combat roles.

## Proposed school structure

Each Ender affinity currently has three proposed branches:

| School | Branches | Tactical identity |
| --- | --- | --- |
| Aether | Flow · Ward · Flux | resource control, infrastructure, fields, sealing, discharge |
| Resonance | Concord · Dissonance · Chorus | frequency, synchronization, disruption, counters, resonant fields |
| Correspondence | Traverse · Anchor · Fold | distance, positioning, boundaries, teleportation, impossible geometry |
| Lumen | Radiance · Dawn · Prism | light, restoration, revelation, cleansing, refraction |

These branch names and detailed spell-tree contents are **DESIGN_PROPOSAL**, not frozen canon.

## Tier-I foundation techniques

The current implementation scaffold records two Tier-I foundation techniques per school. **Aether Sense is now established and integrated for Ender; the other seven remain design proposals.**

### Aether

- **Aether Sense** — **ESTABLISHED / INTEGRATED for Ender.** A zero-cost exploration technique for explicit Aether signatures, leaks, machinery, active fields, and Aether-bearing entities. In WORLD, press **V** to scan; results are written to the ledger and briefly visualized without advancing quest state.
- **Aether Pulse** — baseline active Aether discharge.

### Resonance / Harmonic

- **Resonant Ping** — probes a target's frequency profile for weakness or instability.
- **Attune** — tunes Ender's frequency in preparation for later Resonance techniques.

### Correspondence

- **Spatial Sense** — perceives distortions, seams, hidden paths, and true distance.
- **Rift Step** — short-range instantaneous reposition.

### Lumen

- **Lumen Spark** — controlled magical light for illumination, revelation, and offense.
- **Solar Mend** — restorative Lumen warmth.

## Resource boundary

The code intentionally does **not** assign numeric costs to these techniques.

- Aether techniques may bind to the external **Aether** resource where appropriate.
- Resonance, Correspondence, and Lumen may eventually draw on **Arete**, but those costs and runtime semantics are not frozen.
- Passive/perception techniques may ultimately have no direct resource cost.
- **Echoes are not redefined here** and are not silently treated as Arete.

Every still-proposed foundation technique therefore carries a null/unfrozen numeric cost. Aether Sense is explicitly zero-cost and retains a null numeric cost because it does not consume a resource.

## Runtime boundary

The browser-visible `AetherMasteryDefs` registry now exposes:

- school definitions,
- branch definitions,
- proposed foundation techniques,
- Ender's authored magic profile,
- foundation-candidate discovery,
- explicit runtime-readiness checks.

Readiness remains fail-closed. A still-proposed spell returns:

`design_proposal_not_runtime_authorized`

until its design status is explicitly established and runtime integration is separately implemented.

**Aether Sense is the first exception established through that gate.** It is explicitly starting-owned by Ender, returns `canUse: true`, and routes through a dedicated read-only exploration scanner. School access alone still does not grant any other spell.

This prevents a data scaffold from silently becoming a playable mechanic.

## Explicit non-claims

This slice does **not** establish:

- mutable school mastery ranks or mastery XP,
- numeric spell costs,
- Arete runtime storage/spending,
- spell learning or acquisition rules,
- equipped spell slots,
- companion school assignments,
- hybrid / Dual / Triple Arts,
- foundation-spell execution through the combat resolver (Aether Sense is exploration-only),
- save-state schema for mastery,
- the four-affinity **Aetherwake** capstone.

The Aetherwake capstone remains intentionally undefined and plot-gated.

## Foundation spell admission gate

The repository now separates **semantic contract completeness** from
**runtime authorization** for foundation spells.

`modules/foundation-spell-admission.js` validates two contract shapes:

- **exploration-readonly** — zero/declared resource cost, no roll table, no
  effect outcomes, read-only mutation policy, explicit adapter binding, and no
  persistence;
- **combat-2d6** — explicit resource cost, 2D6 stat/bands, complete
  common/success/partial/failure effect profiles, implemented effect semantics,
  execution adapter binding, and persistence policy.

`modules/foundation-spell-contracts.js` records current evidence:

- **Aether Sense** — established runtime contract; admission resolves
  `runtime-ready`;
- **Aether Pulse** — unresolved draft only. It preserves the known Aether
  resource binding, combat/offense role, 2D6 global combat shape, and damage
  requirement, but explicitly leaves cost, governing stat, outcome tables,
  starting ownership, execution adapter, and persistence policy unresolved.

A synthetic structurally complete Aether Pulse contract is used only in tests
to prove that **contract completeness cannot override design/runtime
authorization**. The real Aether Pulse definition remains
`design_proposal / not_integrated`.


## Synthetic Aether Pulse evaluation

The repository now has a deliberately non-authorizing balance-measurement surface:

`modules/aether-pulse-synthetic-evaluation.js`

It exists so proposed Aether Pulse shapes can be measured **before** any values are
promoted into the spell contract.

The evaluator:

- enumerates all **36 exact 2D6 outcomes** for a supplied integer stat modifier;
- preserves the established global 10+ / 7–9 / 6− outcome bands by default;
- accepts explicitly marked `synthetic-test-only` candidate fixtures;
- measures expected enemy damage, expected self-damage, and expected enemy
  damage per Aether;
- can sweep the same synthetic candidate across multiple stat modifiers;
- stamps every result `designEstablished: false` and
  `runtimeAuthorized: false`.

The candidate numbers in the automated tests are **test fixtures only**. They are
not recommendations, balance decisions, starting ownership, or proposed canon.
The real `foundation-spell-contracts.js` Aether Pulse record remains unchanged:
cost, governing stat, outcome table, ownership, adapter, persistence, and runtime
authorization are still unresolved.

This creates a useful sequence:

`synthetic measurement → explicit design decision → complete admission contract → runtime authorization`

and prevents synthetic tuning evidence from bypassing the design/admission gate.



## Synthetic design-space comparison

The synthetic evaluator can now compare an **explicit caller-supplied candidate
set** without choosing a preferred spell design.

For one common modifier it can calculate a Pareto frontier across three
mechanical dimensions:

- higher expected enemy damage;
- lower expected self-damage;
- lower Aether cost.

A candidate is removed from that frontier only when another synthetic candidate
is no worse on all three dimensions and strictly better on at least one. This
preserves real tradeoffs instead of collapsing them into a hidden score.

The frontier deliberately refuses mixed-modifier comparisons. A Wits +2 result,
for example, cannot be placed on the same frontier as a Might -1 result without
first making the modifier context explicit. Candidate sets can still be swept
across multiple modifiers to show sensitivity.

Automated fixtures include a deliberately dominated candidate only to prove the
filter works. Fixture identities and numbers remain **test-only**. The tooling
does not generate a recommended candidate, assign weights, select a stat, or
promote anything into the real Aether Pulse contract.

## Current-runtime balance reference

Synthetic candidate measurements can now be compared to the **current prototype
combat scale** through:

`modules/aether-pulse-runtime-reference.js`

The reference is intentionally descriptive rather than prescriptive. It records
current runtime facts that materially affect interpretation of a hypothetical
Aether Pulse:

- current prototype Ender: **Wits +2**, **Might -1**;
- current Aether pool: **4 current / 6 maximum**;
- current Staff Strike capacity: **2 charges**;
- current ordinary enemy HP examples: **8, 10, 12, 14**;
- charged Staff Strike success damage: mean **5.5** from `1d6+2`;
- partial Staff Strike damage: mean **4.5** from `1d6+1`;
- current Staff Strike uses Might and therefore evaluates against the present
  **−1** prototype modifier by default.

The reference is protected by source-drift tests against `modules/combat.js`
and `modules/ability-defs.js`. If those observed facts change, the reference
must be reconciled instead of silently carrying an obsolete baseline forward.

It can report, for any explicitly synthetic Pulse candidate:

- expected enemy damage versus the currently charged Staff Strike;
- expected self-risk difference;
- current/max-Aether cast capacity for the proposed cost;
- expected total damage across that resource envelope;
- expected fraction of each current enemy HP band removed per cast.

**This comparison does not make Staff Strike the target balance for Aether
Pulse.** Staff Strike is a charged weapon technique with a different role,
resource model, and variance profile. The reference exists to reveal scale and
tradeoffs, not to select a winner or authorize a design.

## Next implementation gates

The smallest safe progression from the current foundation is:

1. keep Aether Sense's zero-cost exploration contract stable through browser verification;
2. preserve the distinction between innate access, broad learnability, learned ownership, and runtime authorization;
3. define persistent school-mastery state only when an actual mutable mastery mechanic is ready, using an explicit save-schema migration;
4. establish the next individual spell's design and resource semantics before implementing it;
5. add combat spell execution only after its effect semantics are supported by the ordinary resolver.

**Aether Pulse** is the natural next Aether candidate once its cost, roll/effect contract, and combat-resolver path are explicitly established. Resonance, Correspondence, and Lumen resource-bearing techniques remain blocked on unresolved inner-resource semantics rather than silently consuming Echoes or guessed Arete.
