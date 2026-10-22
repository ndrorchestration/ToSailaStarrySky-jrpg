# Godot First Wake Chapter I migration — Windows local verification
**Date:** 2026-10-22  
**Exact exercised code/render head:** `fa2670e59651bafe187ccf5f7f3e1d648a2e6408`  
**Draft PR:** #337  
**Base review stack:** PR #330 / `design/aetherwake-jrpg-excellence-vertical-slice-20261021`  
**Scope:** operator-local native migration and renderer evidence only.

## Native Chapter I state contract
The packaged Chapter I progression now has a dedicated deterministic GDScript state contract:

`res://scripts/first_wake_chapter1_state.gd`

It models:
- Signal
- Crossing
- Contact
- Choice
- Wake
- Done

with the packaged denominators:
- **3** signal hooks: `harmonic_buoy`, `sky_lane_warning`, `below_frequency`
- **3** crossing hazards: `sky_predator`, `wind_shear`, `corporate_intercept`
- **4** contacts: Ionia, Wakeheart, Lyra, Verrick
- **3** choice paths: `path_a`, `path_b`, `path_c`
- explicit Ionia join boundary before Choice
- explicit Wake → Done completion with `chapter_one_complete=true`

Signal-phase meetings with Lyra, Wakeheart and Verrick carry forward as contact evidence, matching the currently packaged Chapter I flow rather than requiring duplicate conversations.

Outcome randomness is intentionally not embedded in the state model. The resolved `10+` / `7-9` variant is injected so the migration FSM remains deterministic and testable; canonical outcome/epilogue resolution remains a separate migration responsibility.

## Real native review scene
A dedicated migration scene now exercises the same progression physically on the existing Godot dock:

- `res://scenes/first_wake_chapter1_review.tscn`
- `res://scripts/first_wake_chapter1_review.gd`
- `res://scripts/first_wake_chapter1_input_policy.gd`

The scene:
- reuses the existing reversible 2.5D dock stage;
- gives Ender real movement within the existing dock bounds;
- presents three named Signal targets for Wakeheart, Lyra and Verrick;
- presents three named Crossing hazards: Cargo Sweep, Wind Shear and Dock Hold;
- carries the three Signal contacts into Contact;
- uses Ionia as the fourth contact and decision-boundary join;
- exposes all three storm choices with binding-aware keyboard/controller actions;
- returns to a Wake resolution boundary;
- reaches an explicit Chapter I Complete screen;
- keeps unapproved Ionia art disabled by default;
- does not infer canonical epilogues or production saves.

## Godot 4.7.2 logic verification — PASS
Authorized host: `neontic`  
Godot: `4.7.2.stable.official.ed1daf0bf`

State contract:

`AETHERWAKE_GODOT_CHAPTER1_FSM_PASS: 3 signals, 3 hazards, 4 contacts, Ionia join, 3 paths, Wake and explicit completion`

Real-scene contract:

`AETHERWAKE_GODOT_CHAPTER1_SCENE_PASS: real dock scene traverses Signal, Crossing, Contact, 3-path Choice, Wake and Done`

The state/scene tests additionally verify:
- hazards cannot complete before Crossing;
- choice cannot occur before the decision boundary;
- Wake cannot complete before a choice;
- duplicate contacts do not increment;
- all three hazards are required;
- Signal-phase contacts carry forward;
- Ionia joins exactly at the four-contact Choice boundary;
- active-party target advances from Ender + Lyra to Ender + Lyra + Ionia;
- movement pauses during Choice;
- path selection is exclusive;
- all three path IDs are accepted by the state layer;
- Done preserves explicit Chapter I completion.

## Native 960×640 renderer — PASS
Windows OpenGL 3.3 Compatibility renderer:
Intel Iris Xe Graphics.

Command:

`Godot_v4.7.2-stable_win64.exe --path godot --rendering-driver opengl3 --resolution 960x640 --script res://tests/capture_first_wake_chapter1_review.gd`

Six distinct real-native frames were captured:

| Stage | SHA-256 |
| --- | --- |
| Signal | `0c22ccfce34fff8b7a9724d47bdc5b7e89584bcee0b6d2282d0255161c4fb4a0` |
| Crossing | `9ce9066d77765ca7be9eb1a25674ecb90160b7c896d38fa30876a9f640828970` |
| Contact | `71c19fdd6cad20693fa527a4efae41f3ca4961bba030c67503b2f07d50f2544d` |
| Choice | `28770e2f7ade163912f208989a49df5e0e4e285384e268ba5e9485bdf5e1888e` |
| Wake | `c58a49f61d461c2eba225de48791be68ecbad56411d47cce88d3a9f2599b3f11` |
| Done | `ff18773a258a4b6f77705ed95b53b9cc82e4473bb0c83279196399016d73325b` |

Renderer assertion:

`AETHERWAKE_GODOT_CHAPTER1_NATIVE_RENDER_PASS: Signal, Crossing, Contact, Choice, Wake and Done are visibly distinct 960x640 native frames`

Direct visual review found and repaired an initial UI-overlap problem before this final capture. The accepted migration-review frames have:
- non-overlapping title/objective/party hierarchy;
- named Signal and hazard targets;
- clear three-choice panel;
- explicit active-party change to Ender + Lyra + Ionia;
- explicit Chapter I completion panel.

## Visual limitations
This is usable native migration evidence, **not artistic acceptance**.

Still visibly provisional:
- Wakeheart, Lyra and Verrick use generic migration placeholders;
- Ionia remains review-only and unapproved art stays hidden by default;
- no final party sprites, animation set, production environment pass or cinematic framing is established;
- no canonical epilogue presentation is migrated yet.

## CI wiring
`.github/workflows/godot-first-wake-pilot.yml` now calls:
- `first_wake_chapter1_state_test.gd`
- `first_wake_chapter1_review_test.gd`

Existing hosted execution/billing boundaries inherited from PR #330 remain fail-closed until GitHub actually starts the jobs.

## Boundaries
This is a meaningful native migration advance, not completed production migration. It does not yet bind the full packaged Chapter I dialogue corpus, encounter formulas, canonical epilogue resolver, save system, production party system, final art, or Windows installer to Godot. No merge, creator visual acceptance, external player acceptance, public release, or issue #293 disposition is established.
