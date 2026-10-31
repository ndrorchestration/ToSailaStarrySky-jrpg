#include "Misc/AutomationTest.h"
#include "TSTSSWaterLandingGate.h"
#include "TSTSSFirstWakeState.h"

#if WITH_DEV_AUTOMATION_TESTS
IMPLEMENT_SIMPLE_AUTOMATION_TEST(FTSTSSWaterLandingRestoreTest,
    "TSTSS.FirstWake.WaterLandingRestore",
    EAutomationTestFlags::EditorContext | EAutomationTestFlags::EngineFilter)

bool FTSTSSWaterLandingRestoreTest::RunTest(const FString& Parameters)
{
    UTSTSSFirstWakeState* Story = NewObject<UTSTSSFirstWakeState>();
    UTSTSSWaterLandingGate* Gate = NewObject<UTSTSSWaterLandingGate>();
    if (!TestTrue(TEXT("Restore saved SeaContact"), Story->Restore(true, ETSTSSFirstWakeBeat::SeaContact, 0x07))) return false;
    TestFalse(TEXT("First stable sample does not complete"), Gate->Observe(0.1f, true, 0.f, Story));
    TestEqual(TEXT("Still at SeaContact"), Story->GetCurrentBeat(), ETSTSSFirstWakeBeat::SeaContact);
    for (int32 Index=0; Index<9; ++Index) Gate->Observe(0.1f, true, 0.f, Story);
    TestFalse(TEXT("Loss of overlap resets stability"), Gate->Observe(0.1f, false, 0.f, Story));
    TestEqual(TEXT("No premature flotation"), Story->GetCurrentBeat(), ETSTSSFirstWakeBeat::SeaContact);
    for (int32 Index=0; Index<21; ++Index) Gate->Observe(0.1f, true, 0.f, Story);
    TestEqual(TEXT("Restored contact can eventually confirm flotation"),
        Story->GetCurrentBeat(), ETSTSSFirstWakeBeat::FlotationConfirmed);
    return true;
}
#endif
