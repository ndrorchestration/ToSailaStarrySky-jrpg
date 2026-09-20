# Aetherwake — The Last Solarpunk Airship

Aetherwake is a **pre-alpha 2D6 PbtA JRPG** built with p5.js and adapted from selected technical patterns and reference material from *Memories 0.7.4*. You play Ender aboard the *Aureate Wake*, the last solarpunk airship, as a failing aether-core, impossible sky-lanes, and a fractured world begin to reveal the same unfinished song.

The current repository contains a playable vertical-slice prototype plus an active architecture migration toward the full authored-party RPG.

## Development status

- **Stage:** late prototype / pre-alpha
- **Playable baseline:** boot → character creation → world exploration → dialogue/quest systems → combat
- **Target roster:** 5 authored playable protagonists — Ender, Lyra, Ionia, Reson, Aepex
- **Combat party:** exactly 3 active combatants selected from the persistent roster
- **Current migration:** smoke-green persistent roster, effect vocabulary/resolver contracts, centralized transactional use eligibility, reachable level-gated progression, and corrected secondary-action state; higher-order effect semantics remain separate gates

See `SPEC.md` for the implementation/target split and `docs/DEVELOPMENT.md` for source-of-truth and verification rules.

## Run the game

Open `index-embedded.html` in a modern browser.

The development runtime is designed to work offline and uses:

- embedded fonts,
- bundled p5.js,
- embedded/reference loading assets,
- local JavaScript modules,
- optional generated TTS assets when present.

Current canvas: **960×640**.

## Controls

| Key | Action |
|---|---|
| **WASD / arrows** | Move |
| **E** | Talk / interact / advance dialogue |
| **Q** | Plant Covenant Field |
| **F** | Board / interact with ship |
| **Tab** | Toggle sky / ground layer |
| **L** | Mycelial ledger |
| **M** | Repair Cafe / shop |
| **R** | Character sheet |
| **T** | Quest log |
| **N / Enter / Space** | Start / confirm |
| **C** | Trigger Sky-Predator encounter (development/testing) |
| **1–8** | Combat actions |
| **S** | Secondary combat action when available |

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

Combat uses **2D6 + stat**:

- **10+** — full success
- **7–9** — partial success / cost
- **6−** — failure / complication

The current preservation baseline contains eight combat actions:

| # | Action | Role |
|---:|---|---|
| 1 | Resonator Staff | EMP attack |
| 2 | Uncover Truth | Wits / reveal |
| 3 | Shared Dream | Spirit / support |
| 4 | Mycelial Ledger | Presence / resource recovery |
| 5 | Hold | conserve / recharge |
| 6 | Wind Ward | defensive ability |
| 7 | Aether Seal | defensive / aether ability |
| 8 | Rest | heat / vitality recovery |

Current prototype progression unlocks **Wind Ward at level 3, Aether Seal at level 4, and Rest at level 5**.

These flat combat definitions are an implementation baseline, not the final architecture. The target system uses data-driven ability definitions, explicit prerequisites, a generic effect resolver, school mastery, jobs, and party-combination arts.

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
- the preserved character-creation flow still creates two player-named prototype companions and prototype jobs, then adapts them into the Lyra/Ionia roster slots;
- Reson and Aepex are identity-only runtime shells until authored onboarding/mechanics are migrated;
- formation switching and three-character combat are **not** enabled yet.

The prototype names/jobs remain implementation provenance rather than final character canon.

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
| `modules/party-state.js` | Authoritative persistent roster / active-party reference layer |
| `modules/char-create.js` | Active preservation character-creation adapter |
| `modules/airship-state.js` | Pure Dragonfly Wakeheart power, charge, veil, cooldown, and action rules |
| `modules/airship-combat-bridge.js` | Renderer-free one-shot airship-to-combat transfer and mitigation rules |
| `modules/airship-ui.js` | Dragonfly-class ship systems console renderer |
| other `modules/*.js` | Older modular mirrors/reference source; not authoritative runtime for all systems |
| `SPEC.md` | Current technical target + implementation notes |
| `docs/DEVELOPMENT.md` | Development authority, migration rules, smoke gate |
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

The verification suite covers the playable path from startup through character creation, world state, combat, Dragonfly ship boarding/system actions, and return to WORLD. It also verifies roster/reference invariants, effect-vocabulary coverage, registry/runtime equivalence, transactional action affordability, progression reachability, secondary-action state, enemy metadata propagation, live resolver routing, and post-combat write-back into the canonical lead record.

## Architecture direction

The production migration is incremental:

1. establish one verified playable baseline,
2. introduce persistent five-character roster state,
3. formalize effect vocabulary and extract the current ability/progression registries — **established on `dev/progression-build`**,
4. route ordinary combat mutations through a generic effect resolver while preserving current 2D6 outcome behavior — **damage/restoration/resource routing established on `dev/progression-build`**,
5. enforce current learned/unlocked action eligibility before broader mastery-tree work — **established on `dev/progression-build`**,
6. replace prototype companion creation with authored roster onboarding,
6. implement school/job/mastery progression,
7. add formation, Dual Arts, and Triple Arts,
8. expand campaign content after the architecture is stable.

Each phase should preserve a working combat loop.

## Provenance

Aetherwake adapts selected code structures, interaction patterns, and reference-game lessons from *Memories* while developing its own setting, characters, narrative, combat/progression model, and authored party structure.

See `memories_adaptation_catalog.md` for the working adaptation catalog.

## Author

Andrew Hensel (ndrorchestration)

## Credits

Reference loading-screen UX and adaptation study: *Memories 0.7.4*. Fonts include VT323 and Press Start 2P. TTS tooling uses Microsoft Edge TTS where generated voice assets are available.
