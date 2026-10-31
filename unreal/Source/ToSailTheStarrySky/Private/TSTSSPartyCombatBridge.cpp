#include "TSTSSPartyCombatBridge.h"
#include "TSTSSSaveGame.h"

bool UTSTSSPartyCombatBridge::TryApplyValidatedAction(
    const TArray<FTSTSSCombatant>& Current, const FTSTSSCombatAction& Action,
    TArray<FTSTSSCombatant>& OutNext)
{
    // The existing resolver is authoritative for resource cost, damage,
    // healing and action authorization. This bridge only validates and commits.
    TArray<FTSTSSCombatant> Candidate;
    if (!UTSTSSCombatRules::TryApplyAction(Current, Action, Candidate))
    {
        return false;
    }
    UTSTSSSaveGame* Probe = NewObject<UTSTSSSaveGame>();
    if (!IsValid(Probe) || !Probe->CapturePartyRoster(Candidate))
    {
        return false;
    }
    OutNext = MoveTemp(Candidate);
    return true;
}
