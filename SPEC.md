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
- onboarding now uses the fixed authored starting identities Ender, Lyra, and Ionia;
- Lyra and Ionia are no longer player-renamable companion slots;
- Sky-Sailor / Engine-Wright / Aether-Weaver remain preservation-era **mechanics templates**, centralized in `modules/field-role-defs.js` and recorded separately from authored identity and native-job canon;
- Lyra and Ionia's canonical `nativeJob` values remain unresolved/null; selecting a mechanics template does not establish canon;
- Reson and Aepex currently exist as identity/schema shells only;
- formation mutation is not implemented in this phase;
- combat now receives a validated read-only Ender/Lyra/Ionia party context, but only Ender is executable; Lyra/Ionia temporary field-role actions remain explicitly staged/non-executable until complete outcome contracts are established;
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

The first three records are mechanically populated through the onboarding adapter. Ender retains the preservation baseline, while Lyra and Ionia preserve authored identity plus explicitly labeled prototype mechanics templates. Reson and Aepex intentionally remain unimplemented shells; no unresolved native job, progression, or ability semantics are fabricated.

### OPEN DESIGN

Inactive-character XP/mastery sharing policy remains open.

---

## 4. Combat system

### TARGET COMBAT DIRECTION — APPROVED 2026-09-21

Aetherwake's production combat model is a conventional **turn-based JRPG stat-and-formula system with bounded secondary RNG**.

Target rules:

- stats and declarative ability formulas determine the primary result;
- actions normally execute when use eligibility, targeting, and resource checks pass;
- optional RNG is limited to conventional JRPG roles such as accuracy/evasion, critical hits, status application, small bounded damage variance, and enemy AI choice;
- combat does **not** use PbtA-style full/partial/failure bands as the target resolution model;
- normal combat exposes **no player-facing dice system**;
- preservation-era `2D6 + stat` text is compatibility/provenance evidence only and must not be promoted into new production action contracts;
- migrated abilities require a new formula-system contract covering power/scaling, defense or resistance interaction, targeting, costs, effect semantics, and any bounded RNG policies before execution is authorized.

The migration contract is defined in `docs/JRPG_COMBAT_DIRECTION.md` and machine-guarded by `modules/combat-system-policy.js`.

The existing 2D6 implementation remains temporarily testable only to keep the playable prototype intact while actions are migrated incrementally.

### CURRENT IMPLEMENTATION — HYBRID MIGRATION

Resolution now has four explicit paths:

- **Staff Strike:** live JRPG damage-formula resolution through `modules/combat-formula.js`; no 2D6 outcome band, one dedicated staff charge, Might scaling, EMP damage type, explicit future EMP-defense hook, bounded variance, and critical policy.
- **Hold:** live deterministic JRPG resource-formula resolution; restores one staff charge up to `maxStaffCharges`, consumes the turn, adds no Heat, and has no success/partial/failure self-damage branches.
- **Rest:** live deterministic JRPG recovery-formula resolution; reduces Heat by up to 2 and restores up to 1 Vitality, consumes the turn, adds no Heat, and has no success/partial/failure damage branch.
- **The remaining five current actions:** preservation-era 2D6 compatibility path:
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

Current use eligibility is centralized in `modules/ability-defs.js` v0.5.0. Staff Strike additionally preflights its dedicated staff charge before turn/heat consumption. The prototype's existing numeric rule is preserved exactly as `tier + cost`, but affordability is preflighted transactionally across pooled Echo+Aether before a turn or resource is consumed. The combat UI and runtime use the same cost function. Normal victory XP now routes through `awardXP()`, so crossing a threshold executes `levelUp()` and makes newly learned actions eligible.

The development branch now separates current combat metadata from execution:

