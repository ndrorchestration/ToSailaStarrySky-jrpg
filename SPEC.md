# Aetherwake JRPG — Technical Specification

**Development stage:** pre-alpha  
**Current runtime:** p5.js global mode, 960×640  
**Current entry point:** `index-embedded.html`  
**Architecture rule:** preserve a working playable loop during every migration phase.

---

## 1. Status model

This specification distinguishes three kinds of information:

- **CURRENT IMPLEMENTATION** — behavior present in the preservation build.
- **TARGET ARCHITECTURE** — approved direction for the production game.
- **OPEN DESIGN** — intentionally unresolved; do not hardcode assumptions.

The current integrated runtime and the long-term architecture are not yet identical.

---

## 2. Playable roster

### TARGET ARCHITECTURE

Aetherwake has exactly five authored playable protagonists:

1. **Ender** — lead protagonist; native job **Rift Scholar**
2. **Lyra**
3. **Ionia**
4. **Reson**
5. **Aepex**

Combat uses exactly three active characters:

```text
ROSTER[5] → select ACTIVE_PARTY[3] → combat
```

Rules:

- all five retain persistent progression,
- bench status must not create a separate/frozen character copy,
- formation changes initially occur outside combat at preparation/safe states,
- no in-battle swapping is required for the first production implementation,
- Triple Arts always involve all three active combatants.

### CURRENT IMPLEMENTATION

The preservation build still contains the superseded prototype model:

- Ender fixed in slot 0,
- two player-created companion slots,
- prototype jobs: Sky-Sailor, Engine-Wright, Aether-Weaver,
- Ender implementation residue may still display **Rift Scholar + Dreamwright**.

These facts are implementation provenance, not current character canon.

---

## 3. Persistent character state

### TARGET ARCHITECTURE

Persistent progression belongs to canonical roster records, not combat copies.

Minimum character-state domains:

- identity / stable ID,
- native job,
- school affinities,
- level / XP,
- school and branch mastery,
- job mastery/training,
- unlocked abilities,
- unlocked passives,
- learned hybrids,
- equipment/loadout,
- bonds/relationships,
- story flags,
- long-term resources.

`ACTIVE_PARTY[3]` should contain IDs/references to roster records.

Combat-local state may contain:

- encounter HP deltas where appropriate,
- temporary statuses,
- turn order,
- encounter fields,
- short-lived buffs/debuffs,
- transient targeting/setup state.

Post-combat results write back to the persistent roster according to progression rules.

### OPEN DESIGN

Inactive-character XP/mastery sharing policy remains open.

---

## 4. Combat system

### CURRENT IMPLEMENTATION

Resolution:

- 2D6 + relevant stat
- 10+ = full success
- 7–9 = partial success / complication
- 6− = failure

Resources currently include:

- Vitality,
- Echoes,
- Aether,
- Heat,
- Scrap,
- Resonator Staff charges.

Current flat actions:

1. Resonator Staff
2. Uncover Truth
3. Shared Dream
4. Mycelial Ledger
5. Hold
6. Wind Ward
7. Aether Seal
8. Rest

Current prototype level unlocks:

- level 3 — Wind Ward
- level 4 — Aether Seal
- level 5 — Rest

### TARGET ARCHITECTURE

Combat action availability derives from character state and declarative definitions.

Core registries:

- `ABILITY_DEFS`
- `SCHOOL_DEFS`
- `TREE_DEFS`
- `JOB_DEFS`
- `HYBRID_DEFS`
- `DUAL_ART_DEFS`
- `TRIPLE_ART_DEFS`

Learn eligibility and use eligibility must be separate checks.

The generic resolver should process ordinary effects without action-ID-specific branching.

Planned effect-component vocabulary includes:

- damage,
- healing/restoration,
- resource changes,
- buffs/debuffs,
- status,
- position/spatial,
- field/terrain,
- mark/trigger,
- interrupt/counter/reaction,
- reveal/information,
- summon/deploy/construct,
- link/network,
- transform/alter,
- conditional/branch,
- sequence,
- rare script hook.

Repeated use of script hooks for ordinary mechanics indicates the vocabulary is incomplete.

