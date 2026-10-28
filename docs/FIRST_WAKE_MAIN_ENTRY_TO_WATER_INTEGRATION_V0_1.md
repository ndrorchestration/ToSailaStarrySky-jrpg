# First Wake — native main-entry to physical splashdown integration (review v0.1)

**DRAFT / unmerged.** This is an integration of the existing creator-approved revised employment opening and preflight, the [verified local 2D water-contact study #447](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/447), and the [verified main-entry / interactive repair chain #533](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/533). It is **not** a new ocean/flight world model or a full playable Chapter I.

## New physically connected route

From the **actual configured original Chapter I main_scene** the player can use F8 to visit the revised opening without overwriting legacy v1 progress. Ender discovers Ionia's flyer, accepts paid work after interviewing her, boards the Aureate Wake, inspects phase reference, containment and fuel, and completes the captain's safety checklist. **Only after** the preflight contract is met, press the newly remappable **F** action to enter an embedded standalone ship-flight review.

The previously tested flight candidate uses a genuine Godot 4.7.2 **RigidBody2D** hull and **Area2D.body_entered** ocean sensor, not a pure transition flag. After a brief ascent, authored phase drift/containment stress/limited fuel prompts E to initiate a controlled water descent. Actual local water contact and sustained bounded buoyancy/settlement must occur before the shared revised story contract changes to `waterborne`. The UI retains **Ender + Ionia** only; Lyra and her son Talen are **not** shown or recruited on the unsafe first flight. This is an **isolated 2D geometry and flotation proof**; its report explicitly says `production_ocean_verified=false`.

## Saves, character abilities and history remain protected

- Godot startup `run/main_scene` remains the legacy review scene and original v1 data path/schema remain unchanged.
- Press F8 to enter/leave the revised opt-in route; legacy v1 progression and physical player position return exactly from **volatile SceneTree memory**, not from converting the revised v2 slot.
- K/L still operate the **independent v2 checkpoint** in dock/engineering/preflight. **Once physical flight begins, all v2 export, restore, and disk-load operations refuse** until a future explicitly versioned save format covers flight and water evidence. E no longer risks advancing the parent room while embedded ship flight owns E.
- No combat authorization, plot-energy spell, Ender–Lyra Resonance unlock, Lyra party join or production flight right is granted.

## Native acceptance requirements

1. Existing `first_wake_flight_water_review_test.gd` from #447 tests no early launch, real area contact and sustained water flotation, no premature Lyra and no invented fuel properties.
2. New `first_wake_main_entry_to_water_review_test.gd` begins from the configured main scene; sends real F8/F events, completes flyer/hire dialogue, gangway and three engineering inspections, verifies preflight v2 snapshot, verifies forbidden midflight save/restore, confirms physics water contact and buoyancy, and checks complete original v1 state restoration and unchanged v1/v2 slot hashes after returning with F8.
3. Existing native Godot 4.7.2 workflow now runs both physics tests with explicit script-error and PASS receipt checks, plus original Chapter I v1 save/restore, revised v2 checkpoint, interactive music chart #533, Resonance authorization and smoke/renderer regressions. Exact-head PASS is mandatory; historical #447 result does not certify combined source.

**Remaining gap** (not claimed by this PR): an actual post-water recovery and Lyra/Talen reunion playable scene, tangible in-world fuel salvage inventory/custody, linked melody repair scene, approved unique shanty audio, verified core instruments, full planetary ocean, actual seaworthiness, accessibility playtests, save schema for later stages, Windows Defender custody and creator acceptance. The physical water proof is an important testable bridge, not a completed production vertical slice.

## Implementation source and review evidence

- Reuses exact [physics source and design receipt #447](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/447) rather than reimplementing ship physics.
- Stacks on revised Chapter I route [#533](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/533) and safeguards the older scene/save.
- Creator-directed short first-flight/ocean sequence, postflight Lyra recruitment and later materials/Denith shanty solution remain intact.
