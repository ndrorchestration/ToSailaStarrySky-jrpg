#include "TSTSSExplorerCharacter.h"
#include "TSTSSSaveGame.h"

bool ATSTSSExplorerCharacter::InitializeFirstWakeStartingParty(
    const FTSTSSCombatant& StartingEnder)
{
    if (!IsValid(FirstWakeState) || FirstWakeState->HasStarted() ||
        bHasLivePartyRoster ||
        !UTSTSSSaveGame::IsValidFirstWakeStartingEnder(StartingEnder))
    {
        return false;
    }
    return SetLivePartyRoster({StartingEnder});
}
