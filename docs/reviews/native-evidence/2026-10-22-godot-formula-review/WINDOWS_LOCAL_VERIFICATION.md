# First Wake native production-formula review encounter — Windows verification
**Date:** 2026-10-22  
**Exact exercised/package source:** `64bf2e1e4639929f4526c4620bb67607491ebefe`  
**Parent:** production formula authority from draft PR #342  
**Scope:** private native-review evidence only; not canonical encounter admission or public release acceptance.

## Purpose
This increment makes the already-authorized native JRPG formula subset **playable inside the native Chapter I Windows preview** without inventing a current-story enemy or altering Chapter I progression.

Repository research confirmed that `Sky-Predator` is a historical/development encounter label and is not current Chapter I story canon, while the current `sky_predator` hazard ID is presented as **Loose Cargo Sweep**. The new encounter therefore uses the explicit noncanonical **Formula Review Target** rather than silently reintroducing a historical enemy.

## Review controller
`godot/scripts/first_wake_formula_encounter.gd`:
- consumes the native production stat model and production combat formula authority;
- supports only the authorized generic subset: Staff Strike, Uncover Truth, Hold, Rest;
- keeps RNG injected for deterministic tests;
- tracks VIT, staff charges, heat, target HP, analysis modifier, turns and review log;
- rejects blocked/unknown actions;
- cannot mutate Chapter I progression;
- remains transient across durable Chapter I save/restore.

Native review controls:
- `C` — open/close Formula Review;
- `1` — Staff Strike;
- `2` — Uncover Truth;
- `3` — Hold;
- `4` — Rest.

The overlay explicitly displays: **Production JRPG math · noncanonical target · Chapter I progress unchanged**.

## Exact Windows Godot 4.7.2 tests — PASS
Authorized host: `neontic`.

At exact head `64bf2e1e...`:
- `AETHERWAKE_GODOT_CHAPTER1_CONTENT_PASS`
- `AETHERWAKE_GODOT_CHAPTER1_DIALOGUE_PASS`
- `AETHERWAKE_GODOT_CHAPTER1_DIALOGUE_SCENE_PASS`
- `AETHERWAKE_GODOT_CHAPTER1_FSM_PASS`
- `AETHERWAKE_GODOT_CHAPTER1_SAVE_PASS`
- `AETHERWAKE_GODOT_CHAPTER1_SAVE_SCENE_PASS`
- `AETHERWAKE_GODOT_JRPG_STAT_MODEL_PASS`
- `AETHERWAKE_GODOT_COMBAT_FORMULA_PASS`
- `AETHERWAKE_GODOT_FORMULA_REVIEW_ENCOUNTER_PASS`
- `AETHERWAKE_GODOT_FORMULA_REVIEW_SCENE_PASS`
- `AETHERWAKE_GODOT_CHAPTER1_SCENE_PASS`
- `AETHERWAKE_GODOT_WINDOWS_EXPORT_CONTRACT_PASS`

The real-scene review test proves that opening, acting in, completing and closing the formula encounter leaves the Chapter I snapshot unchanged. Durable save export contains no combat/formula-review state; restoring a Chapter I save closes the transient review.

## Native renderer — PASS
Real Windows OpenGL 3.3 / Intel Iris Xe produced eight distinct 960×640 frames:

| State | SHA-256 |
| --- | --- |
| Signal | `325b02a4fe995be7d3ad9f46796aaf0a60a8c2cae9721a5f9323466dd7163b29` |
| Formula Review | `95e4c6dddf643b5ef75d4f5251ba8a530ef3e2a322879e0736f1a920d822aa2e` |
| Dialogue | `11c0b8817f6cd2ef55acdd4cc573d010c100c2516049ebcefaee5512d2c2aec2` |
| Crossing | `1ecfe8b90fc0917de1dff70c8700d6605b7bff034e0a272210024f3a2b25c780` |
| Contact | `3f73517b856d80999872e7dc3473f9f6e7726ac0b6db30d51916b2c6003ab7e0` |
| Choice | `bd5de195a4c0ddf5ff350b8b5cb4477f663e9c2866870db1786ea5f60a17b50f` |
| Wake | `6aa4cba6b9151948d24b7e516d474d901501a12b5f19d8783e3c35b8ba0c41b8` |
| Done | `a037b54ae583f7d3c4b009fcc6f82a5aba4816bf5f10291a38de288c63fcf638` |

Renderer assertion:
`AETHERWAKE_GODOT_CHAPTER1_NATIVE_RENDER_PASS: Signal, Formula Review, Dialogue, Crossing, Contact, Choice, Wake and Done are visibly distinct 960x640 native frames`.

The Formula Review frame was directly inspected and clearly separates the noncanonical production-math review from Chapter I state.

## Exact native Windows export
The Windows build gate reran all Chapter I/content/dialogue/save/formula/review/export contracts before export.

Godot console binary was used for synchronous PowerShell process custody; attempting the GUI binary first produced a blank `$LASTEXITCODE`, which was treated as a tooling invocation failure rather than a game failure.

`Aetherwake-First-Wake-Godot-Preview.exe`
- size: **113,585,520 bytes**
- SHA-256: `0d5e0493826260223d29b378e563fdf803099ecd9fb6cc4fb32aff47835c48a8`

## Exact installable native ZIP
`Aetherwake-First-Wake-Godot-Native-Preview-Windows.zip`
- size: **42,383,583 bytes**
- SHA-256: `1ca8d70c2b0370531f2adbd34a9c50100d7646d80ec6314e9c6dbafd18741e2d`
- packaged EXE SHA-256: `0d5e0493826260223d29b378e563fdf803099ecd9fb6cc4fb32aff47835c48a8`
- install wrapper SHA-256: `c9e75b1deb541c3433ef170ca48a694e02910016a0e08220579d674d7fc6106c`
- uninstall wrapper SHA-256: `c62428deb7fe59e52f32a3b43fac8a0b61e7136597eff9eade51e981122c3e4f`

## Defender + install custody — PASS
No exclusions, allowlisting, protection disabling, execution-policy bypass, administrator elevation or NSIS were used.

Microsoft Defender custom scans reported no threats for:
- exact install wrapper;
- exact uninstall wrapper;
- exact packaged executable;
- complete exact ZIP.

Fresh exact-ZIP install:
- per-user install: PASS;
- Desktop shortcut: PASS;
- Start Menu shortcut: PASS;
- responsive native window: PASS;
- title: `Aetherwake - First Wake Chapter I Native Preview`.

Packaged uninstall invoked while the game remained running:
- installed process removed;
- install directory removed;
- Desktop shortcut removed;
- Start Menu folder removed;
- temporary cleanup copy removed.

Result: `GODOT_FORMULA_PREVIEW_EXACT_PACKAGE_QA=PASS`.

## Boundaries
This increment establishes a **playable production-formula review**, not combat parity.

Still unresolved:
- a current-story canonical enemy adapter;
- binding authored Chapter I hazards to production combat;
- party-wide combat;
- durable production-combat persistence;
- final battle sprites/animation/FX;
- creator visual acceptance;
- external-player acceptance;
- hosted exact-head verification;
- issue #293 disposition;
- public release authorization.

The existing fuller NW.js owner build remains rollback evidence while native parity continues.
