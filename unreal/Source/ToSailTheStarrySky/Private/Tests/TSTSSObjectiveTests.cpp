#include "Misc/AutomationTest.h"
#include "TSTSSFirstWakeState.h"

#if WITH_DEV_AUTOMATION_TESTS
IMPLEMENT_SIMPLE_AUTOMATION_TEST(FTSTSSFirstWakeObjectiveTest,
    "TSTSS.FirstWake.ObjectivesTrackStoryAndInspections",
    EAutomationTestFlags::EditorContext | EAutomationTestFlags::EngineFilter)
bool FTSTSSFirstWakeObjectiveTest::RunTest(const FString& Parameters)
{
    UTSTSSFirstWakeState* State = NewObject<UTSTSSFirstWakeState>();
    if (!TestNotNull(TEXT("State"), State)) return false;
    const FString Unstarted = State->GetCurrentObjective().ToString();
    TestFalse(TEXT("Unstarted objective populated"), Unstarted.IsEmpty());

    if (!TestTrue(TEXT("Flyer"), State->AdvanceTo(ETSTSSFirstWakeBeat::FlyerDiscovered))) return false;
    if (!TestTrue(TEXT("Ionia"), State->AdvanceTo(ETSTSSFirstWakeBeat::IoniaHired))) return false;
    if (!TestTrue(TEXT("Board"), State->AdvanceTo(ETSTSSFirstWakeBeat::BoardedAureateWake))) return false;
    const FString Lift = State->GetCurrentObjective().ToString();
    TestTrue(TEXT("Lift objective"), Lift.Contains(TEXT("lift")));
    TestEqual(TEXT("Objective read does not mutate inspection mask"), State->GetInspectionMask(), static_cast<uint8>(0));
    if (!TestTrue(TEXT("Lift inspected"), State->InspectStation(ETSTSSInspectionStation::Lift))) return false;
    TestTrue(TEXT("Pressure objective"), State->GetCurrentObjective().ToString().Contains(TEXT("pressure")));
    if (!TestTrue(TEXT("Pressure inspected"), State->InspectStation(ETSTSSInspectionStation::Pressure))) return false;
    TestTrue(TEXT("Reserve objective"), State->GetCurrentObjective().ToString().Contains(TEXT("reserve")));
    if (!TestTrue(TEXT("Reserve inspected"), State->InspectStation(ETSTSSInspectionStation::Reserve))) return false;
    TestTrue(TEXT("Signoff objective"), State->GetCurrentObjective().ToString().Contains(TEXT("engineering checks")));
    TestEqual(TEXT("Objective never auto-advances story"), State->GetCurrentBeat(),
        ETSTSSFirstWakeBeat::BoardedAureateWake);

    if (!TestTrue(TEXT("Restore mid-flight"), State->Restore(true, ETSTSSFirstWakeBeat::Launched, 7))) return false;
    TestTrue(TEXT("Flight objective restored"), State->GetCurrentObjective().ToString().Contains(TEXT("first flight")));
    State->Reset();
    TestEqual(TEXT("Reset restores beginning objective"), State->GetCurrentObjective().ToString(), Unstarted);
    return true;
}
#endif
