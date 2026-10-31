#include "TSTSSWaterLandingGate.h"

bool UTSTSSWaterLandingGate::Observe(float DeltaSeconds, bool bHullTouchesWater,
    float HullVerticalSpeedCms, UTSTSSFirstWakeState* Story)
{
    if (!IsValid(Story) || !FMath::IsFinite(DeltaSeconds) ||
        !FMath::IsFinite(HullVerticalSpeedCms) || DeltaSeconds <= 0.f ||
        DeltaSeconds > 0.25f)
    {
        return false;
    }
    if (!bHullTouchesWater)
    {
        StableContactSeconds = 0.f;
        return false;
    }
    if (!bContactRecorded)
    {
        if (!Story->AdvanceTo(ETSTSSFirstWakeBeat::SeaContact)) return false;
        bContactRecorded = true;
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
