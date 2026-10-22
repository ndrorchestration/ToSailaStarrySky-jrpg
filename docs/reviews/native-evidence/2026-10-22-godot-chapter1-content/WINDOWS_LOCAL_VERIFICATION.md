# Godot First Wake Chapter I authored-content binding — Windows local verification
**Date:** 2026-10-22  
**Exact exercised code/render head:** `d2dca4d74ea3c5cc4f908b02d3d1b8e396c02b67`  
**Stack:** PR #337 native Chapter I FSM/scene migration  
**Scope:** operator-local Godot 4.7.2 migration evidence only.

## What moved into native authority
A dedicated native content layer now mirrors the current packaged First Wake Chapter I player-facing data:

`res://scripts/first_wake_chapter1_content.gd`

It contains:
- exact Signal labels for Wakeheart, Verrick and Lyra;
- exact Crossing hazard labels/stat identities;
- contact names/titles plus selected authored Chapter I lines;
- all three storm-path labels and descriptions;
- all six path/variant outcome strings (`path_a|b|c × 10+|7-9`);
- current six epilogue IDs, names and text;
- packaged-style objective copy;
- an explicit native implementation of the **current legacy first-match epilogue resolver**.

The real native review scene consumes this content authority rather than hard-coded migration placeholders for labels/outcomes/objectives.

## Important legacy resolver finding
Current packaged defaults are:
- hull integrity: **100**
- morale: **50**
- engine integration: **0**

The current packaged runtime does not mutate morale or engine integration through the three storm choices. Because the legacy resolver's second rule is:

`hull >= 60 && morale >= 45 && (engineIntegration < 50 || path_a)`

default `path_c` therefore resolves to **epiline_1 / The Clear Departure**, before the later path-C endings are considered.

This migration intentionally preserves that implementation truth. It does **not** silently repair it.

The native contract separately proves the richer current endings remain reachable when explicit stat inputs satisfy their legacy rules:
- low hull → `epiline_5` / The Weather-Bruised;
- path_b + high engine → `epiline_2` / The Shield-Bound because first-match order preempts the later path-B rule;
- path_b + mid stats → `epiline_3` / Verrick's Weather Ledger;
- path_c + morale 60 / engine 50 → `epiline_4` / Lyra's Wide Wing;
- path_c + engine 60 / morale 50 → `epiline_6` / The First Chord.

A later canon/owner decision can correct the resolver or stat mutation model explicitly. This branch does not make that decision.

## Godot 4.7.2 verification
Authorized Windows host: `neontic`  
Godot: `4.7.2.stable.official.ed1daf0bf`

A fresh checkout initially failed to load review PNG/SVG resources because the imported Godot cache was absent. Running the required headless editor import repaired the environment; no source change was needed for that failure.

PASS tokens at exact exercised head:

`AETHERWAKE_GODOT_CHAPTER1_CONTENT_PASS: packaged labels, authored lines, six choice outcomes, and exact legacy epilogue ordering`

`AETHERWAKE_GODOT_CHAPTER1_FSM_PASS: 3 signals, 3 hazards, 4 contacts, Ionia join, 3 paths, Wake and explicit completion`

`AETHERWAKE_GODOT_CHAPTER1_SCENE_PASS: real dock scene traverses Signal, Crossing, Contact, 3-path Choice, Wake and Done`

`AETHERWAKE_GODOT_CHAPTER1_NATIVE_RENDER_PASS: Signal, Dialogue, Crossing, Contact, Choice, Wake and Done are visibly distinct 960x640 native frames`


## Full native contact-dialogue sequencing
The migration now includes the full packaged five-line intro sequences for:
- Ionia;
- Wakeheart;
- Lyra;
- Verrick.

A dedicated deterministic dialogue cursor:
`res://scripts/first_wake_chapter1_dialogue_state.gd`

keeps dialogue sequencing separate from quest mutation. The real review scene now:
- pauses Ender when a contact dialogue opens;
- shows speaker identity, authored current line, and line index;
- advances with the same named interaction action;
- refuses to credit a Signal/contact before the fifth line closes;
- resumes movement after Signal dialogue;
- remains paused when Ionia's completed dialogue transitions directly into the three-path Choice.

Exact-head PASS tokens:

`AETHERWAKE_GODOT_CHAPTER1_DIALOGUE_PASS: four authored five-line contact intros advance and close deterministically`

`AETHERWAKE_GODOT_CHAPTER1_DIALOGUE_SCENE_PASS: authored five-line Wakeheart/Ionia dialogue gates progress and movement`

Direct inspection of the native dialogue frame confirmed Wakeheart's first packaged line is visible with a readable panel and `line 1 / 5` continuation state.

## Native renderer evidence
Fresh OpenGL 3.3 Compatibility frames:

| Stage | SHA-256 |
| --- | --- |
| Signal | `325b02a4fe995be7d3ad9f46796aaf0a60a8c2cae9721a5f9323466dd7163b29` |
| Dialogue | `11c0b8817f6cd2ef55acdd4cc573d010c100c2516049ebcefaee5512d2c2aec2` |
| Crossing | `1ecfe8b90fc0917de1dff70c8700d6605b7bff034e0a272210024f3a2b25c780` |
| Contact | `3f73517b856d80999872e7dc3473f9f6e7726ac0b6db30d51916b2c6003ab7e0` |
| Choice | `bd5de195a4c0ddf5ff350b8b5cb4477f663e9c2866870db1786ea5f60a17b50f` |
| Wake | `6aa4cba6b9151948d24b7e516d474d901501a12b5f19d8783e3c35b8ba0c41b8` |
| Done | `a037b54ae583f7d3c4b009fcc6f82a5aba4816bf5f10291a38de288c63fcf638` |

Direct inspection confirms:
- Choice displays all three packaged storm-choice labels;
- Wake displays the real packaged path-C `10+` outcome beginning with the bright-wing shelter result;
- Done visibly identifies **The Clear Departure**, exposing the current default-stat legacy resolver behavior;
- active party remains Ender + Lyra + Ionia at the decision/ending boundary.

## CI
The native review workflow now runs the authored-content/legacy-epilogue contract before the real scene contract.

Hosted execution is not established until GitHub actually starts the jobs. Existing no-step hosted failures remain fail-closed and are not upgraded from local evidence.

## Remaining migration gaps
Still not migrated/admitted:
- production combat formulas/encounters;
- save system;
- production party system integration beyond migration target state;
- final character/environment art;
- Windows Godot packaging/install path;
- explicit canon correction, if any, for the legacy epilogue/stat inconsistency.

No merge, creator visual acceptance, external player acceptance, public release, or issue #293 disposition is established.
