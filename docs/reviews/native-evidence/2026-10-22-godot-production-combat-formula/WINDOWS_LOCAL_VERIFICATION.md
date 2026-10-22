# Native production JRPG combat authority — Windows verification

**Date:** 2026-10-22  
**Exact exercised code head:** `d0a3a7e3d209021c654a568c32cce0622ccf0def`  
**Base:** native Windows preview branch / PR #341  
**Godot:** `4.7.2.stable.official.ed1daf0bf`  
**Host:** authorized Windows host `neontic`

## Purpose

This increment ports the repository's approved production combat **math/authority layer** into native Godot before any Chapter I hazard is allowed to depend on it.

It deliberately does **not** port the old visible-2D6 / PbtA compatibility resolver.

Target policy preserved:

- turn-based JRPG resolution;
- no player-facing dice;
- no PbtA success/partial/failure outcome bands;
- primary resolution from stats + explicit ability formulas;
- bounded secondary RNG only;
- injected RNG for deterministic testing.

## Native stat model

`godot/scripts/jrpg_stat_model.gd` ports the current `modules/jrpg-stat-model.js` v0.1.0 contract:

- level range 1–175;
- primary-stat hard cap 75;
- Ender/Lyra/Ionia/Reson/Aepex level-one and capstone profiles;
- derived HP/attack/defense/accuracy/evasion/initiative/break/resolve/crit values;
- diminishing defense multiplier;
- 0.95–1.05 damage variance;
- 1.5× critical multiplier;
- bounded hit/status chances;
- deterministic damage, healing and break formulas.

Windows result:

`AETHERWAKE_GODOT_JRPG_STAT_MODEL_PASS: level 175 profiles, derived roles, bounded RNG math and damage/healing parity`

## Native formula subset

`godot/scripts/first_wake_combat_formula.gd` ports only the currently authorized generic `jrpg-stat-formula` actions:

- `staffStrike`
- `uncoverTruth`
- `hold`
- `rest`

Parity includes:

- Staff Strike EMP damage, Might scaling, Aether Defense interaction, bounded variance, 10% crit policy and staff-charge evidence;
- Uncover Truth weakness reveal + 1.15 next-damage analysis modifier;
- Hold restores one staff charge up to maximum;
- Rest reduces up to 2 Heat and restores up to 1 Vitality;
- analyzed Staff Strike consumes the analysis multiplier;
- missing or out-of-range injected RNG fails closed.

Explicit SSOT guard: `sharedDream` and `windWard` are **not** migrated; `mycelialLedger` and `aetherSeal` remain separate non-generic contracts rather than being silently folded into the formula layer.

Windows result:

`AETHERWAKE_GODOT_COMBAT_FORMULA_PASS: Staff Strike, Uncover Truth, Hold, Rest and fail-closed RNG/SSOT guards`

## Regression stack at exact head

PASS on the same checkout:

- headless editor import;
- production JRPG stat model;
- authorized production formula subset;
- Chapter I FSM;
- authored Chapter I content / legacy epilogue ordering;
- four-contact authored dialogue cursor;
- real-scene dialogue gating;
- fail-closed save codec;
- real-scene save/restore and invalid-snapshot rejection;
- full native Chapter I scene Signal → Crossing → Contact → Choice → Wake → Done;
- Windows native preview export surface.

No existing Chapter I migration contract regressed.

## Boundary

This is **formula authority**, not completed combat migration.

Not yet established:

- Chapter I hazards invoking this formula layer;
- native enemy production-stat adapter / migration fixture;
- native turn controller / combat UI using these formulas;
- production combat persistence in the save codec;
- party-wide combat;
- final enemy/party animation;
- creator or external-player combat acceptance;
- a rebuilt Windows preview containing a playable formula-combat encounter.

The current native Windows package from PR #341 remains the downloadable native preview until a later scene-binding candidate passes exact package/security QA. The fuller NW.js package remains a separate rollback/reference.

Hosted GitHub execution remains subject to the existing no-step Actions/account boundary and is not substituted by this operator-local evidence.
