# Unreal combat-to-checkpoint integration proof — 2026-10-31

## Scope
A new editor automation scenario, `TSTSS.Integration.CombatThenCheckpointThenReload`, exercises the **existing** conventional combat resolver, validated party bridge, First Wake state snapshot and persistence service as one contiguous source-level integration path.

Fixture: explicitly initialized Ender and Ionia test combatants (stat values are **synthetic**, not final combat balancing). Ender heals Ionia using a resource-costing action; rejected unaffordable actions must leave results unchanged. The accepted post-combat roster and an inspected First Wake boarding checkpoint are captured into the current versioned save, written to a unique test-owned `tstss_qa_<GUID>` disk slot, reloaded and compared for identity, resource, health, story beat, mask and schema version. The generated slot is deleted afterward; an existing slot collision fails without overwriting player data.

## Professional production gates
- **Authored, not run:** A full UE 5.8 Win64 compile and native automation execution are still required. Test source readback alone does not establish PASS.
- **Not a playable encounter:** No battle HUD, active-formation limit, enemy AI, world-spawned Explorer invocation, cinematic effects or combat animation is involved.
- **Not full persistence assurance:** Does not validate equipment/inventory, story scene rehydration, crashes or interrupted writes. Disk file may remain on process crash; the generated GUID minimizes collision with player slots.
- **Real First Wake acceptance:** Need native map from flyer/Ionia hiring through engineering, flight, physics-driven sea contact, safe flotation and berth return; screenshot/video and hardware profiling are separate gates.
- Keep the established Five Lights as narrative plot affinities, three-active conventional JRPG target and Ionia-first party order unchanged. Maintain protected main and Godot playable reference; no release is authorized.

The next work should focus on obtaining actual native build/automation logs rather than multiplying unverified standalone prototype systems.
