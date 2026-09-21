# Aetherwake Development Guide

## Current stage

Aetherwake is a late-prototype / pre-alpha project.

The development branch now has a verified playable baseline, persistent `ROSTER[5]` / reference-based `ACTIVE_PARTY[3]`, fixed authored Ender/Lyra/Ionia onboarding, player-facing schema-v2 persistence for party/progression + World/quest/ledger + bounded Dragonfly state, effect vocabulary v0.1, extracted current ability/progression registries, and live fail-closed resolver routing for ordinary damage/restoration/resource mutations. Higher-order resolver semantics and authored companion/mastery progression remain staged work.

## Source-of-truth rules

### Runtime

Current browser runtime:

1. `index-embedded.html`
2. `modules/effect-vocabulary.js`
3. `modules/effect-resolver.js`
4. `modules/ability-defs.js`
5. `modules/progression-defs.js`
6. `modules/mastery-defs.js`
7. `modules/magic-access.js`
8. `modules/aether-sense.js`
9. `modules/party-state.js`
10. `aetherwake.js`
11. `modules/char-create.js`
12. bundled `p5.min.js`

The other files under `modules/` are useful historical/modular mirrors, but they are not guaranteed to match the integrated runtime.

Do not assume a change to `modules/core.js` or `modules/combat.js` changes the playable browser build unless the build process is explicitly changed to consume those files.

### Branches

- `main` — authoritative stable repository baseline.
- `dev/progression-build` — preservation/stabilization branch for the September 18–19 development build and subsequent baseline fixes.

Do not promote `dev/progression-build` to `main` until the smoke gate passes.

## Smoke gate

Canonical command:

```bash
npm run test:smoke
```

The smoke test should verify:

```text
boot/title
→ character creation
→ canonical ROSTER[5] / ACTIVE_PARTY[3] references
→ WORLD with world.player === ROSTER[0]
→ start combat
→ resolve a normal action
→ resolve an ability
→ write combat results back to the canonical lead record
→ return to WORLD
```

The test intentionally uses real keyboard input for player-facing state transitions and action execution. Reference equality is part of the gate; equal values in separate character copies are not sufficient.

## Dual-entrypoint boot gate

Both `index-embedded.html` (embedded/NW.js launch) and `index.html` (browser launch) are supported playable entrypoints. They must load the same runtime dependency chain in order:

```text
effect vocabulary → resolver → ability/progression registries → mastery
→ magic access → Aether Sense → party/airship state → airship bridge/UI
→ audio → aetherwake.js → character creation → p5.js
```

Each entrypoint includes a hidden `#aetherwake-init-error` status surface. Missing runtime dependencies fail closed through `showInitializationFailure()` instead of entering a partially initialized game, and the launcher reports a visible timeout if p5/canvas creation never completes. The debug overlay remains opt-in through `?debug=1`.

Validate the entrypoint contracts before browser testing:

```bash
npm run test:runtime-contracts
npm run test:smoke
npm run test:all
```


## Verified development checkpoint

On 2026-09-19, smoke run `35456148594` passed on commit `be896474c97271084c989f7d5e0d61f27ae72769`. It verified:

- roster IDs `ender|lyra|ionia|reson|aepex`,
- active IDs `ender|lyra|ionia`,
- direct reference identity for all three active entries,
- `world.player === ROSTER[0]`,
- legacy `window.party === ACTIVE_PARTY`,
- Reson/Aepex remaining unimplemented runtime shells,
- combat state write-back into the canonical lead record.

This checkpoint does not mean the authored-roster onboarding, formation system, three-character combat, ability extraction, or progression architecture is complete, and it does not mean `dev/progression-build` has been promoted to `main`.

## Comprehensive runtime-repair checkpoint

On 2026-09-20, GitHub Actions smoke run `35508881748` passed on commit
`308b4a4ef83b80bfb67e28047d91454b0d35ec88` after the comprehensive runtime
repair defined by
`docs/superpowers/specs/2026-09-20-aetherwake-bug-repair-design.md`.

The verified gate includes:

