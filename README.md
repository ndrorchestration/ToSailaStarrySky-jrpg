# Aetherwake — The Last Solarpunk Airship

Aetherwake is a **pre-alpha turn-based JRPG** built with p5.js and adapted from selected technical patterns and reference material from *Memories 0.7.4*. You play Ender aboard the *Aureate Wake*, the last solarpunk airship, as a failing aether-core, impossible sky-lanes, and a fractured world begin to reveal the same unfinished song.

The current repository contains a playable vertical-slice prototype plus an active architecture migration toward the full authored-party RPG.

## Development status

- **Stage:** late prototype / pre-alpha
- **Playable baseline:** boot → character creation → world exploration → dialogue/quest systems → combat
- **Target roster:** 5 authored playable protagonists — Ender, Lyra, Ionia, Reson, Aepex
- **Combat party:** exactly 3 active combatants selected from the persistent roster
- **Current migration:** smoke-green persistent roster, authored Ender/Lyra/Ionia onboarding, explicit prototype-mechanics provenance, versioned party/progression save schema v1, effect vocabulary/resolver contracts, centralized transactional use eligibility, reachable level-gated progression, and corrected secondary-action state; complete game-state persistence and higher-order effect semantics remain separate gates

See `SPEC.md` for the implementation/target split and `docs/DEVELOPMENT.md` for source-of-truth and verification rules.

## Run the game

### Windows — simplest player path

Use the **Aetherwake-Windows** artifact produced by the **Windows desktop package** GitHub Actions workflow. Extract the ZIP completely, then double-click `Aetherwake.exe`. Keep the extracted files together.

The desktop build does not require Python, PowerShell, a development server, or Node.js on the player's computer.

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

Aetherwake now exposes the versioned save system through player-facing quick controls:

- **F2 — Quick Save:** writes the current schema-v2 save only from normal `WORLD` state.
- **F3 — Quick Load:** restores a valid save from menu, onboarding, or normal `WORLD` state and returns to `WORLD`.
- combat, dialogue, shop, ledger, quest, character-sheet, and airship-console states reject quick-save/load actions that would cross an unsafe transient boundary.
- restored data includes canonical party/progression state, World position/quest/ledger state, and bounded Dragonfly system state.
- load re-synchronizes the combat snapshot from the restored canonical World/roster record.
- older schema-v1 saves migrate through the explicit v1 → v2 migration path.

The save document deliberately excludes encounter-local combat and presentation state. Invalid, unversioned, future-version, or identity-tampered saves fail closed rather than being guessed into a usable state.

## Dragonfly Wake console

Stand near the ship's core chamber and press **F** to board the compact Dragonfly-class *Aureate Wake*. The hull volume is fixed at **three shipping containers**, excluding masts, wings, and rigging.

Inside the console:

- **1** — Phase-Slip Wake Drive
- **2 / H** — cycle Harmonic Phase Veil mode
- **3** — Resonance Lance
- **4** — Rootline Tether
- **5** — Pattern Forge
- **R** — vent the Wakeheart, reduce heat, advance cooldowns, and recover one power cell
- **ESC / L** — return to the world

The console is the first playable ship-systems slice. Its power and charge budgets are intentionally bounded, and its one-shot systems now hand off to the next encounter: Resonance Lance opens with a bounded strike, Guard veil absorbs the first point of incoming damage, Slip veil can phase through the first hit, Resonance veil sharpens the first crew roll, and Phase-Slip explicitly phases the first damaging strike.

## Combat prototype

**Target combat direction:** conventional JRPG stat-and-ability formulas with bounded secondary RNG. There is no player-facing dice system in the production target, and PbtA success/partial/failure bands are being retired. See `docs/JRPG_COMBAT_DIRECTION.md`.

**Current migration runtime:** combat is now hybrid while the engine is converted incrementally.

- **Resonator Staff / Staff Strike:** live **JRPG damage formula**; Might-scaled EMP damage, one staff charge, bounded damage variance and critical policy, no visible dice/outcome bands.
- **Hold:** live **deterministic JRPG resource formula**; restores one Resonator Staff charge up to the current maximum, with no roll bands or self-damage.
- **The remaining six actions:** still use the preservation-era **2D6 + stat** compatibility path (10+ / 7–9 / 6−) until each receives a production formula/effect contract.

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
| 8 | Rest | heat / vitality recovery |

Current prototype progression unlocks **Wind Ward at level 3, Aether Seal at level 4, and Rest at level 5**.

The remaining 2D6 action definitions are a **legacy implementation baseline**, not the final architecture. Staff Strike and Hold are the first two actions migrated out of that baseline. The target system uses data-driven ability formulas, explicit prerequisites, a generic effect resolver, bounded accuracy/critical/status variance where appropriate, school mastery, jobs, and party-combination arts.

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

