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

## 1.1 Desktop distribution contract

### CURRENT IMPLEMENTATION

The player desktop runtime is staged independently from the development repository:

```text
desktop package root/
├── package.json        # minimal launcher manifest
└── www/
    ├── index-embedded.html
    ├── aetherwake.js
    ├── p5.min.js
    ├── modules/
    └── required runtime assets
```

The launcher manifest points to `www/index-embedded.html`. Windows packaging consumes only this staged runtime, not the repository root. The distribution pipeline produces a conventional per-user installer plus a portable ZIP fallback.

### VERIFICATION RULE

A compiled installer is not sufficient evidence of a working release. A player-facing installer may be called verified only when the **exact generated candidate** has been installed on Windows and the installed `Aetherwake.exe` has successfully launched through the release smoke gate.

Current status as of 2026-10-06: runtime baseline before documentation-only reconciliation was `875503662d9a9cff64eb6ec1bbbeedbfcc3ccbe3`. Documentation-only merges may advance protected `main` without changing runtime bytes. Preview 0.1 candidate PR #250 is bound independently to exact head `46f50c581d992bf581bb6b6d7961a9421b8b779d`. Hosted smoke run `37557721548` passed. Windows workflow-dispatch run `37559269564` passed package build, no-admin installer compilation, exact installed launch with `DESKTOP_RENDER_READINESS=PASS`, portable verification, SHA-256 generation, and prerelease publication. The published installer was independently re-downloaded, hash-verified, installed, and launched on NeonPC. Technical candidate verification is `PASS`; human review, visual acceptance, and human/player acceptance remain pending.

---

## 1.2 Visual presentation contract

### CURRENT DIRECTION

Aetherwake uses a coordinated three-layer presentation model:

1. gameplay pixel art;
2. in-engine cinematic presentation;
3. short authored video cinematics for selected high-cost story beats.

All three must depict the same canon, silhouettes, materials, palette logic, geography, Dragonfly state, and magic behavior.

The internal gameplay render surface remains 960×640. Desktop presentation may scale that surface, but visual composition and input geometry must preserve the logical coordinate system.

### ACCEPTANCE AUTHORITY

See:

- `docs/VISUAL_BIBLE.md`
- `docs/VISUAL_BENCHMARK_SCENE.md`
- `docs/CINEMATIC_CLIP_CONTRACT.md`

Existing art/migration PRs are implementation candidates and do not supersede these acceptance rules.

---

## 2. Playable roster

### TARGET ARCHITECTURE

Aetherwake has exactly five authored playable protagonists:

1. **Ender** — lead protagonist; native job **Rift Scholar**
2. **Lyra**
3. **Ionia**
4. **Reson**
5. **Aepex**

Combat supports 1–5 active authored protagonists as recruitment expands:

