#include "Misc/AutomationTest.h"
#include "TSTSSFirstWakeState.h"
#include "TSTSSSaveGame.h"

#if WITH_DEV_AUTOMATION_TESTS
// Imports #614's valuable ordered preflight checks without pretending that
// manual milestones can certify physics-driven sea contact or flotation.
IMPLEMENT_SIMPLE_AUTOMATION_TEST(FTSTSSFirstWakeIntegratedPreflightTest,
    "TSTSS.FirstWake.OrderedPreflightStopsAtPhysics",
    EAutomationTestFlags::EditorContext | EAutomationTestFlags::EngineFilter)
bool FTSTSSFirstWakeIntegratedPreflightTest::RunTest(const FString& Parameters)
{
    UTSTSSFirstWakeState* State = NewObject<UTSTSSFirstWakeState>();
    if (!TestNotNull(TEXT("Story state"), State)) return false;
    TestFalse(TEXT("Cannot hire before flyer"), State->AdvanceTo(ETSTSSFirstWakeBeat::IoniaHired));
    TestTrue(TEXT("Flyer"), State->AdvanceTo(ETSTSSFirstWakeBeat::FlyerDiscovered));
    TestTrue(TEXT("Ionia hired"), State->AdvanceTo(ETSTSSFirstWakeBeat::IoniaHired));
    TestTrue(TEXT("Board"), State->AdvanceTo(ETSTSSFirstWakeBeat::BoardedAureateWake));
    TestFalse(TEXT("Cannot skip inspection"), State->AdvanceTo(ETSTSSFirstWakeBeat::EngineeringChecked));
    TestTrue(TEXT("Lift"), State->InspectStation(ETSTSSInspectionStation::Lift));
    TestTrue(TEXT("Pressure"), State->InspectStation(ETSTSSInspectionStation::Pressure));
    TestTrue(TEXT("Reserve"), State->InspectStation(ETSTSSInspectionStation::Reserve));
    TestFalse(TEXT("Duplicate reserve rejected"), State->InspectStation(ETSTSSInspectionStation::Reserve));
    TestTrue(TEXT("Engineering"), State->AdvanceTo(ETSTSSFirstWakeBeat::EngineeringChecked));
    TestTrue(TEXT("Launch"), State->AdvanceTo(ETSTSSFirstWakeBeat::Launched));
    TestFalse(TEXT("No synthetic contact"), State->AdvanceTo(ETSTSSFirstWakeBeat::SeaContact));
    TestFalse(TEXT("No synthetic flotation"), State->AdvanceTo(ETSTSSFirstWakeBeat::FlotationConfirmed));
    TestFalse(TEXT("No reserve inspection before real landing"), State->AdvanceTo(ETSTSSFirstWakeBeat::EmptyReserveInspected));
    TestEqual(TEXT("Preflight state retains launch"), State->GetCurrentBeat(), ETSTSSFirstWakeBeat::Launched);
    return true;
}

IMPLEMENT_SIMPLE_AUTOMATION_TEST(FTSTSSFirstWakeRestoreGuardTest,
    "TSTSS.FirstWake.RejectedRestorePreservesState",
    EAutomationTestFlags::EditorContext | EAutomationTestFlags::EngineFilter)
bool FTSTSSFirstWakeRestoreGuardTest::RunTest(const FString& Parameters)
{
    UTSTSSFirstWakeState* State = NewObject<UTSTSSFirstWakeState>();
    if (!TestNotNull(TEXT("Story state"), State)) return false;
    TestTrue(TEXT("Restore boarding with partial inspection"), State->Restore(true, ETSTSSFirstWakeBeat::BoardedAureateWake, 1));
    TestFalse(TEXT("Late beat with incomplete inspections invalid"), State->Restore(true, ETSTSSFirstWakeBeat::Launched, 1));
    TestEqual(TEXT("Beat unchanged"), State->GetCurrentBeat(), ETSTSSFirstWakeBeat::BoardedAureateWake);
    TestEqual(TEXT("Mask unchanged"), State->GetInspectionMask(), static_cast<uint8>(1));
    TestFalse(TEXT("Unknown inspection bit rejected"), State->Restore(true, ETSTSSFirstWakeBeat::BoardedAureateWake, 8));
    TestEqual(TEXT("Mask still unchanged"), State->GetInspectionMask(), static_cast<uint8>(1));
    UTSTSSSaveGame* Save = NewObject<UTSTSSSaveGame>();
    if (!TestNotNull(TEXT("Save structure"), Save)) return false;
    Save->bFirstWakeStarted = true;
    Save->FirstWakeBeat = ETSTSSFirstWakeBeat::Launched;
    Save->InspectionMask = 1;
    TestFalse(TEXT("Incomplete inspection save invalid"), Save->IsStructurallyValid());
    Save->InspectionMask = 7;
    TestTrue(TEXT("Complete inspection save valid"), Save->IsStructurallyValid());
    return true;
}
#endif