- `modules/combat-system-policy.js` guards the approved formula-driven JRPG target;
- `modules/combat-formula.js` v0.3 resolves migrated damage, deterministic resource, and deterministic recovery formulas (currently Staff Strike, Hold, and Rest) without mutating state;
- `modules/effect-vocabulary.js` establishes effect vocabulary v0.1;
- frozen kinds are `damage`, `restore`, `resource`, `modifier`, `status`, `reveal`, and `movement`;
- `modules/ability-defs.js` v0.5.0 owns canonical metadata/order, formula bindings, unlock eligibility, legacy pooled resource-cost calculation, affordability, and current use eligibility for the eight actions;
- `modules/progression-defs.js` owns the current level-3/4/5 unlock table;
- `AetherCombat.resolveTurn()` routes Staff Strike, Hold, and Rest through the formula resolver and keeps the five unmigrated actions on the legacy outcome branch;
- ordinary damage, restoration, and resource mutations inside `resolveTurn()` are now executed through `modules/effect-resolver.js`;
- the resolver fails closed on unsupported implemented effect kinds and treats `DECLARED_NOT_APPLIED` effects as explicit no-ops;
- `resolveTurn()` now rejects locked actions before consuming a turn or resources;
- the combat panel exposes stable keys 1–8 while visibly marking locked actions;
- CI rejects reintroduced direct ordinary mutations inside `resolveTurn()` and validates the browser path after resolver integration.

### READ-ONLY PARTY COMBAT CONTEXT — PHASE A

`modules/party-combat-bridge.js` now creates a validated, detached snapshot of
the three active roster records for encounter context.

Current authorization boundary:

- active context must contain exactly three unique implemented records;
- Ender is the only executable actor in this phase;
- Lyra/Ionia retain their temporary field-role provenance and two declared
  preservation actions;
- every companion action is marked non-executable with
  `OUTCOME_CONTRACT_NOT_ESTABLISHED`;
- no companion action ID enters the current 1–8 executable action registry;
- the combat UI may display party presence/HP/role, but cannot invoke companion
  turns.

This phase exists specifically to prevent descriptive prototype mechanics from
silently becoming executable rules.

### COMPANION ACTION ADMISSION — COMPLETENESS GATE

`modules/companion-action-admission.js` now formalizes the evidence required
before a preservation-role companion action can advance beyond staged metadata.

A complete candidate contract must bind the declared action to its temporary
field-role provenance, specify the existing 2D6 outcome bands and cost, provide
validated common/success/partial/failure effect profiles whose effects are
already executable, identify an execution adapter, and state its persistence
policy.

Passing those completeness checks does **not** authorize execution. The current
gate returns `complete-not-authorized`; all six real preservation-role actions
currently remain blocked with `OUTCOME_CONTRACT_NOT_ESTABLISHED`. Ender is
still the only executable combat actor.

### FIRST EVIDENCE-BOUND COMPANION ACTION DRAFT — WIND-SHEAR DANCE

`modules/companion-action-contracts.js` records Wind-Shear Dance as a
`draft-unresolved` preservation contract. The draft preserves only source-backed
facts: 2D6+Grace, evade/reposition intent, and the explicit 10+ next-Grace-roll
+1. It intentionally leaves cost, exact reposition band, partial/failure
outcomes, execution binding, and persistence unresolved.

The draft assigns no companion school or canonical native job. Those bindings
remain `UNKNOWN`, so the temporary Sky-Sailor mechanics template cannot silently
become Lyra/Ionia canon. Because the draft exposes no admission candidate,
Wind-Shear Dance remains non-executable and does not change the Ender-only
combat authorization boundary. Aether Sense becoming executable for Ender does
not alter this companion boundary.

### SECOND EVIDENCE-BOUND COMPANION ACTION DRAFT — AETHER COMPASS

Aether Compass is recorded as a second `draft-unresolved` preservation
contract. Its source-backed facts are limited to 2D6+Wits, resource revelation,
and a possible gain of Scrap or Aether. The draft does not infer which outcome
band performs either effect, what is revealed, how the gained resource is
selected, or how much is gained.

Cost, full outcome tables, reveal execution, execution binding, persistence,
native job, and school remain unresolved. It exposes no admission candidate,
so it remains non-executable and does not widen companion combat authorization.

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

### MASTERY DEFINITIONS — PHASE A

`modules/mastery-defs.js` now establishes only the code-owned facts that are
already supported by the specification:

- major domain-family IDs: Elemental, Arcane, Psychic, Spirit;
- Ender special affinity IDs: Aether, Resonance, Correspondence, Lumen;
- Ender native job: Rift Scholar;
- Lyra/Ionia/Reson/Aepex affinity and native-job status: explicit **UNKNOWN**.

The module preserves unknown as a first-class state rather than converting missing
data into "none." It does not add ranks, mastery XP, trees, new abilities, or new
combat eligibility.

