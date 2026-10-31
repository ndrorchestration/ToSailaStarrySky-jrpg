#include "TSTSSWaterLandingGate.h"

// Retained only for compatibility with earlier prototype references.
// This public Blueprint-callable API accepted caller-supplied contact flags,
// allowing fabricated water evidence. The trusted water observer now owns
// the transition and this unsafe legacy path deliberately fails closed.
bool UTSTSSWaterLandingGate::Observe(float DeltaSeconds, bool bHullTouchesWater,
    float HullVerticalSpeedCms, UTSTSSFirstWakeState* Story)
{
    Reset();
    return false;
}
