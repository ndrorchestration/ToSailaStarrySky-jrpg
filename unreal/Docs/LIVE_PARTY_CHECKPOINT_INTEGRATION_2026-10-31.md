# Unreal First Wake — live party checkpoint integration (2026-10-31)

## Scope and behavior

Previously, the Explorer saved only story state, preserving existing saved party data but never capturing live combat updates. This draft adds an **explicitly initialized** `LivePartyRoster` on `ATSTSSExplorerCharacter`, exposed to Blueprint via `SetLivePartyRoster`, `GetLivePartyRoster` and `HasLivePartyRoster`.

`SetLivePartyRoster` rejects empty rosters, duplicate character IDs and invalid HP/resource/stat bounds using the same `UTSTSSSaveGame::IsStructurallyValid` contract as the save layer. `SaveFirstWake` continues to refuse unsafe slots and retain valid existing save data; if there is a live party, it uses `CapturePartyRoster` to validate and atomically copy updated stats into that save before writing. If the live party was never explicitly initialized, it does **not** erase an existing saved party. `LoadFirstWake` restores live party data after story validation succeeds. No schema change (still v2).

The `TSTSS.Save.LivePartySnapshotIsValidated` automation fixture covers valid updates and failure without mutation for empty, invalid-health and duplicated-character rosters.

## Boundaries

- **Implemented source:** Blueprint-compatible entry points for combat system to provide a live roster, persistence capture/restore bridge, unit regressions. **No runtime wiring from a combat encounter to `SetLivePartyRoster` yet.**
- **Not yet proven:** Unreal 5.8 UHT/Win64 compile, editor automation execution, player-world spawning, actual disk save/load with active combat, equipment, map/ship positioning, crash atomicity, visual QA.
- Source-of-truth for full party state needs definition before integrating inventory/equipment/three-active formation. Never confuse plot affinity (Five Lights) with automatic combat skills.
- Explicitly retain the first character Ender and Ionia-first canonical story. Current validation checks structural plausibility, not whether a particular roster configuration is canonically joinable.

## Next test
Run exact-commit Windows Unreal build and editor suite; spawn a real Explorer in a native map, call `SetLivePartyRoster` from the actual combat result, save via Explorer, reload via Explorer, and compare party/stats and objective HUD. Add clean save-slot creation/cleanup, corruption and interruption tests. Keep draft/unmerged.
