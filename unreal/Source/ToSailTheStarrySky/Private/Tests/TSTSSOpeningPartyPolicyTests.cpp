#include "Misc/AutomationTest.h"
#include "TSTSSSaveGame.h"

#if WITH_DEV_AUTOMATION_TESTS
IMPLEMENT_SIMPLE_AUTOMATION_TEST(FTSTSSOpeningPartyPolicyTest,
    "TSTSS.Save.OpeningPartyRequiresEnder",
    EAutomationTestFlags::EditorContext | EAutomationTestFlags::EngineFilter)
bool FTSTSSOpeningPartyPolicyTest::RunTest(const FString& Parameters)
{
    FTSTSSCombatant Ender;
    Ender.CharacterId = TEXT("Ender");
    Ender.Health = 12;
    Ender.MaxHealth = 20;
    Ender.Resource = 4;
    Ender.MaxResource = 10;
    Ender.Attack = 5;
    Ender.Defense = 3;
    TestTrue(TEXT("Authored positive Ender stats allowed"),
        UTSTSSSaveGame::IsValidFirstWakeStartingEnder(Ender));

    FTSTSSCombatant Wrong = Ender;
    Wrong.CharacterId = TEXT("Ionia");
    TestFalse(TEXT("Opening party cannot start with Ionia"),
        UTSTSSSaveGame::IsValidFirstWakeStartingEnder(Wrong));

    Wrong = Ender;
    Wrong.Health = 0;
    TestFalse(TEXT("Opening Ender must be alive"),
        UTSTSSSaveGame::IsValidFirstWakeStartingEnder(Wrong));

    Wrong = Ender;
    Wrong.Health = 30;
    TestFalse(TEXT("Opening HP cannot exceed maximum"),
        UTSTSSSaveGame::IsValidFirstWakeStartingEnder(Wrong));

    Wrong = Ender;
    Wrong.Resource = 20;
    TestFalse(TEXT("Opening resources must be in range"),
        UTSTSSSaveGame::IsValidFirstWakeStartingEnder(Wrong));

    Wrong = Ender;
    Wrong.CharacterId = NAME_None;
    TestFalse(TEXT("Unidentified opening character refused"),
        UTSTSSSaveGame::IsValidFirstWakeStartingEnder(Wrong));
    return true;
}
#endif