- dependency-complete, fail-closed boot for both `index-embedded.html` and `index.html`;
- current-key input ordering and immediate first-step world movement;
- first-contact dialogue, overlay return-state isolation, core-owned state transitions, and a typewriter path that cannot freeze on an empty first frame;
- synchronized world coordinates, lore sidecar storage, data-driven crossing completion, and a read-only ledger API;
- stable-ID, scrap-based, transactional Repair Cafe purchases with explicit capacity caps;
- complete World → Combat → World player-state round-trip and per-encounter transient reset;
- fail-closed enemy preflight before any one-shot airship state can be consumed;
- bounded Dragonfly airship-to-combat handoff with one-shot transfer semantics;
- combat-log rendering from authoritative combat state;
- canonical night-state vignette and visible grass-wind strokes;
- optional prerecorded dialogue TTS gated off by default because the current repository does not ship the `tts/` MP3 asset pack;
- regression coverage for malformed hazard configuration and p5 `text()` renderer shadowing.

The smoke path uses real browser input and verifies the playable flow through
character creation, world interaction, dialogue, shop behavior, combat,
Dragonfly boarding/system actions, combat handoff, canonical party write-back,
and return to WORLD without uncaught page or console errors.

This checkpoint verifies the source branch only. Generated `standalone/` and
`nw-package/` trees and any desktop executable remain post-validation build
artifacts and are not established by this CI result. `main` remains untouched
by this repair sequence.

## Authored onboarding checkpoint

On 2026-09-20, commit `49a031cb73b189d079d61b53f66785dd69c59cac`
passed both gameplay smoke run `35511110387` and Windows desktop package run
`35511111911`.

This establishes:

- Ender, Lyra, and Ionia as fixed authored starting identities;
- Lyra/Ionia no longer being player-renamable companion slots in the normal onboarding path;
- Sky-Sailor, Engine-Wright, and Aether-Weaver being explicitly treated as temporary **mechanics templates**, not canonical authored jobs;
- Lyra/Ionia `nativeJob === null` until authored job/school design is established;
- direct canonical references remaining `ACTIVE_PARTY[0..2] === ROSTER[0..2]`;
- explicit implementation provenance `authored-identity+prototype-mechanics` for the two companion records;
- deterministic and browser-level regression coverage for the onboarding state machine.

The browser gate also exposed and fixed an unrelated legacy renderer defect:
the field-role selector referenced an undefined `synText`; it now renders the
current template's `job.synergyBonus` directly.

This checkpoint does **not** establish Reson/Aepex mechanics, canonical Lyra/Ionia
jobs, formation switching, or true three-character combat.

## Save/persistence v1 checkpoint

On 2026-09-20, commit `fadd4a7cb7bee366c38cb07779aa8b388df92dd6`
passed gameplay smoke run `35511357445` and Windows desktop package run
`35511357423`.

Schema v1 establishes a compatibility boundary for **party/progression
persistence**, not a complete player-facing game save:

- `modules/save-state.js` defines save kind `aetherwake-save`, schema version
  `1`, and storage key `aetherwake.save.v1`;
- both playable entrypoints load the save module and boot fails visibly if the
  required save API is unavailable;
- only an allowlisted set of persistent roster/progression/resource fields is
  serialized;
- canonical roster identity is code-owned rather than save-owned;
- restoration mutates existing roster records in place, preserving
  `world.player === ROSTER[0]` and canonical `ACTIVE_PARTY` references;
- malformed JSON, missing versions, future versions, altered roster identity,
  duplicate/unknown active IDs, and activation of unimplemented roster shells
  fail closed;
- the migration registry exists explicitly. Schema v1 has no predecessor, so it
  correctly claims no synthetic legacy migration;
- encounter/render/transient fields are excluded by construction.

That v1 checkpoint has since been superseded by schema v2. Schema v2 explicitly covers World/quest/ledger and Dragonfly state and is exposed through the safe-state F2/F3 controls documented above. Encounter-local combat remains intentionally excluded.

## Player save/load v2 checkpoint

On 2026-09-20, runtime commit `3ddfb0daa287c7d5fc955cdcb7aa07b6573fe116`
passed gameplay smoke run `35548433775`. The matching Windows desktop build
run `35548433778` built and verified the packaged application and uploaded
artifact `10616998053` (`Aetherwake-Windows`, 664,418,765 bytes,
SHA-256 `135aaa09f440e0c7efc71a965cf989607ed06bbf84777a8fada99dd6794aa35d`).

