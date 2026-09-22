# Aetherwake — The Last Solarpunk Airship

Aetherwake is a **pre-alpha turn-based JRPG** built with p5.js and adapted from selected technical patterns and reference material from *Memories 0.7.4*. You play Ender aboard the *Aureate Wake*, the last solarpunk airship, as a failing aether-core, impossible sky-lanes, and a fractured world begin to reveal the same unfinished song.

The current repository contains a playable vertical-slice prototype plus an active architecture migration toward the full authored-party RPG.

## Development status

- **Stage:** late prototype / pre-alpha
- **Playable baseline:** boot → character creation → world exploration → dialogue/quest systems → combat
- **Target roster:** 5 authored playable protagonists — Ender, Lyra, Ionia, Reson, Aepex
- **Combat party target:** supports 1–5 active authored protagonists, growing through recruitment; current preservation runtime still initializes Ender/Lyra/Ionia first
- **Current migration:** smoke-green persistent roster, effect vocabulary/resolver contracts, centralized transactional use eligibility, reachable level-gated progression, and corrected secondary-action state; higher-order effect semantics remain separate gates

See `SPEC.md` for the implementation/target split and `docs/DEVELOPMENT.md` for source-of-truth and verification rules.

## Run the game

Use a local HTTP server for the reliable launch path. The canonical smoke test uses this same model.

From the repository folder:

```bash
python -m http.server 8080
```

Then open:

```text
http://127.0.0.1:8080/index-embedded.html
```

On Windows, you can also use:

```powershell
py -m http.server 8080
```

Opening the file directly may leave the loading screen or produce a blank canvas in some browser configurations because the verified runtime path is served over HTTP.

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

Combat is migrating to a **conventional JRPG formula model**. Production-native actions use explicit power/scaling, defenses, bounded accuracy/critical variance, costs, statuses, and deterministic analysis where appropriate. Legacy 2D6 behavior remains only in explicitly quarantined compatibility actions and historical mirrors.

The current action surface contains eight slots:

| # | Action | Role |
|---:|---|---|
| 1 | Resonator Staff | EMP attack |
| 2 | Uncover Truth | deterministic analysis / weakness reveal |
| 3 | Shared Dream | legacy compatibility residue; blocked by current Dreaming/Talen SSOT |
| 4 | Mycelial Ledger | Ender Commons read-only relationship analysis |
| 5 | Hold | deterministic staff recharge |
| 6 | Wind Ward | legacy compatibility residue; owner/domain unresolved |
| 7 | Aether Seal | Ender Aether/Ward suppression on explicit Aether-dependent targets |
| 8 | Rest | deterministic heat/vitality recovery |

Current prototype progression unlocks **Wind Ward at level 3, Aether Seal at level 4, and Rest at level 5**.

These flat combat definitions are an implementation baseline, not the final architecture. The target system uses data-driven ability definitions, explicit prerequisites, a generic effect resolver, school mastery, jobs, and party-combination arts.

## Party architecture

### Target

```text
ROSTER[5] → ACTIVE_PARTY[3] → combat
```

Persistent progression belongs to the five-character roster. The target combat/menu architecture supports all five simultaneously once recruited; the active party grows from 1 → 2 → 3 → 4 → 5 through the story.

### Current migration state

The development runtime now has the first persistent party-state layer:

- `modules/party-state.js` owns exactly five stable roster identities: `ender`, `lyra`, `ionia`, `reson`, and `aepex`;
- `ACTIVE_PARTY` is validated for 1–5 direct references into `ROSTER`; the current preservation bootstrap begins with Ender/Lyra/Ionia;
- `world.player`, `ROSTER[0]`, and `ACTIVE_PARTY[0]` are the same object, so combat write-back updates the canonical lead record;
- the preserved character-creation flow still creates two player-named prototype companions and prototype jobs, then adapts them into the Lyra/Ionia roster slots;
- Reson and Aepex are identity-only runtime shells until authored onboarding/mechanics are migrated;
- full authored five-character simultaneous combat is **not** enabled yet; the architecture now permits 1–5 active members while authored recruitment/onboarding is migrated.

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
npm run test:smoke
```

The verification suite covers the playable path from startup through character creation, world state, combat, and return to WORLD. It also verifies roster/reference invariants, effect-vocabulary coverage, registry/runtime equivalence, transactional action affordability, progression reachability, secondary-action state, enemy metadata propagation, live resolver routing, and post-combat write-back into the canonical lead record.

## Architecture direction

The production migration is incremental:

1. establish one verified playable baseline,
2. introduce persistent five-character roster state,
3. formalize effect vocabulary and extract the current ability/progression registries — **established on `dev/progression-build`**,
4. migrate production combat away from legacy 2D6 branches into explicit JRPG formula/contract resolution while preserving only quarantined compatibility behavior,
5. enforce current learned/unlocked action eligibility before broader mastery-tree work — **established on `dev/progression-build`**,
6. replace prototype companion creation with authored roster onboarding,
7. implement school/job/mastery progression,
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


## Windows desktop package

For the simplest player experience, use the **Aetherwake-Windows.zip** artifact produced by the **Windows desktop package** GitHub Actions workflow. Extract the ZIP completely, then double-click `Aetherwake.exe`. Keep the extracted files together.

The packaged build starts the game in its own window and does not require Python, PowerShell, or a manually started HTTP server. The browser instructions below remain the development and fallback path.

See `docs/DESKTOP_BUILD.md` for the packaging contract.
