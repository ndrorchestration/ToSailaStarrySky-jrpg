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

The development branch now contains a persistent party-state bridge:

- `ROSTER` has exactly five stable identities in canonical order: Ender, Lyra, Ionia, Reson, Aepex;
- `ACTIVE_PARTY` has exactly three direct references into `ROSTER`, initially Ender/Lyra/Ionia;
- `world.player === ROSTER[0] === ACTIVE_PARTY[0]`, so the lead character is no longer duplicated across WORLD and persistent party state;
- the preservation character-creation flow remains temporarily in use as onboarding input for the first three records;
- its two player-created companion names and Sky-Sailor / Engine-Wright / Aether-Weaver jobs remain prototype residue rather than authored canon;
- Reson and Aepex currently exist as identity/schema shells only;
- formation mutation and true three-character combat are not implemented in this phase;
- Ender implementation residue may still display **Rift Scholar + Dreamwright**, while canonical `nativeJob` is **Rift Scholar**.

The authored identities are canonical; prototype onboarding/mechanics remain migration provenance until the later authored-roster phase.

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

### CURRENT IMPLEMENTATION

`modules/party-state.js` owns the session-persistent roster arrays and validates their identity/reference invariants. The World module's original player object is adopted as `ROSTER[0]` rather than replaced. The current combat system still uses an encounter-local copy for resolution, but `finishCombat()` writes persistent fields back to that canonical roster-backed World record.

The first three records are mechanically populated through the preservation onboarding adapter. Reson and Aepex intentionally remain unimplemented shells; no unresolved job, progression, or ability semantics are fabricated.

Each canonical roster record now also carries a validated `magicProfile`. Ender's profile records only his established innate affinities (**Aether, Resonance/Harmonic, Correspondence, Lumen**) while all mastery ranks remain zero by default. Lyra, Ionia, Reson, and Aepex carry explicit OPEN affinity status with empty affinity/mastery sets. Prototype onboarding does not overwrite these canonical profiles. This state is session-persistent through the roster layer but does not yet grant spells or affect combat.

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

These unlocks are now enforced at use time. At level 1, the eligible action set is Staff Strike, Uncover Truth, Shared Dream, Mycelial Ledger, and Hold. Wind Ward, Aether Seal, and Rest remain visible in stable key slots but reject use until their IDs enter `player.unlockedAbilities`.

Current use eligibility is centralized in `modules/ability-defs.js` v0.2.0. The prototype's existing numeric rule is preserved exactly as `tier + cost`, but affordability is preflighted transactionally across pooled Echo+Aether before a turn or resource is consumed. The combat UI and runtime use the same cost function. Normal victory XP now routes through `awardXP()`, so crossing a threshold executes `levelUp()` and makes newly learned actions eligible.

The development branch now separates current combat metadata from execution:

- `modules/effect-vocabulary.js` establishes effect vocabulary v0.1;
- frozen kinds are `damage`, `restore`, `resource`, `modifier`, `status`, `reveal`, and `movement`;
- `modules/ability-defs.js` v0.2.0 owns canonical metadata/order, unlock eligibility, legacy resource-cost calculation, pooled affordability, and current use eligibility for the eight actions;
- `modules/progression-defs.js` owns the current level-3/4/5 unlock table;
- `AetherCombat.resolveTurn()` remains the action/outcome branch authority;
- ordinary damage, restoration, and resource mutations inside `resolveTurn()` are now executed through `modules/effect-resolver.js`;
- the resolver fails closed on unsupported implemented effect kinds and treats `DECLARED_NOT_APPLIED` effects as explicit no-ops;
- `resolveTurn()` now rejects locked actions before consuming a turn or resources;
- the combat panel exposes stable keys 1–8 while visibly marking locked actions;
- CI rejects reintroduced direct ordinary mutations inside `resolveTurn()` and validates the browser path after resolver integration.

Known semantic debt remains explicit rather than being silently upgraded:

- Uncover Truth's reveal and +1-next-roll semantics are currently narrated/local-only rather than durable applied state;
- the Shared Dream +1-next-action branch is likewise not persisted/applied;
- current legacy cost/tier behavior is preserved exactly;
- modifier/reveal/status/movement execution is not generalized merely because those kinds exist in the vocabulary.

### ESTABLISHED EFFECT VOCABULARY — v0.1

The first frozen ordinary effect kinds are:

- damage,
- restoration,
- resource change,
- modifier,
- status,
- reveal/information,
- movement/spatial.

This is intentionally smaller than the full long-term design vocabulary. Field/terrain, marks/triggers, interrupt/reaction, summon/deploy, link/network, transform, conditional/branch, sequence, and script-hook policy remain design extensions rather than frozen runtime contracts.

### ESTABLISHED RESOLVER BOUNDARY — v0.1

`modules/effect-resolver.js` is now live for the ordinary mutation subset:

- player/enemy damage,
- vitality restoration,
- Echo/Aether/Heat/Scrap/Staff-charge deltas.

Current invariants:

- player damage clamps at zero;
- enemy HP preserves the prototype's existing unclamped behavior;
- vitality restoration clamps at `maxVit`;
- bounded resources clamp to their existing min/max rules;
- unsupported implemented effect kinds fail closed;
- `DECLARED_NOT_APPLIED` effects do not mutate state;
- the explicit post-defeat floor `state.player.vit = 1` remains a special combat rule outside the generic resolver.

