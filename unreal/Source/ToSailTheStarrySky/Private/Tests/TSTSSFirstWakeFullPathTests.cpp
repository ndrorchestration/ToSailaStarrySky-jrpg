#include "Misc/AutomationTest.h"
#include "TSTSSFirstWakeState.h"
#include "TSTSSSaveGame.h"

#if WITH_DEV_AUTOMATION_TESTS
// Source-level parity contract for the Ionia-first First Wake. This does not
// simulate physics: SeaContact still requires a native collision integration test.
IMPLEMENT_SIMPLE_AUTOMATION_TEST(FTSTSSFirstWakeCompletePathTest,
    "TSTSS.FirstWake.CompleteOrderedLaunchToBerth",
    EAutomationTestFlags::EditorContext | EAutomationTestFlags::EngineFilter)
bool FTSTSSFirstWakeCompletePathTest::RunTest(const FString& Parameters)
{
    UTSTSSFirstWakeState* State = NewObject<UTSTSSFirstWakeState>();
    if (!TestNotNull(TEXT("State exists"), State)) return false;

    TestFalse(TEXT("Cannot hire before flyer"), State->AdvanceTo(ETSTSSFirstWakeBeat::IoniaHired));
    TestTrue(TEXT("Flyer"), State->AdvanceTo(ETSTSSFirstWakeBeat::FlyerDiscovered));
    TestTrue(TEXT("Ionia first"), State->AdvanceTo(ETSTSSFirstWakeBeat::IoniaHired));
    TestFalse(TEXT("No early launch"), State->AdvanceTo(ETSTSSFirstWakeBeat::Launched));
    TestTrue(TEXT("Board"), State->AdvanceTo(ETSTSSFirstWakeBeat::BoardedAureateWake));
    TestFalse(TEXT("Engineering requires all three checks"), State->AdvanceTo(ETSTSSFirstWakeBeat::EngineeringChecked));

    TestTrue(TEXT("Lift inspected"), State->InspectStation(ETSTSSInspectionStation::Lift));
    TestTrue(TEXT("Pressure inspected"), State->InspectStation(ETSTSSInspectionStation::Pressure));
    TestTrue(TEXT("Reserve inspected"), State->InspectStation(ETSTSSInspectionStation::Reserve));
    TestEqual(TEXT("All inspections recorded"), State->GetInspectionMask(), static_cast<uint8>(7));
    TestFalse(TEXT("Duplicate reserve inspection rejected"), State->InspectStation(ETSTSSInspectionStation::Reserve));
    TestTrue(TEXT("Engineering approved"), State->AdvanceTo(ETSTSSFirstWakeBeat::EngineeringChecked));
    TestTrue(TEXT("Launch"), State->AdvanceTo(ETSTSSFirstWakeBeat::Launched));
    TestTrue(TEXT("Sea contact milestone"), State->AdvanceTo(ETSTSSFirstWakeBeat::SeaContact));
    TestTrue(TEXT("Flotation confirmed"), State->AdvanceTo(ETSTSSFirstWakeBeat::FlotationConfirmed));
    TestTrue(TEXT("Empty reserve investigated"), State->AdvanceTo(ETSTSSFirstWakeBeat::EmptyReserveInspected));
    TestTrue(TEXT("Return to berth"), State->AdvanceTo(ETSTSSFirstWakeBeat::ReturnedToBerth));
    TestFalse(TEXT("Terminal beat cannot repeat"), State->AdvanceTo(ETSTSSFirstWakeBeat::ReturnedToBerth));
    TestFalse(TEXT("Inspections cannot be repeated after launch"), State->InspectStation(ETSTSSInspectionStation::Lift));
    return true;
}

IMPLEMENT_SIMPLE_AUTOMATION_TEST(FTSTSSFirstWakeRestoreIntegrityTest,
    "TSTSS.FirstWake.RejectedRestorePreservesState",
    EAutomationTestFlags::EditorContext | EAutomationTestFlags::EngineFilter)
bool FTSTSSFirstWakeRestoreIntegrityTest::RunTest(const FString& Parameters)
{
    UTSTSSFirstWakeState* State = NewObject<UTSTSSFirstWakeState>();
    if (!TestNotNull(TEXT("State exists"), State)) return false;
    TestTrue(TEXT("Restore valid boarding"), State->Restore(true, ETSTSSFirstWakeBeat::BoardedAureateWake, 1));
    TestFalse(TEXT("Cannot restore post-engineering with incomplete checks"),
        State->Restore(true, ETSTSSFirstWakeBeat::Launched, 1));
    TestEqual(TEXT("Failed restore preserves beat"), State->GetCurrentBeat(), ETSTSSFirstWakeBeat::BoardedAureateWake);
    TestEqual(TEXT("Failed restore preserves inspections"), State->GetInspectionMask(), static_cast<uint8>(1));
    TestTrue(TEXT("Failed restore preserves started"), State->HasStarted());
    TestFalse(TEXT("Reject invalid inspection bit"), State->Restore(true, ETSTSSFirstWakeBeat::BoardedAureateWake, 8));
    TestEqual(TEXT("Invalid mask does not mutate"), State->GetInspectionMask(), static_cast<uint8>(1));

    UTSTSSSaveGame* Save = NewObject<UTSTSSSaveGame>();
    if (!TestNotNull(TEXT("Save exists"), Save)) return false;
    Save->bFirstWakeStarted = true;
    Save->FirstWakeBeat = ETSTSSFirstWakeBeat::Launched;
    Save->InspectionMask = 1;
    TestFalse(TEXT("Save cannot bypass inspection gate"), Save->IsStructurallyValid());
    Save->InspectionMask = 7;
    TestTrue(TEXT("Properly inspected save valid"), Save->IsStructurallyValid());
    Save->InspectionMask = 8;
    TestFalse(TEXT("Unsupported inspection bit invalid"), Save->IsStructurallyValid());
    return true;
}
#endif
