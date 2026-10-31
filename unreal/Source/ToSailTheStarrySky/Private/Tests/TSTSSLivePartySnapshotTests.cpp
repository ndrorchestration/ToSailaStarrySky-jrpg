#include "Misc/AutomationTest.h"
#include "TSTSSSaveGame.h"

#if WITH_DEV_AUTOMATION_TESTS
IMPLEMENT_SIMPLE_AUTOMATION_TEST(FTSTSSLivePartySnapshotTest,
    "TSTSS.Save.LivePartySnapshotIsValidated",
    EAutomationTestFlags::EditorContext | EAutomationTestFlags::EngineFilter)
bool FTSTSSLivePartySnapshotTest::RunTest(const FString& Parameters)
{
    UTSTSSSaveGame* Save = NewObject<UTSTSSSaveGame>();
    if (!TestNotNull(TEXT("Save fixture"), Save)) return false;
    FTSTSSCombatant Ender;
    Ender.CharacterId = TEXT("Ender");
    Ender.Health = 11;
    Ender.MaxHealth = 20;
    Ender.Resource = 3;
    Ender.MaxResource = 8;
    Ender.Attack = 5;
    const TArray<FTSTSSCombatant> Valid{Ender};
    if (!TestTrue(TEXT("Valid party snapshot accepted"), Save->CapturePartyRoster(Valid))) return false;
    if (!TestEqual(TEXT("Party size"), Save->PartyRoster.Num(), 1)) return false;
    TestEqual(TEXT("Live HP snapshotted"), Save->PartyRoster[0].Health, 11);

    TestFalse(TEXT("Empty party does not erase progress"),
        Save->CapturePartyRoster(TArray<FTSTSSCombatant>()));
    TestEqual(TEXT("Preserve roster after empty input"), Save->PartyRoster.Num(), 1);

    FTSTSSCombatant Invalid = Ender;
    Invalid.Health = 100;
    TestFalse(TEXT("Invalid health rejected"), Save->CapturePartyRoster({Invalid}));
    TestEqual(TEXT("Rejected health does not mutate roster"), Save->PartyRoster[0].Health, 11);

    TestFalse(TEXT("Duplicate character identities rejected"),
        Save->CapturePartyRoster({Ender, Ender}));
    TestEqual(TEXT("Rejected duplicates preserve roster"), Save->PartyRoster.Num(), 1);
    return true;
}
#endif
