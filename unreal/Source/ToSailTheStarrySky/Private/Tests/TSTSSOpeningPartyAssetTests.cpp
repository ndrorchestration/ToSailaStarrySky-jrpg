#include "Misc/AutomationTest.h"
#include "TSTSSOpeningPartyData.h"

#if WITH_DEV_AUTOMATION_TESTS
IMPLEMENT_SIMPLE_AUTOMATION_TEST(FTSTSSOpeningPartyAssetGateTest,
    "TSTSS.Save.OpeningPartyAssetRequiresReview",
    EAutomationTestFlags::EditorContext | EAutomationTestFlags::EngineFilter)
bool FTSTSSOpeningPartyAssetGateTest::RunTest(const FString& Parameters)
{
    UTSTSSOpeningPartyData* Data = NewObject<UTSTSSOpeningPartyData>();
    if (!TestNotNull(TEXT("Opening data asset"), Data)) return false;

    TestFalse(TEXT("Unreviewed blank default cannot initialize"), Data->IsReady());

    FTSTSSCombatant Fixture;
    Fixture.CharacterId = TEXT("Ender");
    Fixture.Health = 12;
    Fixture.MaxHealth = 20;
    Fixture.Resource = 3;
    Fixture.MaxResource = 8;
    Fixture.Attack = 4;
    Fixture.Defense = 2;

    Data->StartingEnder = Fixture;
    TestFalse(TEXT("Valid fixture without review cannot initialize"), Data->IsReady());

    Data->bReviewedForPrototype = true;
    TestTrue(TEXT("Reviewed valid fixture is structurally eligible"), Data->IsReady());

    Data->StartingEnder.CharacterId = TEXT("Ionia");
    TestFalse(TEXT("Reviewed wrong protagonist still rejected"), Data->IsReady());

    Data->StartingEnder = Fixture;
    Data->StartingEnder.Health = 0;
    TestFalse(TEXT("Reviewed invalid HP still rejected"), Data->IsReady());

    Data->StartingEnder = Fixture;
    Data->bReviewedForPrototype = false;
    TestFalse(TEXT("Removing review flag blocks initialization"), Data->IsReady());

    // Fixture values are fabricated for validation only, never production data.
    return true;
}
#endif
