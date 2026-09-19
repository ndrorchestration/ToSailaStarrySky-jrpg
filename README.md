# Aetherwake — The Last Solarpunk Airship

Aetherwake is a **pre-alpha 2D6 PbtA JRPG** built with p5.js and adapted from selected technical patterns and reference material from *Memories 0.7.4*. You play Ender aboard the *Aureate Wake*, the last solarpunk airship, as a failing aether-core, impossible sky-lanes, and a fractured world begin to reveal the same unfinished song.

The current repository contains a playable vertical-slice prototype plus an active architecture migration toward the full authored-party RPG.

## Development status

- **Stage:** late prototype / pre-alpha
- **Playable baseline:** boot → character creation → world exploration → dialogue/quest systems → combat
- **Target roster:** 5 authored playable protagonists — Ender, Lyra, Ionia, Reson, Aepex
- **Combat party:** exactly 3 active combatants selected from the persistent roster
- **Current migration:** preserve and stabilize the latest playable build before replacing prototype party/progression architecture

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

### Current prototype

The current `modules/char-create.js` still implements the older prototype flow:

- Ender is fixed,
- two player-named companions are created,
- prototype jobs are Sky-Sailor, Engine-Wright, and Aether-Weaver.

That flow is **preserved for provenance and runtime stabilization but is scheduled for replacement** by the authored roster.

## Current quest vertical slice

The existing prototype quest follows:

**Signal → Crossing → Contact → Choice → Wake**

It includes signal hooks, traversal hazards, NPC encounters, three major choice paths, and multiple epilogue outcomes. This is a vertical-slice narrative structure, not the complete campaign.

## Repository layout

| Path | Purpose |
|---|---|
| `aetherwake.js` | Current integrated runtime / preservation build |
| `index-embedded.html` | Current self-contained browser entry point |
| `modules/char-create.js` | Active prototype character-creation module |
| `modules/*.js` | Older modular mirrors/reference source; currently not authoritative runtime for all systems |
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

Run the canonical smoke test:

```bash
npm run test:smoke
```

The smoke gate is intended to cover the playable path from startup through character creation, world state, and combat.

## Architecture direction

The production migration is incremental:

1. establish one verified playable baseline,
2. introduce persistent five-character roster state,
3. formalize effect vocabulary and `ABILITY_DEFS`,
4. move combat to a generic effect resolver,
5. replace prototype companion creation with authored roster onboarding,
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