This establishes the first player-facing persistence controls:

- **F2 Quick Save** is admitted only from normal `WORLD` state;
- **F3 Quick Load** is admitted from menu, authored onboarding, or normal
  `WORLD` state and returns to `WORLD`;
- unsafe transient states reject the operation instead of serializing combat or
  overlay internals;
- real-browser testing saves schema-v2 state, deliberately corrupts canonical
  party resources, World position, and Dragonfly power, then proves F3 restores
  all three domains;
- canonical identity survives load:
  `world.player === ROSTER[0] === ACTIVE_PARTY[0]`;
- combat is re-synchronized from the restored canonical World player;
- schema-v1 documents continue through the explicit v1 → v2 migration path.

Schema v2 persists party/progression, World/quest/ledger, and bounded Dragonfly
state. Encounter-local combat and presentation state remain intentionally
excluded.

## Mastery definitions Phase A checkpoint

On 2026-09-20, runtime commit `aa8e0aa4f098d8272a8a4fc539ed90f7ef181c47`
passed gameplay smoke run `35548707900` and Windows desktop package run
`35548707894`. The Windows run uploaded artifact `10617756330`
(`Aetherwake-Windows`, 664,424,658 bytes,
SHA-256 `79e6249b49ed46298a50548f3d1329e4d068beb0e736eb5cc5f547fef8dcb01c`).

Phase A establishes a non-mutating mastery-definition boundary:

- major domain families are code-owned as Elemental, Arcane, Psychic, Spirit;
- Ender's established special affinities are Aether, Resonance,
  Correspondence, and Lumen;
- Ender's native job fact is Rift Scholar;
- Lyra/Ionia/Reson/Aepex affinity and native-job knowledge remains explicit
  **UNKNOWN**, not silently interpreted as none;
- the runtime fails visibly if mastery definitions are missing or invalid;
- both playable entrypoints load the same mastery definition module before
  persistent party state;
- current combat eligibility, costs, level unlocks, and save schema v2 are
  unchanged by Phase A.

Mutable mastery ranks/points are intentionally not part of this checkpoint.
Because schema v2 is already player-facing, the first mutable mastery state must
enter through an explicit save schema v3 migration rather than extending v2
silently.

## Aether Sense executable-magic checkpoint

The magic-development lane establishes **Aether Sense** as the first
runtime-authorized foundation technique while preserving the remaining seven
foundation techniques as fail-closed design proposals.

The boundary is intentionally narrow:

- Ender's Aether affinity is established, and Aether Sense is explicitly listed
  as an Ender starting technique rather than being granted to every future
  Aether-capable character;
- Aether Sense is exploration-only in this slice and costs no Aether, Echoes,
  or unresolved inner resource;
- WORLD key **V** scans only explicit scene signatures: the Wake core, Engine
  Spirit, unresolved Aether Leak hazard while present, and an active player
  Covenant Field;
- sensing is read-only: it does not complete hazards, advance quests, mutate
  combat, grant mastery, or change save schema;
- results are recorded in the existing ledger and shown through a short-lived
  world overlay;
- Lyra/Ionia/Reson/Aepex magic ownership remains UNKNOWN;
- Aether Pulse, Resonant Ping, Attune, Spatial Sense, Rift Step, Lumen Spark,
  and Solar Mend remain unauthorized proposals.

Because no mutable mastery state is introduced, player-facing save schema v2
remains unchanged. Any later mutable mastery system still requires an explicit
schema migration.

## Canonical character-sheet checkpoint

On 2026-09-20, runtime commit `94556dabfc56d26b139731c8ee6d8c15e5d54698`
passed gameplay smoke run `35549081375` and Windows desktop package run
`35549081367`. The Windows run uploaded artifact `10617812829`
(`Aetherwake-Windows`, 664,427,544 bytes,
SHA-256 `4262049ab53f54aae030883c49340a90885f465cf7439e827d1972b913f16d59`).

This checkpoint replaces the live character sheet's preservation-era hardcoded
values with a canonical view-model:

- identity/stats/resources come from the live World/ROSTER lead record;
- native-job and affinity facts come from Mastery Phase A;
- current eligible actions come from the canonical ability registry;
- the legacy `Rift Scholar / Dreamwright` string is no longer presented as the
  canonical native job; preservation class residue is labeled separately;