Because save schema v2 is already player-facing, mutable mastery state is not
allowed to appear silently inside v2 documents. The first mutable mastery phase
must introduce an explicit **save schema v3** migration that initializes new
mutable fields without fabricating progress. Authored affinity/native-job facts
remain code-owned rather than save-owned.

### OPEN DESIGN

Several proposed schools/domains, resource relationships, mastery scales/award
rules, and companion job definitions remain unresolved.

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
- `modules/mastery-defs.js` owns the established code-owned mastery/domain facts and explicit UNKNOWN companion canon.
- `modules/field-role-defs.js` owns the three preservation-era temporary mechanics templates used by authored companion onboarding; these are not canonical native jobs.
- `modules/party-state.js` is the authoritative persistent roster / active-party reference layer.
- `modules/save-state.js` is the versioned save-document boundary; schema v2 is the current player-facing format with explicit migration from released schema v1.
- `aetherwake.js` is the current integrated runtime/preservation artifact and remains the current combat executor.
- `modules/char-create.js` is loaded at runtime as the authored starting-trio onboarding adapter and consumes the shared field-role registry rather than owning a duplicate mechanics registry.
- several older mirror/reference modules may still diverge from the integrated runtime and should not be treated as authoritative without entrypoint/test evidence.

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

### TARGET ARCHITECTURE

Persistent game state must use:

- an explicit save-schema version,
- stable character IDs,
- explicit migrations between released schema versions,
- separation of persistent and encounter-local state,
- allowlisted subsystem payloads rather than arbitrary runtime-object dumps,
- fail-closed validation before any restore mutation.

Save format is a compatibility boundary and must not be treated as an afterthought.

### HISTORICAL RELEASED SCHEMA V1 — MIGRATION SOURCE

`modules/save-state.js` establishes save kind `aetherwake-save`, schema
version `1`, and a versioned local-storage key. `modules/party-state.js`
provides the underlying allowlisted export/validation/restore API.

Schema v1 currently persists:

- all five stable roster IDs in canonical order,
- each record's runtime-implementation flag,
- allowlisted party/progression/resource fields,
- the three active-party IDs.

Restore mutates the existing canonical records and `ACTIVE_PARTY` array in
place. Authored identity (`id`, `canonicalName`, `nativeJob`) is code-owned
and cannot be rewritten by a save document. Invalid JSON, missing/future schema
versions, roster-ID tampering, duplicate/unknown active IDs, or activation of an
unimplemented shell fail closed.

Schema v1 remains supported only as a released migration source. The current
migration registry explicitly maps v1 → v2; no fictitious pre-v1 migration is
claimed.

### CURRENT SAVE SCHEMA — v2

Schema v2 is the current player save compatibility boundary:

- versioned save kind `aetherwake-save`;
- current storage key `aetherwake.save.v2`;
- stable authored roster IDs with code-owned canonical identity;
- allowlisted party/progression/resource state;
- World position/layer, quest, and ledger state through the World persistence contract;
- bounded Dragonfly system state through the airship persistence contract;
- explicit migration from released schema v1;
- validation of the complete document before restore;
- restoration by mutation/rebinding rules that preserve canonical roster/World references.

Player-facing quick controls now expose this boundary:

- **F2** saves only from normal `WORLD` state;
- **F3** loads only from safe menu/onboarding/`WORLD` states and returns to `WORLD`;
- combat/UI/transient states remain excluded;
- combat is reinitialized from the restored canonical World player after load.

Encounter-local combat state and presentation/render state remain intentionally
outside the save document. Mid-encounter saving is not authorized by v2.

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

**Development-branch checkpoint:** the smoke-stabilized baseline plus steps 2–5 are verified; step 6 is partially established through the fail-closed ordinary effect resolver; step 7 has established fixed Ender/Lyra/Ionia authored onboarding plus a shared preservation field-role registry while companion canonical jobs/affinities remain unresolved; save schema v2 covers party/progression, World/quest/ledger, and bounded Dragonfly state with explicit v1 migration and player-facing F2/F3 safe-state controls; migration step 8 Phase A establishes code-owned mastery/domain facts without mutable mastery state; and the character sheet now exposes a read-only five-character roster browser without mutating formation. Encounter-local combat persistence remains intentionally excluded. Promotion/merge to `main` has not occurred.

**Non-negotiable:** avoid a single rewrite of character creation, combat, progression, and party state at the same time.