The development branch now includes `modules/save-state.js` with explicit
`aetherwake-save` schema version **1**. This first schema deliberately covers
the canonical roster, active-party IDs, and allowlisted progression/resource
state while preserving roster object identity during restore.

It is an architecture/compatibility checkpoint, **not yet a complete
player-facing save system**. Quest/world position, world-layer state, ledger
history, and Dragonfly state still require explicit persistence contracts before
save/load should be exposed as a finished player feature. Unsupported,
unversioned, future, or identity-tampered save data fails closed.


## Current quest vertical slice

The existing prototype quest follows:

**Signal → Crossing → Contact → Choice → Wake**

It includes signal hooks, traversal hazards, NPC encounters, three major choice paths, and multiple epilogue outcomes. This is a vertical-slice narrative structure, not the complete campaign.

## Repository layout

| Path | Purpose |
|---|---|
| `aetherwake.js` | Current integrated runtime / preservation build |
| `index-embedded.html` | Current browser entry point |
| `modules/effect-vocabulary.js` | Frozen effect vocabulary v0.1 + current action effect profiles |
| `modules/effect-resolver.js` | Fail-closed ordinary mutation resolver for damage/restoration/resources |
| `modules/ability-defs.js` | Canonical metadata for the eight current combat actions |
| `modules/progression-defs.js` | Canonical current level-unlock table |
| `modules/mastery-defs.js` | Code-owned mastery/domain facts, Ender affinities, and explicit UNKNOWN companion canon |
| `modules/party-state.js` | Authoritative persistent roster / active-party reference layer |
| `modules/char-create.js` | Active preservation character-creation adapter |
| `modules/airship-state.js` | Pure Dragonfly Wakeheart power, charge, veil, cooldown, and action rules |
| `modules/airship-combat-bridge.js` | Renderer-free one-shot airship-to-combat transfer and mitigation rules |
| `modules/airship-ui.js` | Dragonfly-class ship systems console renderer |
| other `modules/*.js` | Older modular mirrors/reference source; not authoritative runtime for all systems |
| `SPEC.md` | Current technical target + implementation notes |
| `docs/DEVELOPMENT.md` | Development authority, migration rules, smoke gate |
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

Run the architecture contracts and canonical smoke test:

```bash
npm run test:onboarding
npm run test:save-state
npm run test:effects
npm run test:registries
npm run test:resolver
npm run test:resolver-integration
npm run test:enemy-metadata
npm run test:combat-input
npm run test:resource-eligibility
npm run test:progression-reachability
npm run test:secondary-action
npm run test:airship
npm run test:airship-combat-bridge
npm run test:smoke
```

The verification suite covers the playable path from startup through authored onboarding, world state, combat, Dragonfly ship boarding/system actions, and return to WORLD. It also verifies roster/reference invariants, authored-identity/prototype-mechanics separation, save-schema v1 fail-closed behavior, effect-vocabulary coverage, registry/runtime equivalence, transactional action affordability, progression reachability, secondary-action state, enemy metadata propagation, live resolver routing, and post-combat write-back into the canonical lead record.

## Architecture direction

The production migration is incremental:

1. establish one verified playable baseline,
2. introduce persistent five-character roster state,
3. formalize effect vocabulary and extract the current ability/progression registries — **established on `dev/progression-build`**,
4. route ordinary combat mutations through a generic effect resolver while preserving current 2D6 outcome behavior — **damage/restoration/resource routing established on `dev/progression-build`**,
5. enforce current learned/unlocked action eligibility before broader mastery-tree work — **established on `dev/progression-build`**,
6. replace prototype companion creation with authored roster onboarding — **identity migration established on `dev/progression-build`; canonical companion jobs/mechanics remain unresolved**,
7. implement school/job/mastery progression — **Phase A definitions established; mutable mastery/save-v3 state not yet implemented**,
8. add formation, Dual Arts, and Triple Arts,
9. expand campaign content after the architecture is stable.

Each phase should preserve a working combat loop.

## Provenance

Aetherwake adapts selected code structures, interaction patterns, and reference-game lessons from *Memories* while developing its own setting, characters, narrative, combat/progression model, and authored party structure.

See `memories_adaptation_catalog.md` for the working adaptation catalog.

## Author

Andrew Hensel (ndrorchestration)

## Credits

Reference loading-screen UX and adaptation study: *Memories 0.7.4*. Fonts include VT323 and Press Start 2P. TTS tooling uses Microsoft Edge TTS where generated voice assets are available.
