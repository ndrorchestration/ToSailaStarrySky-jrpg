#include "Misc/AutomationTest.h"
#include "TSTSSSaveGame.h"
#include "TSTSSFirstWakeState.h"

#if WITH_DEV_AUTOMATION_TESTS
IMPLEMENT_SIMPLE_AUTOMATION_TEST(FTSTSSFirstWakeRosterPreservationTest,
    "TSTSS.Save.FirstWakeCheckpointPreservesParty",
    EAutomationTestFlags::EditorContext | EAutomationTestFlags::EngineFilter)
bool FTSTSSFirstWakeRosterPreservationTest::RunTest(const FString& Parameters)
{
    UTSTSSSaveGame* Save = NewObject<UTSTSSSaveGame>();
    UTSTSSFirstWakeState* Story = NewObject<UTSTSSFirstWakeState>();
    if (!TestNotNull(TEXT("Save"), Save) || !TestNotNull(TEXT("Story"), Story)) return false;

    FTSTSSCombatant Ender;
    Ender.CharacterId = TEXT("Ender");
    Ender.Health = 13;
    Ender.MaxHealth = 25;
    Ender.Resource = 4;
    Ender.MaxResource = 12;
    Ender.Attack = 7;
    Ender.Defense = 3;
    Save->PartyRoster.Add(Ender);

    if (!TestTrue(TEXT("Restore inspected preflight"), Story->Restore(
        true, ETSTSSFirstWakeBeat::EngineeringChecked, 0x07))) return false;
    if (!TestTrue(TEXT("Checkpoint captures valid story"), Save->CaptureFirstWake(Story))) return false;
    TestTrue(TEXT("Save valid after capture"), Save->IsStructurallyValid());
    TestEqual(TEXT("Story checkpoint captured"), Save->FirstWakeBeat,
        ETSTSSFirstWakeBeat::EngineeringChecked);
    TestEqual(TEXT("Inspections captured"), Save->InspectionMask, static_cast<uint8>(7));
    if (!TestEqual(TEXT("Party remains present"), Save->PartyRoster.Num(), 1)) return false;
    TestEqual(TEXT("Ender remains in party"), Save->PartyRoster[0].CharacterId, FName(TEXT("Ender")));
    TestEqual(TEXT("Party HP retained"), Save->PartyRoster[0].Health, 13);
    TestEqual(TEXT("Party resource retained"), Save->PartyRoster[0].Resource, 4);
    TestEqual(TEXT("Party attack retained"), Save->PartyRoster[0].Attack, 7);
    TestEqual(TEXT("Party defense retained"), Save->PartyRoster[0].Defense, 3);

    const ETSTSSFirstWakeBeat Before = Save->FirstWakeBeat;
    const uint8 BeforeMask = Save->InspectionMask;
    TestFalse(TEXT("Null story cannot mutate save"), Save->CaptureFirstWake(nullptr));
    TestEqual(TEXT("Rejected capture preserves story beat"), Save->FirstWakeBeat, Before);
    TestEqual(TEXT("Rejected capture preserves inspection mask"), Save->InspectionMask, BeforeMask);

    if (!TestTrue(TEXT("Restore returned-to-berth state"), Story->Restore(
        true, ETSTSSFirstWakeBeat::ReturnedToBerth, 0x07))) return false;
    if (!TestTrue(TEXT("Second capture succeeds"), Save->CaptureFirstWake(Story))) return false;
    TestEqual(TEXT("Updated progression"), Save->FirstWakeBeat,
        ETSTSSFirstWakeBeat::ReturnedToBerth);
    TestEqual(TEXT("Roster size unchanged by second capture"), Save->PartyRoster.Num(), 1);
    TestEqual(TEXT("Roster HP unchanged by second capture"), Save->PartyRoster[0].Health, 13);
    return true;
}
#endif
