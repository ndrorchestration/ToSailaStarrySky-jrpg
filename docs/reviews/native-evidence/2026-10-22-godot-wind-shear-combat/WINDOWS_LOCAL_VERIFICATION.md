# Aetherwake Godot — current Wind Shear Chapter I combat verification
**Date:** 2026-10-22  
**Draft PR:** #345 — `feat(godot): bind current Wind Shear combat to Chapter I Crossing`  
**Exact exercised code head:** `93703ce1443a517449d5884b4390452613e1a0f9`  
**Status:** operator-local native engineering/render verification PASS; exact Windows package artifact verification **NOT ESTABLISHED**.

## Scope and current-story boundary

This increment binds production JRPG formula resolution to exactly one current Chapter I hazard:

- `wind_shear` → live enemy `windShear` / **Harmonic Shear Elemental**.

It deliberately does **not** map:

- `sky_predator` — current story-facing hazard is **Loose Cargo Sweep**;
- `corporate_intercept` — current story-facing hazard is **Dock Authority Hold**.

Those two remain noncombat Chapter I interactions. Historical Sky-Predator and superseded corporate/syndicate combat semantics are not reintroduced.

## Adapter provenance

`godot/scripts/first_wake_current_enemy_adapter.gd` preserves the current live Wind Shear metadata from the authoritative packaged runtime:

- name / goal;
- HP and max HP = 14;
- current weakness copy;
- status / type / ability / ability description / body shape;
- legacy primary stats as provenance.

Production defense/evasion are not hand-authored constants. Legacy primaries are normalized through `jrpg_stat_model.gd`, and the existing approved production derived-stat formulas provide `aetherDefense` and `evasion`.

The adapter is fail-closed: unsupported hazards and tampered adapter provenance are rejected.

## Chapter I semantics

The native scene now enforces:

1. Wind Shear interaction during Crossing opens the authored encounter.
2. Staff Strike / Uncover Truth / Hold / Rest use the existing production-formula controller.
3. Starting or acting in combat does not mutate Chapter I progression.
4. Saving/loading during unresolved combat closes the transient encounter and does not award hazard progress.
5. Cancel/close before target clear does not award progress.
6. Clearing the target alone does not award progress.
7. Clearing and then confirming close marks only `wind_shear` complete.
8. Loose Cargo Sweep and Dock Authority Hold retain their existing direct noncombat completion path.
9. All three completed hazards still advance Crossing → Contact normally.

The separate `C` Formula Review fixture remains explicitly noncanonical.

## First local verification attempt — preserved failure

At earlier branch head `bae7236a1bf2d87a88afb70d61e0942c12a74417`, the Windows Godot 4.7.2 verification exposed a real parse failure:

`Parse Error: Cannot infer the type of "hazard_cleared" variable`

in `first_wake_chapter1_review.gd`.

Downstream real-scene, save-scene, export, and renderer checks therefore failed to load the scene script. This failure was preserved rather than reclassified.

Small repair:
- `hazard_id` made explicitly `String`;
- `hazard_cleared` made explicitly `bool`.

Repair commit / exact verified code head:
`93703ce1443a517449d5884b4390452613e1a0f9`.

## Exact-head direct Godot verification — PASS

Authorized Windows host, Godot `4.7.2.stable.official.ed1daf0bf`.

The following exact-head direct invocations exited successfully:

- current-story enemy adapter contract — PASS;
- production Formula Review encounter controller regression — PASS;
- authored Wind Shear real-scene combat contract — PASS;
- durable local save/load real-scene regression — PASS;
- full native Chapter I scene contract — PASS;
- native Windows export surface contract — PASS;
- real OpenGL 3.3 Chapter I renderer/capture script — PASS.

Consolidated marker:
`AETHERWAKE_WIND_SHEAR_CONSOLIDATED_PASS`.

The renderer path includes the new authored Wind Shear combat state in addition to the prior Chapter I review states. Renderer execution completed successfully. Exact PNG custody/hashes were not separately recovered before the Remote Desktop execution quota was exhausted; do not represent those images as independently delivered evidence.

## Package/export gates wired

The source branch now requires the two new contracts in:

- `scripts/build-godot-chapter1-windows-preview.ps1`;
- `.github/workflows/godot-first-wake-pilot.yml`.

The renderer capture now includes authored Wind Shear combat.

The package README and static package contract distinguish:

- Wind Shear = current-story Crossing combat;
- Loose Cargo Sweep / Dock Authority Hold = noncombat hazards;
- `C` = separate noncanonical Formula Review;
- F5/F9 = durable Chapter I save/load;
- active dialogue / Formula Review / Wind Shear combat = transient;
- load cannot award an unconfirmed Wind Shear hazard.

## Hosted GitHub Actions boundary — NOT ESTABLISHED

Exact-head PR runs:

- `39867615662` — Godot Native Ionia Render Review, job `120133669848`;
- `39867615641` — Godot Native First Wake Pilot, job `120133669546`;
- `39867615644` — Aetherwake smoke, job `120133669404`.

All three jobs report failure with **`steps: null`**.

Therefore hosted execution did not establish a source, combat, renderer, package, or smoke result. These red statuses are not treated as implementation failures and do not replace the exact local Godot PASS evidence.

## Exact Windows package gate — NOT ESTABLISHED

A full #345 Windows build/package/Defender/install/uninstall run was started from exact source `93703ce...`.

The first wrapper attempt stopped during nested PowerShell invocation with:
`Godot import failed with exit code`
without a numeric Godot exit code. This occurred because the wrapper treated Godot console/stderr-style output as a terminating native-command error. The same exact code head had already passed direct Godot import/contracts/renderer.

Before the exporter could be rerun directly, the authorized Remote Desktop Commander account reached its monthly execution limit and explicitly paused further tool calls.

Consequently, for PR #345 there is currently **no newly verified EXE or ZIP**, no exact #345 Defender scan, and no exact #345 install/live-launch/uninstall receipt.

Do not promote PR #345 over #344 as the preferred native download until that exact artifact gate is completed.

## Preferred downloadable native build remains #344

PR #344 / native local-save preview remains the current verified native owner build:

- release: https://github.com/ndrorchestration/aetherwake-jrpg/releases/tag/untagged-bc0e58b1e2f961727907
- exact package source: `fe52a2b0d1bc770a5920f9bd48dfb2d5748d9d54`;
- ZIP SHA-256: `8e7fbe33d2eb043f21902ff2dc4be61749f3875131952842cb8e65bee4620478`;
- server-side digest match / uploaded asset / Defender / install / live launch / running-app uninstall: previously established.

## Boundaries

PR #345 remains draft/unmerged.

This is one current-story authored hazard bound to production JRPG formulas, **not combat parity**. Still unresolved:

- exact #345 Windows artifact verification;
- enemy retaliation / turn-pressure behavior;
- party-wide combat;
- durable canonical production-combat state;
- additional current-story combat adapters, if canon/evidence permits;
- final animation/FX/environment;
- creator visual acceptance;
- external-player acceptance;
- hosted verification;
- issue #293 disposition;
- public release authorization.

No merge, public release, creator acceptance, or security-gate relaxation is established by this receipt.
