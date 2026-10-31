# Unreal 5.8 First Wake — combat results to live party (October 31, 2026)

## Integrated contract
The existing `UTSTSSCombatRules::TryApplyAction` remains the **single authoritative resolver** for attack/heal, cost and roster eligibility. `UTSTSSPartyCombatBridge::TryApplyValidatedAction` validates the resolver output using the existing `UTSTSSSaveGame::CapturePartyRoster` contract and only then publishes a complete candidate roster.

`ATSTSSExplorerCharacter::TryApplyLiveCombatAction` requires a previously initialized live party, invokes the bridge and commits the candidate only after it passes. Failed or unaffordable actions leave all party data unchanged. The existing `SaveFirstWake` persists the resulting live roster; `LoadFirstWake` restores it. No parallel combat calculator or new save format was introduced.

## Source evidence and scope
- Authored C++ bridge header/implementation, Explorer method, and `TSTSS.Combat.LivePartyBridgeTransactions` automation regression covering damage, resources, immutability, unaffordable action and missing target.
- **Not native verified:** UE5.8 compilation, actual automation execution, encounter UI, world-spawned Explorer invocation, save/reload after combat, 3-active formation, audiovisual attack effects, or combat balance.
- Character combat stats in this fixture are synthetic test data, not canon. Five Lights are story affinities, not implicit magic commands.

## Production gates
1. Compile the exact stacked UE 5.8 Win64 Editor + Game targets and run the `TSTSS.*` automation suite with exact-ID receipts.
2. Spawn Explorer with a legitimate initialized party, route a real battle command to `TryApplyLiveCombatAction`, verify resources/damage and rejected actions with in-game controls.
3. Save to a disposable test slot, reload, verify the same character stats and First Wake objective without mutating approved story order.
4. Integrate the 3-active party policy and encounter lifecycle separately. Do not turn a verified pure resolver into a claim that the complete battle system or final cinematic UI is ready.
5. Capture native screenshots and profiling separately for visual approval.

No main merge, public release or canon modification.
