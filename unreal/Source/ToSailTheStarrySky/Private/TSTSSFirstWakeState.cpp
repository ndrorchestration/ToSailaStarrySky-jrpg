#include "TSTSSFirstWakeState.h"

bool UTSTSSFirstWakeState::AdvanceTo(const ETSTSSFirstWakeBeat RequestedBeat)
{
    if (RequestedBeat == ETSTSSFirstWakeBeat::SeaContact ||
        RequestedBeat == ETSTSSFirstWakeBeat::FlotationConfirmed)
    {
        return false;
    }
    return AdvanceUnchecked(RequestedBeat);
}

bool UTSTSSFirstWakeState::AdvanceFromWaterObservation(const ETSTSSFirstWakeBeat RequestedBeat)
{
    if (RequestedBeat != ETSTSSFirstWakeBeat::SeaContact &&
        RequestedBeat != ETSTSSFirstWakeBeat::FlotationConfirmed)
    {
        return false;
    }
    return AdvanceUnchecked(RequestedBeat);
}

bool UTSTSSFirstWakeState::AdvanceUnchecked(const ETSTSSFirstWakeBeat RequestedBeat)
{
    const uint8 Requested = static_cast<uint8>(RequestedBeat);
    const uint8 Current = static_cast<uint8>(CurrentBeat);
    const uint8 Last = static_cast<uint8>(ETSTSSFirstWakeBeat::ReturnedToBerth);

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

FText UTSTSSFirstWakeState::GetCurrentObjective() const
{
    if (!bStarted)
    {
        return NSLOCTEXT("TSTSSFirstWake", "FindFlyer", "Find the captain's engineering flyer.");
    }

    switch (CurrentBeat)
    {
    case ETSTSSFirstWakeBeat::FlyerDiscovered:
        return NSLOCTEXT("TSTSSFirstWake", "MeetIonia", "Meet Captain Ionia about the levitation engine.");
    case ETSTSSFirstWakeBeat::IoniaHired:
        return NSLOCTEXT("TSTSSFirstWake", "BoardWake", "Board the Aureate Wake.");
    case ETSTSSFirstWakeBeat::BoardedAureateWake:
        if ((InspectionMask & 0x01) == 0)
            return NSLOCTEXT("TSTSSFirstWake", "InspectLift", "Inspect the lift system.");
        if ((InspectionMask & 0x02) == 0)
            return NSLOCTEXT("TSTSSFirstWake", "InspectPressure", "Inspect the pressure system.");
        if ((InspectionMask & 0x04) == 0)
            return NSLOCTEXT("TSTSSFirstWake", "InspectReserve", "Inspect the engine reserve.");
        return NSLOCTEXT("TSTSSFirstWake", "ApproveEngineering", "Complete the engineering checks with Ionia.");
    case ETSTSSFirstWakeBeat::EngineeringChecked:
        return NSLOCTEXT("TSTSSFirstWake", "PrepareLaunch", "Prepare for the Aureate Wake's first launch.");
    case ETSTSSFirstWakeBeat::Launched:
        return NSLOCTEXT("TSTSSFirstWake", "FlightInProgress", "Hold on during the first flight.");
    case ETSTSSFirstWakeBeat::SeaContact:
        return NSLOCTEXT("TSTSSFirstWake", "AwaitFlotation", "Wait for the ship to settle safely on the water.");
    case ETSTSSFirstWakeBeat::FlotationConfirmed:
        return NSLOCTEXT("TSTSSFirstWake", "InspectEmptyReserve", "Inspect the depleted engine reserve.");
    case ETSTSSFirstWakeBeat::EmptyReserveInspected:
        return NSLOCTEXT("TSTSSFirstWake", "ReturnToBerth", "Return to the local berth with Ionia.");
    case ETSTSSFirstWakeBeat::ReturnedToBerth:
        return NSLOCTEXT("TSTSSFirstWake", "FirstWakeComplete", "First Wake complete.");
    default:
        return NSLOCTEXT("TSTSSFirstWake", "UnknownBeat", "Review the current objective.");
    }
}