- gear displays the actual equipment record instead of hardcoded equipment claims;
- the renderer bugs caused by an undefined `abilities` iterator and undefined
  gear-row `gy` variable are removed;
- browser smoke opens the real R-key overlay, verifies Ender's established
  Rift Scholar native job and Aether/Resonance/Correspondence/Lumen affinities,
  then closes the overlay without page/console errors.

This remains a presentation/read-model improvement. It does not add mutable
mastery, companion canon, formation switching, or three-character combat.

## Shared field-role registry checkpoint

On 2026-09-21, runtime commit `7dcd741279589e02a99a8eeb835710115edc43f9`
passed gameplay smoke run `35567099503` and Windows desktop package run
`35567099421`. The Windows run uploaded artifact `10624083439`
(`Aetherwake-Windows`, 664,432,820 bytes,
SHA-256 `4d4ffdf8a3521ce3f5b2e3822d65be3f209d15de7a94cf3d955f4c5d824291e1`).

This checkpoint extracts the preservation-era Sky-Sailor, Engine-Wright, and
Aether-Weaver mechanics templates from character creation into
`modules/field-role-defs.js`.

The boundary is explicit:

- these definitions are **prototype mechanics / temporary field roles**;
- they are not canonical native jobs, schools, or mastery facts for Lyra,
  Ionia, Reson, or Aepex;
- onboarding consumes one shared registry rather than owning a duplicate copy;
- runtime boot fails closed if the registry is unavailable or invalid;
- the registry preserves the exact existing rank-1 stats, two-ability metadata,
  and synergy text without balance changes;
- full companion combat is still not authorized because the templates do not
  yet define complete executable PbtA outcome tables for all roll bands.

## Minimal desktop runtime packaging checkpoint

On 2026-09-21, runtime commit `93908e2b0fa8b05e69f7c4095dca419e77cc07a3`
passed gameplay smoke run `35567486492` and Windows desktop package run
`35567486498`.

The packaging lane now stages only required runtime assets before invoking
NW.js:

- staged runtime: **25 files / 2,858,504 bytes**;
- `package.nw` verified payload: **2,858,504 bytes**;
- development-only entries such as `node_modules`, tests, docs, CI metadata,
  scripts, and build tooling are rejected if they leak into `package.nw`;
- the staged runtime has a hard **20 MiB** fail-closed size bound;
- `Aetherwake.exe` and the staged manifest/entrypoint are still verified before
  artifact publication.

The uploaded Windows artifact is `10623874064`
(`Aetherwake-Windows`, **219,915,613 bytes**,
SHA-256 `d90ac3b4b2d83e575e09b047d9b1786783eab1484884c01b44d724484fa21d89`).

Compared with the immediately preceding verified artifact
(`664,432,820 bytes`), this removes **444,517,207 bytes (66.9%)** from the
download while preserving the same playable/runtime behavior. The remaining
artifact weight is primarily the NW.js/Chromium desktop runtime rather than the
game application payload.

## Read-only party combat context checkpoint

On 2026-09-21, runtime commit `ceeb943d94a2d4cd81e500ad475aee11a10ea0d2`
passed gameplay smoke run `35568410543` and lean Windows desktop package run
`35568410500`. The Windows run uploaded artifact `10625580392`
(`Aetherwake-Windows`, 219,918,339 bytes,
SHA-256 `6e15a8edf4946e805f8253037edb82f43efd1f97e760e27545c163d08a476967`).

This establishes the first validated three-character **combat context** without
claiming three-character combat execution:

- `modules/party-combat-bridge.js` snapshots exactly three unique implemented
  active roster references;
- Phase A requires Ender as the executable lead actor;
- Lyra and Ionia enter the encounter context with live HP/resources and their
  temporary field-role provenance;
- their two preservation-era action declarations are visible but explicitly
  marked `declared-non-executable` with reason
  `OUTCOME_CONTRACT_NOT_ESTABLISHED`;
- companion action IDs do not enter Ender's executable 1–8 action registry;
- `AetherCombat` validates and clones the party context, and `getState()`
  returns another detached copy;
- the combat panel displays Lyra/Ionia as **STAGED** but provides no companion
  action controls;
- browser smoke proves encounter context creation does not mutate
  `ACTIVE_PARTY`.

