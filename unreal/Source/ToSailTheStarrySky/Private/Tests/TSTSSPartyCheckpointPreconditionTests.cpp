#include "Misc/AutomationTest.h"
#include "TSTSSSaveGame.h"

#if WITH_DEV_AUTOMATION_TESTS
IMPLEMENT_SIMPLE_AUTOMATION_TEST(FTSTSSPartyCheckpointPreconditionTest,
    "TSTSS.Save.CheckpointRequiresParty",
    EAutomationTestFlags::EditorContext | EAutomationTestFlags::EngineFilter)
bool FTSTSSPartyCheckpointPreconditionTest::RunTest(const FString& Parameters)
{
    UTSTSSSaveGame* Save = NewObject<UTSTSSSaveGame>();
    if (!TestNotNull(TEXT("Save fixture"), Save)) return false;

    TestTrue(TEXT("Default empty save structurally allowed for migration"),
        Save->IsStructurallyValid());
    TestFalse(TEXT("New checkpoint without live or saved party refused"),
        Save->CanCheckpointParty(false));
    TestTrue(TEXT("Initialized live party may enter capture path"),
        Save->CanCheckpointParty(true));

    FTSTSSCombatant Ender;
    Ender.CharacterId = TEXT("Ender");
    Ender.Health = 12;
    Ender.MaxHealth = 20;
    Ender.Resource = 3;
    Ender.MaxResource = 8;
    if (!TestTrue(TEXT("Stored Ender roster validated"),
        Save->CapturePartyRoster({Ender}))) return false;

    TestTrue(TEXT("Story-only checkpoint preserves existing party"),
        Save->CanCheckpointParty(false));
    TestTrue(TEXT("Live checkpoint also accepted"),
        Save->CanCheckpointParty(true));

    Save->SchemaVersion = 999;
    TestFalse(TEXT("Incompatible schema blocked despite party"),
        Save->CanCheckpointParty(false));
    TestFalse(TEXT("Incompatible schema blocked despite live party"),
        Save->CanCheckpointParty(true));
    TestEqual(TEXT("Refusal does not erase stored member"), Save->PartyRoster.Num(), 1);
    return true;
}
#endif
