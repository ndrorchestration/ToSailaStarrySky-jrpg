# Aetherwake — The Last Solarpunk Airship

Aetherwake is a **pre-alpha turn-based JRPG** built with p5.js and adapted from selected technical patterns and reference material from *Memories 0.7.4*. You play Ender aboard the party's compact solarpunk airship as a failing aether-core, impossible sky-lanes, and a fractured world begin to reveal the same unfinished song. Current documentation contains both *Aureate Wake* and *The Unfinished Song*; that naming difference is tracked as an explicit canon-reconciliation item rather than silently normalized.

The current repository contains a playable vertical-slice prototype plus an active architecture migration toward the full authored-party RPG.

## Development status

- **Stage:** late prototype / pre-alpha
- **Playable baseline:** boot → authored Ender/Lyra/Ionia onboarding → world exploration → dialogue/quest systems → combat → Dragonfly ship systems → save/load
- **Target roster:** 5 authored playable protagonists — Ender, Lyra, Ionia, Reson, Aepex
- **Target combat party:** exactly 3 active combatants selected from the persistent roster
- **Current combat runtime:** hybrid migration state — Staff Strike, Hold, and Rest use JRPG-native formulas while five preservation-era actions still use the legacy 2D6 compatibility path
- **Current persistence:** schema v2 stores canonical party/progression state plus bounded World, quest/ledger, and Dragonfly state; encounter-local/transient state remains deliberately excluded
- **Current party boundary:** persistent five-character roster and authored starting trio are established; formation switching and true three-character combat are not enabled yet
- **Current architecture work:** effect vocabulary/resolver contracts, transactional use eligibility, progression reachability, JRPG control surfaces, mastery/magic-access definitions, authored five-character roster integration, open-sky navigation, sky encounters, regression coverage, and Windows packaging are under active incremental development

See `docs/DOCUMENTATION_AUTHORITY.md` first for the authority map, then `SPEC.md` for the implementation/target split and `docs/DEVELOPMENT.md` for source-of-truth and verification rules.

## Run the game

### Windows — simplest player path

Use the **Aetherwake-One-File** artifact produced by the **Windows desktop package** GitHub Actions workflow. GitHub provides Actions artifacts as ZIP downloads; extract that download once, then double-click the single file inside:

`Aetherwake - The Last Solarpunk Airship.exe`

That executable carries the Aetherwake icon and privately prepares the verified game runtime under your local AppData folder. You do not need Python, PowerShell, Node.js, a local HTTP server, or a manually managed runtime folder.

The older **Aetherwake-Windows** folder artifact remains available as a development/debugging fallback.

### Browser — development/fallback path

Open `index-embedded.html` in a modern browser.

The development runtime is designed to work offline and uses:

- embedded fonts,
- bundled p5.js,
- embedded/reference loading assets,
- local JavaScript modules,
- optional generated TTS assets when present.

Current canvas: **960×640**.

## Controls

Aetherwake's primary controls now follow the **Memories / RPG Maker-style JRPG vocabulary**. Normal play does not require memorizing Aetherwake-specific letter hotkeys.

| Primary control | Action |
|---|---|
| **Arrow keys / D-pad** | Move in the world; move menu/cursor selection |
| **Z / Enter / Space / gamepad A** | Confirm, interact, talk, board/use contextual objects, select commands |
| **X / Esc / gamepad B** | Open system menu in the world; cancel / go back |
| **Shift / gamepad X** | Dash/fast movement; secondary/special combat action when available |
| **Q / PageUp / left shoulder** | Previous page/character where supported |
| **W / PageDown / right shoulder** | Next page/character where supported |

The **system menu** provides normal access to **Status, Quest, Mycelial Ledger, Aether Sense, Covenant Field, Sky/Ground Layer, Save, and Load**.

Combat, shops, Core choices, character/status pages, and the Aureate Wake systems console are cursor-driven: use the directional controls, **Z/Enter** to confirm, and **X/Esc** to back out.