This is deliberately an admission boundary, not an implicit companion-combat
implementation. Companion turns remain blocked until complete executable
outcome contracts exist.

## Companion action admission checkpoint

On 2026-09-21, commit `deb34047ed29ac9c54eac6ae3829edb4e6bd7e61`
passed smoke run `35569640367` and Windows package run `35569640366`.

`modules/companion-action-admission.js` now defines the fail-closed completeness
gate that a staged companion action must satisfy before it can even be
considered for execution:

- the action must remain bound to its preservation field-role template and
  provenance;
- the 2D6 stat and 10+/7–9/6− roll bands must be explicit;
- resource cost must be explicit, including zero-cost actions;
- common/success/partial/failure outcome profiles must all validate against the
  existing effect vocabulary;
- every effect required by an executable contract must already have
  `IMPLEMENTED` runtime status rather than `DECLARED_NOT_APPLIED`;
- an execution adapter binding and persistence policy must be explicit;
- structural completeness still yields `complete-not-authorized`, never
  execution permission.

All six current preservation-role companion actions remain fail-closed with
`OUTCOME_CONTRACT_NOT_ESTABLISHED`. No companion turns, new canon, save-schema
changes, or executable companion effects were introduced.

The next admissible work is to author concrete preservation-action outcome
contracts one at a time. Execution remains a separate later authorization and
integration step.

## Wind-Shear Dance contract-draft checkpoint

On 2026-09-21, commit `466fd8ce083f40bbd321ec2cd16ff3a5d46f1d5e`
passed smoke run `35574785248` and Windows package run `35574785284`.
The Windows run uploaded artifact `10626674771`
(`Aetherwake-Windows`, 219,929,340 bytes,
SHA-256 `2ed4b950d66fd3ce224cb26d1a6937c04d1557ffe1dc370cbe76daa6f46a4e05`).

`modules/companion-action-contracts.js` now records the first evidence-bound
preservation action draft, **Wind-Shear Dance**, without converting descriptive
prototype text into invented executable rules.

Established by the draft:

- the source declaration remains exactly `2D6+Grace. Evade / reposition. 10+: next Grace roll +1.`;
- the roll uses the already-established 2D6 + Grace and global 10+/7–9/6− bands;
- reposition intent is preserved but its exact outcome-band assignment remains unknown;
- the explicit 10+ next-Grace-roll +1 is preserved as a declared modifier semantic;
- native-job and school bindings remain `UNKNOWN`, consistent with the companion magic-access boundary.

Still unresolved and therefore blocking admission:

- numeric/resource cost;
- exact reposition outcome band;
- 7–9 outcome;
- 6− outcome;
- executable movement semantics;
- executable next-Grace-roll modifier semantics;
- execution adapter;
- persistence policy.

The module exposes **no admission candidate** while those blockers remain, so
the existing companion-action admission gate continues to return
`OUTCOME_CONTRACT_NOT_ESTABLISHED`. Wind-Shear Dance is documented more
precisely, but it is not executable and no companion turn is authorized.

The next safe contract work is to preserve evidence for another declared
preservation action or to resolve one of these explicit design gaps through an
authored decision; neither path authorizes runtime execution by itself.

## Effect/registry checkpoint

On 2026-09-19:

- run `35457176667` passed on `fda1512e9643c0b70738af200c1714f5174ecaca`, establishing effect vocabulary v0.1 and action-profile coverage;
- run `35457323324` passed on `1f45d888f62b5f77bb1157c946f2522e40727f42`, verifying extracted ability/progression registries and full browser behavior;
- all eight runtime actions are created from `modules/ability-defs.js`;
- level 3/4/5 unlocks are read from `modules/progression-defs.js`;
- `resolveTurn()` remains unchanged as the active mechanics executor;
- declared-but-not-applied prototype semantics remain explicitly marked rather than silently treated as implemented.

Canonical verification commands:

```bash
npm run test:effects
npm run test:registries
npm run test:resolver
npm run test:resolver-integration
npm run test:enemy-metadata
npm run test:combat-input
npm run test:resource-eligibility
npm run test:progression-reachability
npm run test:secondary-action
npm run test:smoke
```

## Resolver integration checkpoint

On 2026-09-19:

