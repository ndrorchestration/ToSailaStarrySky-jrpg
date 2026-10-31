# First Wake save preservation — review and acceptance (October 31, 2026)

## Defect and source correction
The earlier Unreal `ATSTSSExplorerCharacter::SaveFirstWake` always constructed a fresh `UTSTSSSaveGame`, copied only story fields, then saved it to the requested slot. An existing compatible save containing `PartyRoster` could therefore be overwritten with an empty roster, losing character stats/progression.

The corrected method validates slot names and distinguishes a new slot from an existing one. For an existing slot it loads the versioned, structurally validated payload; if the slot exists but cannot be loaded safely, the save attempt **fails without overwriting it**. For a new slot it creates a fresh payload. `UTSTSSSaveGame::CaptureFirstWake` validates a candidate story snapshot before mutating its story fields, preserving the existing party data. The ordinary persisted save schema remains version 2; no format migration is performed.

A new `TSTSS.Save.FirstWakeCheckpointPreservesParty` C++ automation test verifies story and inspections, roster member health/resource/attack/defense persistence in memory across repeated story updates, and nonmutation for an invalid story input. The test has been authored but **has not run in Unreal**.

## Remaining release gates
- Run exact-head UE 5.8 Win64 Editor + Game target builds and all native automation tests.
- Add a dedicated temporary-slot disk round trip that starts with a nonempty party, saves through the Explorer game path, reloads, verifies party and story, and cleans the slot. Ensure this never writes to a real player's slot.
- Integrate a genuine live party roster into the Explorer/game instance before claiming full party persistence: this fix *preserves* existing saved party data but does not yet capture current in-memory combat state or character equipment.
- Verify update failures, interrupted writes, corrupt slots, version migration policy, save backups and crash safety; `UGameplayStatics::SaveGameToSlot` is **not by itself evidence of crash-atomic storage**.
- Validate save/reload together with the HUD, First Wake physical landing, and Ionia-first story in a native Unreal map.

No main merge, public installer, canon changes or art acceptance. Retain the existing playable Godot reference.
