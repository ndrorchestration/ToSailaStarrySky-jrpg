# Godot First Wake Chapter I migration FSM — Windows local verification
**Date:** 2026-10-22  
**Exact exercised head:** `d885dc44c4c903dae25c4c68699872281ea16414`  
**Base review stack:** PR #330 / `design/aetherwake-jrpg-excellence-vertical-slice-20261021`  
**Scope:** operator-local native migration evidence only.

## What is now represented natively
The packaged Chapter I progression now has a dedicated GDScript state contract:

`res://scripts/first_wake_chapter1_state.gd`

It models:
- Signal
- Crossing
- Contact
- Choice
- Wake
- Done

with the current packaged denominators:
- **3** signal hooks: `harmonic_buoy`, `sky_lane_warning`, `below_frequency`
- **3** crossing hazards: `sky_predator`, `wind_shear`, `corporate_intercept`
- **4** contacts: Ionia, Wakeheart, Lyra, Verrick
- **3** choice paths: `path_a`, `path_b`, `path_c`
- explicit Ionia join boundary before Choice
- explicit Wake → Done completion with `chapter_one_complete=true`

Signal-phase meetings with Lyra, Wakeheart and Verrick are intentionally carried forward as contact evidence, matching the current packaged Chapter I behavior rather than forcing duplicate conversations after Crossing.

Outcome randomness is **not** embedded in this migration state model. The resolved `10+` / `7-9` variant is supplied to it explicitly so the state layer stays deterministic and testable; encounter/outcome resolution remains a separate responsibility.

## Windows Godot 4.7.2 verification — PASS
Authorized host: `neontic`  
Godot: `4.7.2.stable.official.ed1daf0bf`

Command:

`Godot_v4.7.2-stable_win64.exe --headless --path godot --script res://tests/first_wake_chapter1_state_test.gd`

Result:

`AETHERWAKE_GODOT_CHAPTER1_FSM_PASS: 3 signals, 3 hazards, 4 contacts, Ionia join, 3 paths, Wake and explicit completion`

The test additionally verifies:
- hazards cannot complete before Crossing;
- choices cannot occur before the decision boundary;
- Wake cannot complete before a choice;
- duplicate contacts are rejected;
- duplicate/late signal mutation is rejected;
- all three hazards are required;
- pre-met Signal contacts carry into Contact;
- Ionia joins exactly when all four contacts are satisfied at the Choice boundary;
- active-party target advances from Ender + Lyra to Ender + Lyra + Ionia;
- choices are exclusive/immutable;
- all three path IDs are accepted;
- explicit Done state preserves path/variant identity.

## CI wiring
`.github/workflows/godot-first-wake-pilot.yml` now includes the same headless Godot contract. Existing hosted execution/billing boundaries from PR #330 remain unchanged until GitHub actually starts the job.

## Boundaries
This is an **isolated native migration contract**, not a claim that Chapter I has fully migrated to Godot. It does not yet bind the full packaged Chapter I scene, dialogues, hazards, contacts, epilogues, save state, presentation, or Windows installer to Godot. No canon, creator visual acceptance, merge, public release, or issue #293 disposition is established.
