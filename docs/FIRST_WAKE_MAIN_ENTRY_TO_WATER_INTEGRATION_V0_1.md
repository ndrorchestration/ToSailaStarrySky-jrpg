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


## Immediate physical-afloat reserve investigation (review-only addition)

After the measured local `RigidBody2D`/water `Area2D` float settles and the opening contract reaches `waterborne`, the pilot now tells the player to press **E** to examine the emergency reserve. This action is **not** automatic on touch-down. The core review refuses the action until `contact_observed=true`, `stable_float_verified=true`, story state `waterborne`, and **Ender + Ionia** alone; then it calls the previously established creator-directed `inspect_postflight_reserve(true)` story event and changes to `postflight_diagnosis`. The crew sees the concrete problem as an empty reserve, not an instant recipe for fuel or phase alignment.

`reserve_inspection_observed` is an **authored, player-triggered story inspection**. `real_inventory_scan_verified=false` remains explicit; it does not certify a physical fuel-meter simulation or approved salvage item. A repeated interaction must fail; the safe family reunion is still **not** triggered automatically while adrift. This preserves Lyra's family introduction and Talen's noncombat safety for a later playable and geography-approved scene.

The standalone local physics regression and the configured main-entry F8 -> Ionia hiring -> preflight -> F flight -> water contact -> **E reserve diagnosis** -> F8 return tests now both assert this boundary. The v2 preflight-only checkpoint, main_scene and legacy v1 data remain unchanged.


## Stacked afloat reserve-station review — successor draft to #545

**Proposed integration only — do not attribute this work to exact-head #545**. This successor branch starts from #545 commit `742d1329f0072e75ea884f4b3679063b9dae4c70`. It changes only the postflotation inspection UI: E while stably waterborne opens a **new onboard, physically navigable review room**. Ender uses ordinary movement controls to reach a reserve station, then E at the station to invoke the same `Opening.inspect_postflight_reserve(true)` contract. Proximity is checked using Ender's current local scene position; remote/duplicate inspection is refused.

The room shows only Ender and Ionia and does not transition into a shoreline, family reunion, physical salvage, planetary travel, fuel chemistry or approved cinematic asset pipeline. Existing `postflight_diagnosis` remains the sole progression authority. The parent flight stage retains its measured 2D contact and stability flags, and the existing F8 return still restores original v1 from memory. The independent preflight-only v2 save and K/L refusal during flight remain unchanged.

**Tests required before claiming verified:** the two existing exact-head Godot 4.7.2 native tests must now additionally walk the Ender actor in the new scene, refuse early and distant station interactions, prove shared opening identity, require near-station E, reject repeat interactions, assert no inventory or salvage verification, and check the unchanged original save-slot hashes and return state. Passing #545 alone **does not** certify this successor commit. No CI, render, Windows security, creator visual acceptance, or release status is inherited from #545.


## Stacked post-diagnosis recovery observation objective — successor to #592

**DRAFT / review-only / no plot promotion.** This change branches from verified #592 head `9f8e058ccb87d307ecfcb9ee9ae34969b3bf7cdc`. Existing explicit physical reserve inspection remains mandatory. Only after that diagnosis, Ender can walk across the same onboard review deck and inspect a separate **RECOVERY LOG** station using E. The log records only observations already supported by the local native scene: `local_contact`, `local_float`, and `empty_reserve`.

The physics controller independently refuses this action unless measured Area2D contact, sustained local flotation, explicit reserve diagnosis, matching `postflight_diagnosis` contract state, and an Ender/Ionia-only crew are all present. The deck requires physical proximity, refuses remote inspection, and refuses duplicate commits. Its locally held `recovery_brief_recorded` does **not** advance the shared opening contract beyond `postflight_diagnosis`.

**Explicit unknowns remain:** real shoreline geography, safe Lyra/Talen reunion, recovery route/deployment authorization, salvage inventory custody, fuel formula, real-world/planetary seaworthiness. The observation log is neither a recovery plan accepted by the Captain nor proof that recovery can begin. It is an evidence-only staging objective suitable for future approved plot/geography integration.

**Native acceptance:** both physical flight and configured-main-entry Godot 4.7.2 tests must prove early and remote rejection, real Ender traversal between reserve and log stations, proximity-activated observation recording, exact known-fact IDs, no new crew/abilities/route/salvage permission, no duplicate recording, unchanged v1 and preflight-only v2 file hashes, and exact F8 original v1 return. This successor's exact-head CI is required; historical #545 and #592 successes do not prove it. Visual, Windows Defender-on custody, signing, player acceptance, and installer distribution are separate gates.