```text
ROSTER[5] → ACTIVE_PARTY[1..5] → combat
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
- `ACTIVE_PARTY` supports 1–5 direct references into `ROSTER`; First Wake starts with Ender alone and adds Lyra at Sequence 06, then times Ionia's official party role to the early storm/shield sequence;
- `world.player === ROSTER[0] === ACTIVE_PARTY[0]`, so the lead character is no longer duplicated across WORLD and persistent party state;
- the normal New Game path no longer uses custom companion creation;
- `modules/char-create.js` remains compatibility provenance only, and its custom companion/job assumptions are not authored canon;
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

`ACTIVE_PARTY[1..5]` should contain IDs/references to roster records.

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

- target production model: conventional JRPG stat/formula resolution;
- migrated actions use explicit deterministic or bounded-RNG contracts;
- legacy 2D6 outcome bands remain compatibility provenance only where an action has not yet been migrated or intentionally quarantined.

Resources currently include:

- Vitality,
- Echoes,
- Aether,
- Heat,
- Scrap,
- Resonator Staff charges.

Current action slots:

1. Resonator Staff — production JRPG formula
2. Uncover Truth — deterministic analysis / weakness reveal
3. Shared Dream — legacy compatibility residue; blocked by current Dreaming/Talen SSOT
4. Mycelial Ledger — Ender Commons read-only analysis
5. Hold — deterministic recharge
6. Wind Ward — legacy compatibility residue; owner/domain unresolved
7. Aether Seal — Ender Aether/Ward suppression on explicit Aether-dependent targets
8. Rest — deterministic recovery

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
- the combat panel exposes stable keys 1–8 while visibly marking locked/unavailable actions;
- CI rejects reintroduced direct ordinary mutations inside `resolveTurn()` and validates the browser path after resolver integration.

Known semantic debt remains explicit rather than being silently upgraded:

- Shared Dream remains compatibility residue until renamed or replaced by an Ender-appropriate resonance/connection action; current SSOT reserves true Dreaming for Talen;
- Wind Ward remains compatibility residue because canonical owner/domain are unresolved;
- current legacy cost/tier behavior is still preserved where not yet redesigned;
- modifier/reveal/status/movement execution is not generalized merely because those kinds exist in the vocabulary;
- several historical modular mirrors still contain old 2D6 text and are not runtime authority.

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

`modules/magic-defs.js` v0.1 is a target-design registry only. `modules/magic-mastery.js` v0.1 adds pure prerequisite, threshold, and reaction eligibility evaluation against that registry. Neither module grants mastery, mutates roster state, unlocks spells, or authorizes use of any new spell in the preservation runtime. `modules/magic-field-reactions.js` v0.1 now provides a pure immutable design-state layer for registered elemental reactions and state transitions. It does not yet execute damage, duration, resistance, turn-order, or other combat effects. Unsupported persistence, acquisition, live field mutation, and executable synthesis mechanics remain fail-closed until the resolver, save schema, UI, and automated tests support them.

### OPEN DESIGN

The first elemental spell catalog exists in `modules/elemental-spell-trees.js` as a design-only 1–5 tree map for all 11 admitted elemental schools. `modules/non-elemental-spell-trees.js` now provides the parallel status-preserving 1–5 design catalog for all 15 registered non-elemental domains. Proposed/high-order domains retain their registry status and are not promoted by catalog inclusion. Dreaming remains exceptional and outside ordinary mastery. These definitions are not executable combat abilities yet.

`modules/magic-spell-access.js` v0.1 now unifies the 260 elemental/non-elemental design seeds behind fail-closed spell access checks: own-school rank, cross-mastery prerequisites, and proposed-domain admission all must pass. Proposed/high-order domains remain inaccessible by default until explicitly admitted by a later creator/canon decision.

Character magic profiles now use schema v2 with learned spells separated from affinity/mastery. `modules/magic-study.js` provides explicit one-rank mastery advances and eligible-spell learning transactions, and `party-state.js` can persist a validated replacement profile for the current session. These transactions deliberately contain no XP curve, teacher requirement, currency/time cost, or automatic progression.

Mastery XP curves, study/resource costs, teachers/quests, authored learn-unlock pacing, save-file persistence/migration, final proposed-domain canon decisions, companion magical ownership, balance coefficients, and final Grand Synthesis names remain unresolved.

---

## 6. Combination arts

### TARGET ARCHITECTURE

Hierarchy:

1. Cross-School Arts — one character, two schools
2. Fusion Arts — deeper two-school interaction
3. Synthesis Arts — one character, three schools
4. Personal Grand Synthesis — four+ schools
5. Dual Arts — two characters
6. Triple Arts — three participating active characters

Combination eligibility should check actual state:

- component abilities,
- actors present,
- bond/synchrony,
- resources,
- readiness,
- positioning/status/setup,
- registered combo definition.

Triple Arts must be genuinely simultaneous among their three participants. A five-member active party may contain multiple valid Triple-Art subsets.

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

The full campaign will expand story acts, recruitment timing, character arcs, relationships, regions, bosses, exploration interactions, the Wakeheart/resonance mystery, and Auroral-lane access after the underlying character/combat architecture is stable.

---

## 8. Runtime architecture

### CURRENT IMPLEMENTATION

- `index-embedded.html` is the current browser entry point.
- `modules/effect-vocabulary.js` loads the frozen effect contract before combat construction.
- `modules/ability-defs.js` and `modules/progression-defs.js` load the canonical current action/unlock registries.
- `modules/magic-defs.js`, `modules/magic-mastery.js`, and `modules/character-magic-profile.js` load before party state and provide fail-closed magic taxonomy/profile contracts.
- `modules/party-state.js` is the authoritative persistent roster / active-party reference layer and now attaches validated magic profiles to all five canonical records.
- `aetherwake.js` is the current integrated runtime/preservation artifact and remains the current combat executor.
- `modules/first-wake-opening.js` is the active authored New Game onboarding controller through the FIRST WAKE chapter card.
- `modules/char-create.js` remains loaded only as historical compatibility surface and is not the normal New Game route.
- several other `modules/*.js` files are older mirrors/reference copies and may not match the integrated runtime; story-facing mirrors should preserve the Act I storm/shield premise when edited.

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
3. establish `ACTIVE_PARTY[1..5]`,
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