The resolver does **not** yet own PbtA outcome selection, action-specific branching, randomness, status semantics, movement semantics, reveal state, modifier persistence, XP, or level-up rules. XP/level progression remains combat-orchestration logic, but normal victory rewards now reach that progression path correctly.

### ESTABLISHED USE/SECONDARY BOUNDARY

- locked or underfunded actions are rejected before turn/resource consumption;
- Echoes are still spent before Aether, preserving the current payment order;
- the resource-cost formula remains the legacy `tier + cost` rule;
- a newly admitted primary action clears any previous secondary opportunity;
- a successful ability opens a secondary opportunity only when that same ability remains usable after primary costs;
- a secondary attempt delegates to ordinary `resolveTurn()` admission and is consumed once;
- failed later abilities cannot inherit stale secondary availability.

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

Effect vocabulary v0.1 already covers the ordinary current-runtime families listed above. Future extensions may add field/terrain, mark/trigger, interrupt/counter/reaction, summon/deploy/construct, link/network, transform/alter, conditional/branch, sequence, and a rare script-hook escape hatch as those mechanics become executable requirements.

Repeated use of script hooks for ordinary mechanics would indicate the vocabulary is incomplete.

---

## 5. Magic and progression

### ESTABLISHED DIRECTION

Aether is a distinct external/world-accessible magical system, not generic mana.

The elemental design contract uses **four primal trees**:

- Fire
- Water
- Air
- Earth

Advanced/specialized elemental trees currently admitted to the design registry are:

- Frost
- Lightning
- Crystal
- Metal
- Plasma
- Sonic
- Storm

Sand/Dust is an Earth application, Steam/Mist is a Water application, and Magma/Glass are Earth applications strengthened or unlocked through Fire knowledge. These are not separate mastery trees.

Recognized major non-elemental school/domain families include:

- Aether
- Lumen
- Resonance / Harmonic
- Correspondence
- Arcane
- Psychic
- Spirit

Proposed later/high-order domains remain explicitly status-labeled in `modules/magic-defs.js` and `docs/MAGIC_SYSTEM.md`; proposal status is not silently converted into story canon.

Ender has special innate affinities including:

- Aether
- Resonance / Harmonic
- Correspondence
- Lumen

**Affinity and mastery are separate contracts.** An innate affinity does not automatically grant Rank 1 mastery, free abilities, or runtime authorization. `modules/character-magic-profile.js` v0.1 records Ender's four established affinities while leaving his mastery profile at zero by default. Lyra, Ionia, Reson, and Aepex retain open affinity status rather than receiving inferred schools from thematic fit.

Ender may eventually learn broadly across magical forms, but potential does not equal automatic mastery.

Jobs and schools are separate concepts:

- **school** = aspect/form of magic,
- **job** = combat role, profession/tradition/training package, access modifiers, passives, equipment relationships.

Jobs should not simply own spell lists.

Magic mastery uses five detailed ranks that can be compressed to three UI tiers:

- Ranks 1–2 = Foundation
- Ranks 3–4 = Advanced
- Rank 5 = Grandmaster

Cross-mastery should change behavior rather than merely add flat damage. The initial thresholds are 2+2 minor interaction, 3+3 Cross-School Art, 4+4 advanced synergy, and 5+5 Grand Synthesis.

Holy/Unholy are not ordinary schools. Sacred/corrupted metaphysics are modeled through modifiers such as Sanctified, Profaned, Blessed, Cursed, Hallowed, and Blighted. Lumen is not synonymous with Holy; Umbral/Shadow is not synonymous with Unholy.

Dreaming remains plot-bound exceptional access rather than an ordinary learnable school.

### DESIGN REGISTRY BOUNDARY

`modules/magic-defs.js` v0.1 is a target-design registry only. `modules/magic-mastery.js` v0.1 adds pure prerequisite, threshold, and reaction eligibility evaluation against that registry. Neither module grants mastery, mutates roster state, unlocks spells, or authorizes use of any new spell in the preservation runtime. Unsupported status, field, persistence, acquisition, and executable synthesis mechanics remain fail-closed until the resolver, save schema, UI, and automated tests support them.

### OPEN DESIGN

Exact spell catalogs, mastery XP curves, resource costs, school teachers/quests, proposed-domain canon status, companion magical ownership, and final Grand Synthesis names remain unresolved.

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
- `modules/effect-vocabulary.js` loads the frozen effect contract before combat construction.
- `modules/ability-defs.js` and `modules/progression-defs.js` load the canonical current action/unlock registries.
- `modules/magic-defs.js`, `modules/magic-mastery.js`, and `modules/character-magic-profile.js` load before party state and provide fail-closed magic taxonomy/profile contracts.
- `modules/party-state.js` is the authoritative persistent roster / active-party reference layer and now attaches validated magic profiles to all five canonical records.
- `aetherwake.js` is the current integrated runtime/preservation artifact and remains the current combat executor.
- `modules/char-create.js` is loaded at runtime as a preservation onboarding adapter.
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

**Development-branch checkpoint (2026-09-19):** the smoke-stabilized baseline plus steps 2–5 are verified, and step 6 is partially established: ordinary damage/restoration/resource mutations now route through a fail-closed resolver while `resolveTurn()` still owns PbtA outcomes and action-specific branch semantics. Promotion/merge to `main` has not occurred.

**Non-negotiable:** avoid a single rewrite of character creation, combat, progression, and party state at the same time.
