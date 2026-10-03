# Aetherwake — The Last Solarpunk Airship

Aetherwake is a **pre-alpha turn-based JRPG** built with p5.js and adapted from selected technical patterns and reference material from *Memories 0.7.4*. You play Ender aboard the *Aureate Wake*, the last solarpunk airship, as a storm at Wake Dock reveals that the ship can exceed ordinary performance only when the right crew resonates with it.

The current repository contains a playable vertical-slice prototype plus an active architecture migration toward the full authored-party RPG.

## Development status

- **Stage:** late prototype / pre-alpha
- **Playable baseline:** boot → First Wake opening → world exploration → dialogue/quest systems → combat
- **Target roster:** 5 authored playable protagonists — Ender, Lyra, Ionia, Reson, Aepex
- **Combat party target:** supports 1–5 active authored protagonists, growing through recruitment; First Wake begins with Ender alone, adds Lyra first, and brings Ionia officially into the early storm/shield sequence
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
- `ACTIVE_PARTY` is validated for 1–5 direct references into `ROSTER`; authored New Game begins with Ender alone, then recruits Lyra at First Wake Sequence 06;
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

### Current release authority — 2026-09-22

- The desktop launcher architecture was corrected at `304835c12555e35061870a54d61f7c95996d0bdd`; the release-critical single-Windows-job hardening that removes Actions artifact storage/transfer is current on `main` at `313d7eb2aee003ce51a23edf48532f64d30f2bc0`.
- Production packaging now follows the RPG Maker MV/NW.js structural pattern used by the Memories reference: a minimal launcher-root `package.json` points to `www/index-embedded.html`, while the player runtime lives under `www/`.
- Development-only files are excluded from the staged player runtime.
- The release system produces **Aetherwake-Setup.exe** plus **Aetherwake-Windows.zip**, verifies those exact bytes on the same pinned Windows job, records SHA-256 hashes, and publishes only after install/launch verification. GitHub Actions artifact storage is deliberately excluded from the release-critical path because that quota has already caused a real packaging failure.
- A local Windows fallback script, `scripts/build-windows-release.ps1`, performs build → installer compile → clean install → launch smoke → SHA-256 generation when hosted CI is unavailable.
- Current GitHub-hosted verification is **blocked before execution**, not failing inside Aetherwake: on `main` `313d7eb2aee003ce51a23edf48532f64d30f2bc0`, Windows package run `35694446836` and smoke run `35694446855` both ended with `runner_id: 0` and zero steps.
- Therefore **no newly generated installer is currently authorized as verified player-facing output**. Older installers and self-extracting wrappers remain historical artifacts and should not be presented as the current answer merely because they compiled or passed an older CI lane.

When a fresh candidate passes the exact Windows install/launch gate, the primary player artifact will be:

- **Aetherwake-Setup.exe** — conventional per-user installer; no administrator elevation; creates normal Start Menu and desktop shortcuts.
- **Aetherwake-Windows.zip** — portable fallback. Extract completely, then run **Aetherwake.exe**.

If Windows Defender flags an executable, do not whitelist or bypass it. Record the exact detection name and SHA-256 so the artifact can be audited.

See `docs/DESKTOP_BUILD.md` for the canonical packaging and verification contract.