---

## 5. Magic and progression

### ESTABLISHED DIRECTION

Aether is a distinct external/world-accessible magical system, not generic mana.

Recognized major school/domain families include:

- Elemental
- Arcane
- Psychic
- Spirit

Ender has special innate affinities including:

- Aether
- Resonance / Harmonic
- Correspondence
- Lumen

Ender may eventually learn broadly across magical forms, but potential does not equal automatic mastery.

Jobs and schools are separate concepts:

- **school** = aspect/form of magic,
- **job** = combat role, profession, tradition, training package, access modifiers, passives, equipment relationships.

Jobs should not simply own spell lists.

### OPEN DESIGN

Several proposed schools/domains, resource relationships, and companion job definitions remain unresolved.

---

## 6. Combination arts

### TARGET ARCHITECTURE

Hierarchy:

1. Cross-School Arts — one character, two schools
2. Fusion Arts — deeper two-school interaction
3. Synthesis Arts — one character, three schools
4. Personal Grand Synthesis — four+ schools
5. Dual Arts — two characters
6. Triple Arts — all three active characters

Combination eligibility should check actual state:

- component abilities,
- actors present,
- bond/synchrony,
- resources,
- readiness,
- positioning/status/setup,
- registered combo definition.

Triple Arts must be genuinely simultaneous. If one character taking three sequential turns can approximately reproduce the result, the effect is too weak for a Triple Art.

---

## 7. World and quest vertical slice

### CURRENT IMPLEMENTATION

The prototype includes:

- Columbus / sky-layer exploration concepts,
- day/night behavior,
- Covenant Field interaction,
- NPC dialogue,
- shop/ledger/quest/character-sheet overlays,
- environmental hazards,
- several enemy types,
- quest flow:

```text
Signal → Crossing → Contact → Choice → Wake
```

The current quest is a vertical slice, not the complete campaign.

### TARGET CAMPAIGN

The full campaign will expand story acts, recruitment timing, character arcs, relationships, regions, bosses, exploration interactions, and the Wake/Core mystery after the underlying character/combat architecture is stable.

---

## 8. Runtime architecture

### CURRENT IMPLEMENTATION

- `index-embedded.html` is the current browser entry point.
- `aetherwake.js` is the current integrated runtime/preservation artifact.
- `modules/char-create.js` is loaded at runtime.
- several other `modules/*.js` files are older mirrors/reference copies and may not match the integrated runtime.

### TARGET ARCHITECTURE

Move toward one canonical editable source tree with explicit subsystem APIs:

```text
src/
  core
  world
  combat
  characters
  party
  abilities
  progression
  ui
```

Self-contained/bundled runtime files should eventually be generated outputs rather than independently edited copies.

Reduce `window.*` coupling incrementally; do not rewrite the entire engine at once.

---

## 9. Save/persistence boundary

Before progression content becomes large, introduce:

- explicit save-schema version,
- stable character IDs,
- migration functions between schema versions,
- separation of persistent and encounter-local state.

Save format is a compatibility boundary and should not be treated as an afterthought.

---

## 10. Verification requirements

Every architecture phase must preserve a playable smoke path.

Canonical smoke target:

```text
boot/title
→ character creation / onboarding
→ WORLD
→ start encounter
→ resolve ordinary action
→ resolve ability
→ finish/leave combat
```

Automated tests should also cover:

- character identity persistence,
- party references,
- ability eligibility,
- resource spending,
- 10+/7–9/6− resolution bands,
- progression unlocks,
- formation validity,
- Dual/Triple eligibility as those systems land.

---

## 11. Migration order

1. stabilize and merge the newest playable baseline,
2. establish persistent `ROSTER[5]`,
3. establish `ACTIVE_PARTY[3]`,
4. freeze first effect vocabulary,
5. extract registries without changing behavior,
6. generalize ability access/resolution,
7. migrate authored roster/onboarding,
8. implement school/job/mastery progression,
9. implement formation and combination arts,
10. expand campaign content,
11. production hardening and balance.

**Non-negotiable:** avoid a single rewrite of character creation, combat, progression, and party state at the same time.
