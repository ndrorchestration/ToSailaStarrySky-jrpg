# Unreal First Wake — non-destructive disk checkpoint regression

**Status:** Test authored on draft branch, **not executed in Unreal Engine 5.8**.

The new `TSTSS.Save.DiskRoundTripPreservesPartyOnStoryUpdate` automation scenario exercises the existing `UTSTSSPersistence` and `UTSTSSSaveGame::CaptureFirstWake` path:

1. Generate a unique `tstss_qa_<GUID>` save slot and refuse the test if it already exists.
2. Write a valid first-phase story checkpoint containing Ender's nondefault HP, resource, attack and defense values.
3. Load the saved payload from disk.
4. Apply an updated engineering-checked First Wake snapshot to the **loaded** payload, retaining its roster.
5. Save back to the same temporary slot, reload from disk, verify schema, inspection mask, story beat and all recorded Ender stats.
6. Delete only the test-created temporary slot and assert cleanup.

This complements the existing `TSTSS.Save.FirstWakeCheckpointPreservesParty` in-memory test and the separate `TSTSS.Save.RoundTripFirstWakeAndParty` single-write test. It intentionally uses the existing persistence service rather than introducing a second save implementation.

## Limitations / review gates

- This checks save service and payload behavior; it does **not** spawn an `ATSTSSExplorerCharacter` in a world or exercise `SaveFirstWake` from an actual player input.
- It does not capture a live party, guarantee crash-atomic disk writes, restore equipment, or validate migration from legacy Godot saves.
- A process crash could leave the per-run temporary slot. Its GUID avoids a naming collision with player slots, but QA should periodically inspect orphaned `tstss_qa_` slots before deleting anything.
- Run against the pinned, clean UE 5.8 Win64 branch and retain compiler log, exact test identity in `AutomationReport/index.json`, stdout and exact Git SHA.
- Build a true gameplay save/resume scenario after native Editor execution and before calling Chapter I beta-ready.

No story, Five Lights, character appearance, engine asset or release behavior changed. Keep draft/unmerged pending native test proof.
