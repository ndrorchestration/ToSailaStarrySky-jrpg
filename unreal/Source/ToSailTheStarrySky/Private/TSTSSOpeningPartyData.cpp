#include "TSTSSOpeningPartyData.h"
#include "TSTSSSaveGame.h"

bool UTSTSSOpeningPartyData::IsReady() const
{
    return bReviewedForPrototype &&
        UTSTSSSaveGame::IsValidFirstWakeStartingEnder(StartingEnder);
}
