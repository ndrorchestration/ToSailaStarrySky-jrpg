# Aetherwake Save / Load Architecture

Status: candidate implementation
Priority: foundational / release-critical
Schema: v1

## Product contract

Aetherwake treats persistence as a core gameplay service.

Player-facing goals:
- Save anywhere in stable exploration states.
- Never require trekking to a save point merely to stop playing.
- Keep manual saves under player control.
- Keep autosaves supplemental and separate from manual saves.
- Provide multiple manual slots so consequential story choices can be revisited without restarting the game.
- Make Continue select the newest valid save.
- Never silently replace a corrupt save with invalid state.

Current slot model:
- 6 manual slots.
- 3 rotating autosave slots.
- F5 opens Save.
- F9 opens Load.
- C on the title screen continues from the newest valid save.

## Safe-state policy

Saving is allowed only from deterministic, rehydratable states.

Allowed now:
- WORLD
- AIRSHIP

Not allowed now:
- COMBAT
- OPENING / authored cinematic sequence
- DIALOGUE and other transient overlays as direct persistence states
- WAKE resolution beat
- game-over / ending transient state

The game may autosave immediately after a transient state resolves into a stable state.

## Storage architecture

Desktop NW.js:
- Store saves under `nw.App.dataPath/saves`.
- Serialize each slot as readable JSON.
- Write to a temporary file.
- Flush the temporary file.
- Move the previous primary to `.bak`.
- Promote the temporary file to primary.
- Restore the backup if promotion fails.

Browser / headless verification:
- Use localStorage through the same envelope and validation layer.

Manual and autosave data use the same schema and validation rules.

## Envelope contract

Every save contains:
- schema version
- game version
- slot identifier
- manual/autosave kind
- save timestamp
- playtime
- chapter
- location
- party summary
- gameplay payload
- checksum

A checksum failure invalidates the candidate save rather than loading partial state.

## Gameplay payload ownership

### Runtime
- stable scene
- day-cycle state
- sky-layer visibility
- accumulated playtime

### World
- player tile/pixel position
- covenant-field state
- ledger entries

### Quest
- quest phase / act
- signal progress
- hazard progress
- contacted NPCs
- final choice and variant
- hull / morale / heat / integration outcomes
- discoveries
- journal
- signal-hook states
- crossing-hazard states
- resolved epilogue identity

### Party
- all five canonical roster records
- active-party IDs

Restore must mutate canonical roster objects rather than replacing them, preserving the invariant that WORLD player and ACTIVE_PARTY entries point into the canonical ROSTER.

### Air navigation
Air-navigation state is not copied ad hoc. It must pass through `AetherAirNavigation.exportPersistentState()` and `restorePersistentState()`.

## Autosave checkpoints

Current:
- First Wake chapter handoff into WORLD.
- Quest state advancement.
- Combat resolution after returning to a stable state.

Planned additions:
- docking / major region transition
- explicit chapter boundary
- major recruitment boundary
- major irreversible economy/story transaction

Autosaves never overwrite manual slots.

## Migration policy

Schema versions are explicit.

Rules:
1. A save schema change requires a migration function or an intentional compatibility break.
2. Migration must be deterministic and covered by fixture tests.
3. Runtime objects are rehydrated through subsystem contracts, not blindly assigned when invariants exist.
4. Unknown future schema versions fail closed.
5. Old save fixtures should remain in tests for every supported released schema.

## Corruption and recovery policy

- Validate envelope shape and checksum before applying gameplay state.
- Preserve previous primary as `.bak`.
- If the primary JSON is unreadable, attempt the validated backup.
- Never mutate runtime state until the envelope has passed top-level validation.
- A future hardening pass should add semantic subsystem validation before commit/apply and expose a user-facing recovery choice when backup fallback occurs.

## Definition of done for every future gameplay system

A consequential subsystem is not complete until it answers:
1. What state must persist?
2. What is derived and should be recomputed?
3. What is the schema version?
4. How is it validated?
5. How is it restored without breaking object identity?
6. What happens when a field is missing from an older save?
7. At which stable checkpoints may it autosave?
8. What tests prove save → mutate → load returns the same gameplay semantics?

This applies to:
- inventory
- equipment
- magic/mastery
- party recruitment and formation
- quests
- factions/relationships
- world-map changes
- airship upgrades
- economy
- crafting
- codex/discoveries
- chapter progression
- options/settings where appropriate

## Verification lanes

Required:
- save-system storage contract
- checksum rejection
- manual slot save/load
- rotating autosaves
- backup creation
- corrupt-primary backup recovery
- runtime integration contract
- browser round-trip smoke
- desktop NW.js file-path smoke
- migration fixtures when schema v2 exists
- packaged Windows save/load smoke before installer promotion

## Current boundary

The candidate implementation establishes the persistence foundation and first complete save/load loop. It does not claim every future subsystem is already represented. Any new gameplay system must register its persistence ownership before merge so save coverage does not drift behind feature development.


## Hardening tranche — semantic preflight and migration registry

The load path now has a strict two-phase shape:

1. **Prepare / validate**
   - envelope integrity and schema normalization;
   - runtime stable-scene validation;
   - world coordinate and pixel/tile consistency;
   - quest counter/record consistency;
   - canonical five-record party identity and resource bounds;
   - active-party membership validation;
   - magic-profile validation when present;
   - air-navigation validation and rehydration planning;
   - epilogue identity validation.
2. **Commit**
   - only after all preparation succeeds may canonical runtime objects be mutated.

This prevents a checksum-valid but semantically impossible save from partially changing the live game before a later subsystem rejects it.

A migration registry now exists before schema v2 is introduced. Unknown future versions fail closed, and migration steps are required to advance exactly one schema version at a time.

Historical compatibility is now anchored by `tests/fixtures/saves/schema-v1-manual-1.json`. Released schema fixtures are intended to remain permanent regression inputs.


## Persistence coverage registry

`docs/persistence-coverage.json` is the machine-readable ownership index for consequential runtime state.

Each implemented persistent subsystem must identify:
- snapshot owner;
- restore owner;
- validator owner;
- version owner.

Transient states such as authored opening and combat are explicitly registered as `transient_not_saveable`, rather than silently omitted. Planned systems that do not yet have persistence ownership are explicitly registered as `gap`.

This keeps feature development honest: a new consequential system cannot disappear from save/load architecture merely because its in-session behavior works.

### Versioning clarification
The **whole-game save envelope schema** and **subsystem persistence versions** are independent contracts. For example, air navigation owns its own `PERSISTENCE_VERSION`; that version does not redefine the whole-game save envelope schema. Documentation must always identify which versioned contract it is referring to.

## Interrupted-write fault simulation

Desktop-save tests now inject failures at each durable-write stage:
- before temporary write;
- after temporary fsync;
- after old-primary backup promotion;
- immediately before new-primary promotion;
- immediately after new-primary promotion.

At every stage, the invariant is: **either the previous save or the fully-written new save remains valid and loadable**.
