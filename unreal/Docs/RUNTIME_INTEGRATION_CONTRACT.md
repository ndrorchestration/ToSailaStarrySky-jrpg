# Unreal runtime integration contract (draft)

## First Wake

Use `UTSTSSFirstWakeState` as an ordered gate. For each actual player-driven event (flyer discovery, Ionia hired, boarding, engineering checks, launch, sea contact, confirmed flotation, empty-reserve inspection and return), attempt to advance exactly once. Never advance from a camera transition alone. The C++ state is not yet connected to interactable actors or level scripting.

## Persistence

`UTSTSSSaveGame` is version 1; `UTSTSSPersistence` exposes `SaveProgress`, `LoadProgress` and `IsValidSlotName` to Blueprints. Persist milestone and roster through deliberate assignment. Local slot uses user index 0; no remote/cloud sync, write-atomicity guarantee, migration from Godot, user profile separation, or crash-recovery guarantee is claimed. A corrupt or unsupported loaded payload returns null. Invalid payloads do not initiate writes. Loading must be connected to game-flow UI and tested in a real Unreal runtime before playable acceptance.

## Combat

`UTSTSSCombatRules::TryApplyAction` is a pure transaction across a copied roster. UI and animations must commit `OutRoster` only when true. Reject absent IDs and unaffordable costs. This is an early deterministic approximation rather than the final JRPG damage/balance model.

## Character art

No source images have been imported into Unreal. Creator-approved art remains the only artistic target; avoid substituting generic marketplace models and calling them canonical.

## Acceptance

Native compile, automated test results, save/load round-trip, rendered First Wake footage, visual approval, then Windows packaging. Preserve the existing Godot release while Unreal is unverified.
