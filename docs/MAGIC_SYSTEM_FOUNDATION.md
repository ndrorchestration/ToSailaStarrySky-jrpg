# Aetherwake Magic System Foundation

Status: **implementation scaffold on a feature branch; no new spells are runtime-authorized yet**

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

The current implementation scaffold records two proposed Tier-I techniques per school:

### Aether

- **Aether Sense** — perception/exploration technique for Aether signatures, leaks, machinery, and fields.
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

Every proposed foundation technique therefore carries a null/unfrozen numeric cost.

## Runtime boundary

The browser-visible `AetherMasteryDefs` registry now exposes:

- school definitions,
- branch definitions,
- proposed foundation techniques,
- Ender's authored magic profile,
- foundation-candidate discovery,
- explicit runtime-readiness checks.

Readiness is fail-closed. A proposed spell returns:

`design_proposal_not_runtime_authorized`

until its design status is explicitly established and runtime integration is separately implemented.

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
- spell execution through the combat resolver,
- save-state schema for mastery,
- the four-affinity **Aetherwake** capstone.

The Aetherwake capstone remains intentionally undefined and plot-gated.

## Next implementation gates

The smallest safe progression from this foundation is:

1. approve or revise the Tier-I spell identities and resource semantics;
2. define persistent school-mastery state without changing combat eligibility;
3. add save/hydration support for mastery state;
4. integrate one low-risk spell end-to-end through the ordinary effect resolver;
5. verify combat/exploration behavior before widening the spell registry.

A strong first executable candidate is **Aether Sense** because it can prove school ownership, environmental targeting, and exploration magic without inventing damage balance or Arete costs.
