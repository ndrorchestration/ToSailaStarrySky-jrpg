#include "TSTSSGameMode.h"
#include "TSTSSExplorerCharacter.h"
#include "TSTSSFirstWakeHUD.h"
#include "TSTSSOpeningPartyData.h"

ATSTSSGameMode::ATSTSSGameMode()
{
    DefaultPawnClass = ATSTSSExplorerCharacter::StaticClass();
    HUDClass = ATSTSSFirstWakeHUD::StaticClass();
}

bool ATSTSSGameMode::TryInitializeNewExplorer(ATSTSSExplorerCharacter* Explorer) const
{
    return IsValid(Explorer) && IsValid(OpeningPartyData) &&
        OpeningPartyData->IsReady() &&
        Explorer->InitializeFirstWakeStartingParty(OpeningPartyData->StartingEnder);
}
