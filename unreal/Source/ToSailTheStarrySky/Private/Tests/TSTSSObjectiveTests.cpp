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
    TestFalse(TEXT("Boarding changes objective"), Lift == Unstarted);
    TestEqual(TEXT("Objective read does not mutate inspection mask"), State->GetInspectionMask(), static_cast<uint8>(0));
    if (!TestTrue(TEXT("Lift inspected"), State->InspectStation(ETSTSSInspectionStation::Lift))) return false;
    const FString Pressure = State->GetCurrentObjective().ToString();
    TestFalse(TEXT("Pressure objective differs from lift"), Pressure == Lift);
    if (!TestTrue(TEXT("Pressure inspected"), State->InspectStation(ETSTSSInspectionStation::Pressure))) return false;
    const FString Reserve = State->GetCurrentObjective().ToString();
    TestFalse(TEXT("Reserve objective differs from pressure"), Reserve == Pressure);
    if (!TestTrue(TEXT("Reserve inspected"), State->InspectStation(ETSTSSInspectionStation::Reserve))) return false;
    TestFalse(TEXT("Signoff objective differs from reserve"), State->GetCurrentObjective().ToString() == Reserve);
    TestEqual(TEXT("Objective never auto-advances story"), State->GetCurrentBeat(),
        ETSTSSFirstWakeBeat::BoardedAureateWake);

    if (!TestTrue(TEXT("Restore mid-flight"), State->Restore(true, ETSTSSFirstWakeBeat::Launched, 7))) return false;
    TestFalse(TEXT("Flight objective restored"), State->GetCurrentObjective().ToString().IsEmpty());
    State->Reset();
    TestEqual(TEXT("Reset restores beginning objective"), State->GetCurrentObjective().ToString(), Unstarted);
    return true;
}
#endif