### Compatibility shortcuts

Legacy development-era shortcuts remain temporarily available while the migration is stabilized: WASD movement; E/Q/F/Tab/V/L/M/R/T; number-key combat/choice shortcuts; F2/F3 quick save/load; and C to trigger the development Sky-Predator encounter. They are **aliases, not required controls**, and should not be treated as the normal player interface.

## Save / load

Aetherwake exposes the versioned save system through the normal system menu. F2/F3 remain compatibility shortcuts:

- **Save / F2:** writes the current schema-v2 save only from normal `WORLD` state.
- **Load / F3:** restores a valid save from menu, onboarding, or normal `WORLD` state and returns to `WORLD`.
- combat, dialogue, shop, ledger, quest, character-sheet, and airship-console states reject save/load actions that would cross an unsafe transient boundary.
- restored data includes canonical party/progression state, World position/quest/ledger state, and bounded Dragonfly system state.
- load re-synchronizes the combat snapshot from the restored canonical World/roster record.
- older schema-v1 saves migrate through the explicit v1 → v2 migration path.

The current save document deliberately excludes encounter-local combat and presentation/transient state. Invalid, unversioned, future-version, or identity-tampered saves fail closed rather than being guessed into a usable state.

## Airship systems console

Stand near the ship's core chamber and **interact** to board the compact Dragonfly-class airship. Current art/development work uses **The Unfinished Song** while older canon pages use **Aureate Wake**; see `docs/DOCUMENTATION_AUTHORITY.md`. The hull volume is fixed at **three shipping containers**, excluding masts, wings, and rigging.

The console is fully cursor-driven with the normal directional + confirm/back controls. Legacy shortcuts remain available during migration:

- **1** — Phase-Slip Wake Drive
- **2 / H** — cycle Harmonic Phase Veil mode
- **3** — Resonance Lance
- **4** — Rootline Tether
- **5** — Pattern Forge
- **R** — vent the Wakeheart, reduce heat, advance cooldowns, and recover one power cell
- **Esc / L** — return to the world

The console is the first playable ship-systems slice. Its power and charge budgets are intentionally bounded, and its one-shot systems now hand off to the next encounter: Resonance Lance opens with a bounded strike, Guard veil absorbs the first point of incoming damage, Slip veil can phase through the first hit, Resonance veil sharpens the first crew roll, and Phase-Slip explicitly phases the first damaging strike.

## Combat prototype

**Target combat direction:** conventional JRPG stat-and-ability formulas with bounded secondary RNG. There is no player-facing dice system in the production target, and PbtA success/partial/failure bands are being retired. See `docs/JRPG_COMBAT_DIRECTION.md`.

**Current migration runtime:** combat is now hybrid while the engine is converted incrementally.

- **Resonator Staff / Staff Strike:** live **JRPG damage formula**; Might-scaled EMP damage, one staff charge, bounded damage variance and critical policy, no visible dice/outcome bands.
- **Hold:** live **deterministic JRPG resource formula**; restores one Resonator Staff charge up to the current maximum, with no roll bands or self-damage.
- **Rest:** live **deterministic JRPG recovery formula**; reduces Heat by up to 2 and restores up to 1 Vitality, with no roll bands or failure damage.
- **The remaining five actions:** still use the preservation-era **2D6 + stat** compatibility path (10+ / 7–9 / 6−) until each receives a production formula/effect contract.

The current preservation baseline contains eight combat actions:

| # | Action | Role |
|---:|---|---|
| 1 | Resonator Staff | JRPG-formula EMP attack |
| 2 | Uncover Truth | Wits / reveal |
| 3 | Shared Dream | Spirit / support |
| 4 | Mycelial Ledger | Presence / resource recovery |
| 5 | Hold | deterministic JRPG recharge |
| 6 | Wind Ward | defensive ability |
| 7 | Aether Seal | defensive / aether ability |
| 8 | Rest | deterministic JRPG recovery |