- resolver scaffold commit `5dd753524fa2874d2df7f726670961f8ce7c62dc` passed run `35457611114`;
- live integration commit `13c84e00d3097429f70bf6616294bbc08b377618` passed run `35457776908`;
- ordinary damage, vitality restoration, and resource deltas inside `resolveTurn()` route through `modules/effect-resolver.js`;
- CI source-checks `resolveTurn()` so ordinary direct mutations cannot silently reappear;
- browser smoke verifies live combat actually performs resolver-backed mutations;
- PbtA roll bands, action-specific branch selection, logs, randomness, XP, level-up rules, and the explicit defeat floor remain outside this resolver layer;
- modifier/reveal/status/movement semantics are not claimed as implemented by the resolver.

This is a partial establishment of migration step 6, not completion of the full generic combat resolver.

## Action eligibility checkpoint

On 2026-09-19, commit `d38827c0c8df9d0b92ce2376a775a8ddf0dafcae` passed run `35458285333`.

It establishes:

- stable eight-action ordering remains unchanged;
- Staff Strike and Hold are baseline actions;
- other current actions require their ID in `player.unlockedAbilities`;
- level-1 eligible actions are Staff Strike, Uncover Truth, Shared Dream, Mycelial Ledger, and Hold;
- Wind Ward/Aether Seal/Rest are rejected before turn/resource consumption until learned;
- combat UI keeps stable 1–8 slots and marks locked actions rather than renumbering them;
- the UI displays the same legacy `tier + cost` resource amount used by runtime resolution.

This enforces the existing progression data without introducing school mastery, job gating, or new unlock semantics.

## Use/progression/secondary checkpoint

On 2026-09-19:

- transactional use-eligibility implementation `a25c901125e65331e5d7f10d2ca6bdb1620015c0` initially exposed one stale source assertion in run `35463662627`; no runtime/browser claim was made from that failed run;
- test-only correction `d93dea34e9b512319f3a94e229e5769e695c8f22` passed run `35463741004`, verifying centralized `tier + cost`, pooled Echo+Aether preflight, zero partial spending on rejected actions, UI/runtime cost agreement, and full browser behavior;
- victory-progression correction `a753ac5809b52534576bba15c7ef37e66d07373f` passed run `35463872395`, proving normal XP award paths can cross level 2 → 3 and unlock Wind Ward;
- secondary-state correction `ba36e59a332adb95cc3d1f9b40681bd2c9d8106e` passed run `35464000671`, proving secondary opportunities are not stale and are offered only when the repeated ability remains usable.

Current explicit boundaries:
- cost amounts were **not** redesigned;
- school/job/mastery prerequisites are not yet implemented;
- modifier/reveal/status/movement execution remains outside the current generic resolver subset;
- `main` remains untouched.

## Architecture migration rule

Do not rewrite character creation, party state, combat resolution, progression, and save state simultaneously.

Preferred order:

1. stabilize current playable baseline,
2. establish persistent `ROSTER[5]`,
3. establish `ACTIVE_PARTY[3]` as references/IDs,
4. define effect vocabulary,
5. extract ability and progression registries,
6. generalize combat resolution,
7. migrate to authored roster onboarding,
8. add school/job/mastery progression,
9. add formation, Dual Arts, and Triple Arts,
10. expand campaign content.

## Persistent-state rule

The production architecture should have one canonical persistent character schema.

World, combat, formation, UI, progression, and persistence systems should operate on character IDs/references or explicit interfaces rather than creating unrelated partial copies.

Save documents must remain versioned compatibility artifacts. New persistent domains require explicit schema treatment and, after a schema is released, explicit migrations rather than best-effort guessing.

Temporary state-copying in the preservation baseline is migration debt and should be removed as the roster architecture lands.

## Build outputs

The following are generated/deployment artifacts and should not be edited as independent source trees:

- `standalone/`
- `nw-package/`
- downloaded NW.js archives

Long term, self-contained runtime bundles should be generated from one canonical source tree.

## Documentation roles

- `README.md` — project overview and runnable current state.
- `SPEC.md` — current implementation versus target architecture.
- `gap_analysis.md` — dated/snapshot conformance audit.
- `memories_adaptation_catalog.md` — adaptation/provenance reference.
- this file — repository development workflow and authority rules.
