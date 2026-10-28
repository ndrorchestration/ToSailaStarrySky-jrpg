# First Wake — physically witnessed local recovery / safe berth review v0.2
**Status: DRAFT / UNMERGED / LOCAL PHYSICS PROTOTYPE. Exact-head native verification required.**

**Lineage:** [PR #548 — single-story continuity through Denith-song bench candidate](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/548). The preceding chapter still begins Ender alone, Ionia first join, brief flight, controlled ocean splashdown and a witnessed empty reserve before Lyra/Talen can appear.

## Gap being closed

In v0.1, after E to request recovery, another E immediately staged the temporary berth and opened Lyra's scene. The story protected party chronology but the disabled ship **had not physically moved toward safety**. Its scene description was explicit about this gap. This v0.2 makes that transition an interactive in-engine **local movement and mooring proof**, with no invented geographic harbor, named rescue boat or approved source of towing power.

## Player-visible, actually implemented order

1. Original Godot RigidBody2D hull meets water via `Area2D.body_entered` and remains safely afloat for the earlier measured interval. Ender/Ionia only. E is still required to physically examine the empty review reserve.
2. E **requests assisted surface recovery**. The existing afloat physics hull unfreezes and moves horizontally on the same authored 960×640 waterline. It is a bounded, mocked external recovery pull, **not the Wake's repaired levitation engine, a new ship mode or a factual tow method**.
3. A **second independent `Area2D.body_entered` sensor** for a visibly marked provisional berth must be triggered by that **same physical hull**. The movement slows on entry, avoiding a timed reflex challenge. E to **secure lines** is rejected before this measured contact.
4. The game observes continuous sensor overlap and a low true RigidBody2D linear velocity for at least 0.35 simulation seconds before marking `berth_stable_verified`. Sensor proximity alone never admits Lyra's family scene. Early E and forged stage shortcuts fail closed. A missed approach hits a bounded stop instead of silently opening the next scene.
5. Only after `berth_ready` does E open the existing walkable Lyra/Talen family scene. This shares the unchanged `first_wake_revised_opening_contract.gd` object with the original job, flight, independent clues, and later physical parts/Denith melody bench investigation. Talen is noncombat; Lyra joins after actual reunion dialogue.

### Evidence boundary

New exact-state telemetry distinguishes `berth_sensor_contact_observed`, `berth_stable_verified`, `berth_stable_seconds`, and `local_2d_berth_approach_verified` from **`approved_shoreline_or_tow_method=false`** and **`real_recovery_route_verified=false`**. The scene draws a simple provisional quay and marker to make the target legible. It does **not** simulate ocean currents, boat/sail/tow realism, external rescue ownership, journey length, a world map location, shore geography, weather-dependent travel, player-triggered propulsion, marine navigation or consent to a canon location.

The work does not change `godot/project.godot`, the default legacy Chapter I or v1 saves, the preflight-only v2 checkpoint, the creator's Five Lights, Lyra/Talen appearance chronology, any combat Art, fuel chemistry, approved shanty, or flight authorization.

## Native QA contract

Existing engine checks are extended to require physical movement to the separate berth Area2D, refusal of a family shortcut before body contact, refusal of a second shortcut before stable mooring, deliberate E line securing, continuously observed low-speed/overlap hold, and the same player-controlled family/theory/material/melody flow. Exact-head native 4.7.2 and smoke/render CI must be checked, not inferred from older PR #548's green result. If viewport art is not captured, **do not claim visual acceptance**.

## Next real production decisions

The player and creator still need to decide actual sea/shore geography, whether the Wake is moved by sails, wind/current, a friendly tow, or another already-established ship system, and whether the family reunion takes place on a dock, in town, or aboard a safely moored vessel. Do not let this toy assisted movement determine those answers. Later work needs animated character art, ocean shader and wet surfaces, true locations/collectible material custody, the original Denith shanty audio with textual alternatives, persistent postflight saves, user QA and a separate Windows Defender release/security review.
