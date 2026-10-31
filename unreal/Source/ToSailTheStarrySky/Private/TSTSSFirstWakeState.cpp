#include "TSTSSFirstWakeState.h"

bool UTSTSSFirstWakeState::AdvanceTo(const ETSTSSFirstWakeBeat RequestedBeat)
{
    const uint8 Requested = static_cast<uint8>(RequestedBeat);
    const uint8 Current = static_cast<uint8>(CurrentBeat);
    const uint8 Last = static_cast<uint8>(ETSTSSFirstWakeBeat::ReturnedToBerth);

    if (RequestedBeat == ETSTSSFirstWakeBeat::SeaContact ||
        RequestedBeat == ETSTSSFirstWakeBeat::FlotationConfirmed) return false;
    if (Requested > Last)
    {
        return false;
    }
    if (!bStarted)
    {
        if (RequestedBeat != ETSTSSFirstWakeBeat::FlyerDiscovered)
        {
            return false;
        }
        bStarted = true;
        return true;
    }
    if (Current >= Last || Requested != Current + 1)
    {
        return false;
    }
    if (RequestedBeat == ETSTSSFirstWakeBeat::EngineeringChecked && !AreInspectionsComplete())
    {
        return false;
    }
    CurrentBeat = RequestedBeat;
    return true;
}

bool UTSTSSFirstWakeState::AdvanceWaterBeat(ETSTSSFirstWakeBeat RequestedBeat)
{
    if (!bStarted) return false;
    if (RequestedBeat == ETSTSSFirstWakeBeat::SeaContact &&
        CurrentBeat == ETSTSSFirstWakeBeat::Launched)
    {
        CurrentBeat = RequestedBeat;
        return true;
    }
    if (RequestedBeat == ETSTSSFirstWakeBeat::FlotationConfirmed &&
        CurrentBeat == ETSTSSFirstWakeBeat::SeaContact)
    {
        CurrentBeat = RequestedBeat;
        return true;
    }
    return false;
}

bool UTSTSSFirstWakeState::InspectStation(ETSTSSInspectionStation Station)
{
    if (!bStarted || CurrentBeat != ETSTSSFirstWakeBeat::BoardedAureateWake)
    {
        return false;
    }
    const uint8 Index = static_cast<uint8>(Station);
    if (Index > 2) return false;
    const uint8 Bit = static_cast<uint8>(1u << Index);
    if ((InspectionMask & Bit) != 0) return false;
    InspectionMask |= Bit;
    return true;
}

void UTSTSSFirstWakeState::Reset()
{
    bStarted = false;
    CurrentBeat = ETSTSSFirstWakeBeat::FlyerDiscovered;
    InspectionMask = 0;
}

bool UTSTSSFirstWakeState::Restore(bool bWasStarted, ETSTSSFirstWakeBeat SavedBeat, uint8 SavedInspectionMask)
{
    if (static_cast<uint8>(SavedBeat) > static_cast<uint8>(ETSTSSFirstWakeBeat::ReturnedToBerth) ||
        (SavedInspectionMask & ~0x07u) != 0 ||
        (!bWasStarted && (SavedBeat != ETSTSSFirstWakeBeat::FlyerDiscovered || SavedInspectionMask != 0)) ||
        (SavedInspectionMask != 0 && static_cast<uint8>(SavedBeat) < static_cast<uint8>(ETSTSSFirstWakeBeat::BoardedAureateWake)) ||
        (static_cast<uint8>(SavedBeat) >= static_cast<uint8>(ETSTSSFirstWakeBeat::EngineeringChecked) && SavedInspectionMask != 0x07))
    {
        return false;
    }
    bStarted = bWasStarted;
    CurrentBeat = SavedBeat;
    InspectionMask = SavedInspectionMask;
    return true;
}