Current prototype progression unlocks **Wind Ward at level 3, Aether Seal at level 4, and Rest at level 5**.

The remaining 2D6 action definitions are a **legacy implementation baseline**, not the final architecture. Staff Strike, Hold, and Rest are the first three actions migrated out of that baseline. The target system uses data-driven ability formulas, explicit prerequisites, a generic effect resolver, bounded accuracy/critical/status variance where appropriate, school mastery, jobs, and party-combination arts.

## Party architecture

### Target

```text
ROSTER[5] → ACTIVE_PARTY[3] → combat
```

Persistent progression belongs to the five-character roster. The active trio is a combat/formation selection, not a separate copy of character progression.

### Current migration state

The development runtime now has the first persistent party-state layer:

- `modules/party-state.js` owns exactly five stable roster identities: `ender`, `lyra`, `ionia`, `reson`, and `aepex`;
- `ACTIVE_PARTY` contains three direct references into `ROSTER`, initially Ender/Lyra/Ionia;
- `world.player`, `ROSTER[0]`, and `ACTIVE_PARTY[0]` are the same object, so combat write-back updates the canonical lead record;
- onboarding now fixes the starting identities as Ender, Lyra, and Ionia; Lyra and Ionia are no longer player-renamable companion slots;
- Sky-Sailor, Engine-Wright, and Aether-Weaver remain selectable **field-role mechanics templates** for the current pre-alpha slice and are recorded separately from authored identity/native-job canon;
- Lyra and Ionia's canonical `nativeJob` values remain unresolved/null rather than being inferred from those templates;
- Reson and Aepex remain identity-only runtime shells until their authored mechanics/recruitment work lands;
- formation switching and true three-character combat are **not** enabled yet.

The temporary field-role templates remain implementation provenance rather than final character canon.

## Persistence boundary

`modules/save-state.js` defines the current `aetherwake-save` schema version **2**.

Schema v2 persists:

- canonical roster identity and active-party IDs;
- allowlisted progression/resource state;
- bounded World position and quest state;
- Mycelial Ledger history;
- bounded Dragonfly/Wakeheart state.

Schema v1 documents migrate through an explicit v1 → v2 migration. Canonical authored identity remains code-owned during restore, and roster object identity is preserved.

The persistence boundary intentionally excludes encounter-local combat state and presentation/transient state. Save/load is a player-facing feature, but it remains fail-closed: unsupported, unversioned, future-version, invalid, or identity-tampered documents are rejected rather than guessed into a usable state.

## Current quest vertical slice

The existing prototype quest follows:

**Signal → Crossing → Contact → Choice → Wake**

It includes signal hooks, traversal hazards, NPC encounters, three major choice paths, and multiple epilogue outcomes. This is a vertical-slice narrative structure, not the complete campaign.

## Repository layout

