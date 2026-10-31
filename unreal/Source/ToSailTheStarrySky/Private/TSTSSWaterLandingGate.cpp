#include "TSTSSWaterLandingGate.h"

bool UTSTSSWaterLandingGate::Observe(float DeltaSeconds, bool bHullTouchesWater,
    float HullVerticalSpeedCms, UTSTSSFirstWakeState* Story)
{
    if (!IsValid(Story) || !FMath::IsFinite(DeltaSeconds) ||
        !FMath::IsFinite(HullVerticalSpeedCms) || DeltaSeconds <= 0.f ||
        DeltaSeconds > 0.25f)
    {
        Reset(); // Invalid samples cannot preserve stable-contact evidence.
        return false;
    }
    if (Story->GetCurrentBeat() != ETSTSSFirstWakeBeat::Launched &&
        Story->GetCurrentBeat() != ETSTSSFirstWakeBeat::SeaContact)
    {
        Reset();
        return false;
    }
    if (!bHullTouchesWater)
    {
        StableContactSeconds = 0.f;
        return false;
    }
    // A restored save may already have recorded SeaContact. Reacquire contact
    // without replaying a milestone; never skip ahead from another story beat.
    if (!bContactRecorded)
    {
        if (Story->HasStarted() &&
            Story->GetCurrentBeat() == ETSTSSFirstWakeBeat::SeaContact)
        {
            bContactRecorded = true;
        }
        else
        {
            if (!Story->AdvanceTo(ETSTSSFirstWakeBeat::SeaContact)) return false;
            bContactRecorded = true;
        }
    }
    if (FMath::Abs(HullVerticalSpeedCms) > 25.f)
    {
        StableContactSeconds = 0.f;
        return false;
    }
    StableContactSeconds += DeltaSeconds;
    if (StableContactSeconds < 2.f) return false;
    if (Story->AdvanceTo(ETSTSSFirstWakeBeat::FlotationConfirmed))
    {
        return true;
    }
    return false;
}
