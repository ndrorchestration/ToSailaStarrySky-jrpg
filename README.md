# Aetherwake

Aetherwake is a **pre-alpha turn-based JRPG** built with p5.js and adapted from selected technical patterns and reference material from *Memories 0.7.4*. You play Ender aboard the solarpunk airship *Aureate Wake*, as a storm at Wake Dock reveals that the ship can exceed ordinary performance only when the right crew resonates with it.

The current repository contains a playable vertical-slice prototype plus an active architecture migration toward the full authored-party RPG.

## Development status

- **Stage:** late prototype / pre-alpha
- **Playable baseline:** boot → First Wake opening → world exploration → dialogue/quest systems → combat
- **Target roster:** 5 authored playable protagonists — Ender, Lyra, Ionia, Reson, Aepex
- **Combat party target:** supports 1–5 active authored protagonists, growing through recruitment; First Wake now begins with Ender alone, adds Lyra first, and brings Ionia officially into the early storm/shield sequence
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
ROSTER[5] → ACTIVE_PARTY[1..5] → combat
```

Persistent progression belongs to the five-character roster. The target combat/menu architecture supports all five simultaneously once recruited; the active party grows from 1 → 2 → 3 → 4 → 5 through the story.

### Current migration state

The development runtime now has the first persistent party-state layer:

- `modules/party-state.js` owns exactly five stable roster identities: `ender`, `lyra`, `ionia`, `reson`, and `aepex`;
- `ACTIVE_PARTY` is validated for 1–5 direct references into `ROSTER`; First Wake now begins with Ender alone, recruits Lyra at Sequence 06, and brings Ionia officially into the early storm/shield sequence;
- `world.player`, `ROSTER[0]`, and `ACTIVE_PARTY[0]` are the same object, so combat write-back updates the canonical lead record;
- the preserved character-creation flow still creates two player-named prototype companions and prototype jobs, then adapts them into the Lyra/Ionia roster slots;
- Reson and Aepex are identity-only runtime shells until authored onboarding/mechanics are migrated;
- full authored five-character simultaneous combat is **not** enabled yet; the architecture now permits 1–5 active members while authored recruitment/onboarding is migrated.

The prototype names/jobs remain implementation provenance rather than final character canon.

## Current quest vertical slice

The existing prototype quest follows:

**Signal → Crossing → Contact → Choice → Wake**

It includes signal hooks, traversal hazards, NPC encounters, three major choice paths, and multiple epilogue outcomes. In the current Act I slice, those paths are leave early, hold dock, or project the Wake's shield across neighboring berths. This is a vertical-slice narrative structure, not the complete campaign.

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
| `modules/first-wake-opening.js` | Active authored New Game → First Wake opening controller |
| `modules/char-create.js` | Historical compatibility adapter; not the normal New Game path |
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

The verification suite covers the playable path from startup through the authored First Wake opening, world/overlay interactions, combat, flight-return seams, and return to the correct originating state. It also verifies roster/reference invariants, effect-vocabulary coverage, registry/runtime equivalence, transactional action affordability, progression reachability, party capacity, magic contracts, air-navigation behavior, live resolver routing, and post-combat write-back into the canonical lead record.

To produce local review material without converting it into acceptance, run:

```bash
npm run capture:player-evidence
```

This creates `evidence/player-acceptance/<source-sha>-<timestamp>/` with screenshots and a manifest whose human/player and visual acceptance fields remain explicitly pending.

## Visual authority

The canonical project-wide visual direction is defined in:

- `docs/VISUAL_BIBLE.md` — project-wide visual language;
- `docs/VISUAL_BENCHMARK_SCENE.md` — first final-quality acceptance scene;
- `docs/CINEMATIC_CLIP_CONTRACT.md` — authored short-video integration rules.

These documents sit above individual art branches. Existing pixel-art recovery work is implementation material and must be reconciled against the visual bible before broad promotion.

## Architecture direction

The production migration is incremental:

1. establish one verified playable baseline,
2. introduce persistent five-character roster state,
3. formalize effect vocabulary and extract the current ability/progression registries — **integrated on `main`**,
4. migrate production combat away from legacy 2D6 branches into explicit JRPG formula/contract resolution while preserving only quarantined compatibility behavior,
5. enforce current learned/unlocked action eligibility before broader mastery-tree work — **integrated on `main`**,
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

The intended player experience is **download one Windows artifact, launch/install it, and run Aetherwake in its own large resizable/maximizable desktop window**. The desktop presentation defaults to **1440×960** and scales proportionally when maximized, while preserving the 960×640 logical game layout. **Alt+Enter** or **F11** toggles native fullscreen; **Escape** exits fullscreen. Browser/HTTP instructions above are development and diagnostic paths, not the desired end-user experience.

### Current Preview 0.1 release authority — 2026-10-06

The runtime baseline before the documentation-only reconciliation was `875503662d9a9cff64eb6ec1bbbeedbfcc3ccbe3`. Documentation merges may advance protected `main` without changing player-runtime bytes. The current bounded Preview 0.1 remediation/review candidate remains PR #250 at exact head `46f50c581d992bf581bb6b6d7961a9421b8b779d`; candidate identity is bound to that exact SHA and artifact hashes, not to a moving `main` pointer.

Technical candidate verification is complete for that exact head:

- hosted smoke run `37557721548`: **PASS**;
- fresh seven-frame player-evidence capture on NeonPC: **CAPTURED** from exact head `46f50c...`;
- title/menu evidence timing: **corrected and observed**;
- prior opaque cyan/teal scanline defect: **not reproduced**;
- local packaged `Aetherwake.exe` first-frame readiness on NeonPC: **PASS**;
- workflow-dispatch Windows run `37559269564`: **SUCCESS** through package build, no-admin installer, exact installed launch, portable verification, SHA-256 manifest, and prerelease publication;
- the published installer was independently downloaded, SHA-256 checked, installed, and launched on NeonPC: **PASS**.

Current published Preview 0.1 candidate:

```text
SOURCE_SHA=46f50c581d992bf581bb6b6d7961a9421b8b779d
INSTALLER_SHA256=7feb6de364264617095a59dd9329a99ebfa77a144b0f5887a7ae7ff064f6221d
PORTABLE_ZIP_SHA256=4c6efc6ea1cecf6468fb983fd8ff5fd5d0ce8645262779551841f663c5326173
TECHNICAL_CANDIDATE_VERIFICATION=PASS
HUMAN_REVIEW=NOT_RUN
VISUAL_ACCEPTANCE=PENDING
HUMAN_PLAYER_ACCEPTANCE=PENDING
```

PR #250 is ready for human review but is not merged. The historical Google Drive one-click launchers still point to older candidates and must not be treated as the current acceptance target.

For the exact uncoached human/player acceptance protocol, see `docs/PREVIEW_0_1_ACCEPTANCE.md`.

When a fresh candidate passes the exact Windows install/launch gate, the primary player artifact will be:

- **Aetherwake-Setup.exe** — conventional per-user installer; no administrator elevation; creates normal Start Menu and desktop shortcuts.
- **Aetherwake-Windows.zip** — portable fallback. Extract completely, then run **Aetherwake.exe**.

If Windows Defender flags an executable, do not whitelist or bypass it. Record the exact detection name and SHA-256 so the artifact can be audited.

See `docs/DESKTOP_BUILD.md` for the canonical packaging and verification contract.