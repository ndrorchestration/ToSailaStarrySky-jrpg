#include "TSTSSFirstWakeState.h"

bool UTSTSSFirstWakeState::AdvanceTo(const ETSTSSFirstWakeBeat RequestedBeat)
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
    CurrentBeat = RequestedBeat;
    return true;
}

void UTSTSSFirstWakeState::Reset()
{
    bStarted = false;
    CurrentBeat = ETSTSSFirstWakeBeat::FlyerDiscovered;
}