| Path | Purpose |
|---|---|
| `aetherwake.js` | Current integrated runtime / preservation build |
| `index-embedded.html` | Current browser and packaged-app entry point |
| `modules/effect-vocabulary.js` | Current effect vocabulary + action effect profiles |
| `modules/effect-resolver.js` | Fail-closed ordinary mutation resolver for damage/restoration/resources |
| `modules/ability-defs.js` | Canonical metadata for the eight current combat actions |
| `modules/progression-defs.js` | Canonical current level-unlock table |
| `modules/mastery-defs.js` | Code-owned mastery/domain facts, Ender affinities, and explicit UNKNOWN companion canon |
| `modules/party-state.js` | Authoritative persistent roster / active-party reference layer |
| `modules/char-create.js` | Authored Ender/Lyra/Ionia onboarding adapter with temporary field-role mechanics |
| `modules/save-state.js` | Versioned schema-v2 save/load boundary and v1 → v2 migration |
| `modules/airship-state.js` | Pure Dragonfly Wakeheart power, charge, veil, cooldown, and action rules |
| `modules/airship-combat-bridge.js` | Renderer-free one-shot airship-to-combat transfer and mitigation rules |
| `modules/airship-ui.js` | Dragonfly-class ship systems console renderer |
| `modules/air-navigation.js` | Pure sky-navigation geography/state: altitude, routes, weather, docking, and deterministic encounter cadence |
| other `modules/*.js` | Older modular mirrors/reference source; not authoritative runtime for all systems |
| `SPEC.md` | Current technical target + implementation notes |
| `docs/DOCUMENTATION_AUTHORITY.md` | Documentation routing, current-state summary, superseded claims, and open-canon boundaries |
| `docs/DEVELOPMENT.md` | Development authority, migration rules, and smoke gate |
| `docs/JRPG_COMBAT_DIRECTION.md` | Approved target combat architecture and migration policy |
| `docs/DESKTOP_BUILD.md` | Windows packaging, artifact, and launch contract |
| `gap_analysis.md` | Snapshot audit of prototype conformance |
| `memories_adaptation_catalog.md` | Adaptation/provenance reference |
| `tests/` | Canonical automated smoke/regression tests |

## Verification

Install dependencies and Chromium once:

```bash
npm install
npm run playwright:install
```

Run the complete current verification gate:

```bash
npm run test:all
```

`test:all` covers runtime contracts, combat policy/formulas, JRPG input/control surfaces, authored onboarding, canon reconciliation, schema-v2 save state and migration, mastery and magic-access definitions, Aether Sense, foundation-spell admission, field-role definitions, party-combat and companion-action contracts, effect vocabulary/resolver integration, enemy metadata, transactional resource eligibility, progression reachability, secondary-action state, Dragonfly state/bridge behavior, regression suites, desktop-package structure, the one-file Windows launcher contract, and the canonical browser smoke path.

Useful focused checks include:

```bash
npm run test:combat-policy
npm run test:combat-formula
npm run test:jrpg-controls
npm run test:onboarding
npm run test:save-state
npm run test:airship
npm run test:desktop-package
npm run test:one-file-launcher
npm run test:smoke
```

The smoke path verifies startup through authored onboarding, World state, combat, Dragonfly ship interactions, and return to `WORLD`, including post-combat write-back into the canonical lead record.

## Architecture direction

The production migration is incremental:

1. establish one verified playable baseline — **established**;
2. introduce persistent five-character roster state — **established**;
3. formalize effect vocabulary and extract the current ability/progression registries — **established on `dev/progression-build`**;
4. migrate combat from preservation-era 2D6/PbtA resolution to conventional JRPG formulas — **Staff Strike, Hold, and Rest migrated; five actions remain on compatibility behavior**;
5. enforce learned/unlocked action eligibility and transactional resource checks — **established**;
6. replace prototype companion naming with authored Ender/Lyra/Ionia onboarding — **identity migration established; canonical Lyra/Ionia jobs remain unresolved**;
7. implement school/job/mastery progression — **Phase-A definitions/access contracts established; full mutable mastery progression remains incomplete**;
8. integrate formation selection, true three-character combat, Dual Arts, and Triple Arts — **bridge/contracts in progress; full runtime not yet enabled**;
9. expand campaign content after the architecture is stable.

Each phase must preserve a working playable loop.

## Provenance

Aetherwake adapts selected code structures, interaction patterns, and reference-game lessons from *Memories* while developing its own setting, characters, narrative, combat/progression model, and authored party structure.

See `memories_adaptation_catalog.md` for the working adaptation catalog.

## Author

Andrew Hensel (ndrorchestration)

## Credits

Reference loading-screen UX and adaptation study: *Memories 0.7.4*. Fonts include VT323 and Press Start 2P. TTS tooling uses Microsoft Edge TTS where generated voice assets are available.
