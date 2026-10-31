#include "Misc/AutomationTest.h"
#include "Misc/Guid.h"
#include "Kismet/GameplayStatics.h"
#include "TSTSSPersistence.h"
#include "TSTSSSaveGame.h"
#include "TSTSSFirstWakeState.h"

#if WITH_DEV_AUTOMATION_TESTS
IMPLEMENT_SIMPLE_AUTOMATION_TEST(FTSTSSDiskRosterCheckpointTest,
    "TSTSS.Save.DiskRoundTripPreservesPartyOnStoryUpdate",
    EAutomationTestFlags::EditorContext | EAutomationTestFlags::EngineFilter)

bool FTSTSSDiskRosterCheckpointTest::RunTest(const FString& Parameters)
{
    // Per-run unique slot: no fixed fixture collisions or player slot overwrite.
    const FString Slot = TEXT("tstss_qa_") + FGuid::NewGuid().ToString(EGuidFormats::Digits);
    if (!TestTrue(TEXT("Generated test slot allowed"), UTSTSSPersistence::IsValidSlotName(Slot)))
        return false;
    if (!TestFalse(TEXT("Never overwrite an existing slot"), UGameplayStatics::DoesSaveGameExist(Slot, 0)))
        return false;

    UTSTSSSaveGame* Initial = NewObject<UTSTSSSaveGame>();
    if (!TestNotNull(TEXT("Initial save object"), Initial)) return false;

    Initial->bFirstWakeStarted = true;
    Initial->FirstWakeBeat = ETSTSSFirstWakeBeat::BoardedAureateWake;
    Initial->InspectionMask = 0x01;
    FTSTSSCombatant Ender;
    Ender.CharacterId = TEXT("Ender");
    Ender.Health = 13; Ender.MaxHealth = 25;
    Ender.Resource = 4; Ender.MaxResource = 12;
    Ender.Attack = 7; Ender.Defense = 3;
    Initial->PartyRoster.Add(Ender);

    const bool bInitialWrite = UTSTSSPersistence::SaveProgress(Slot, Initial);
    if (!TestTrue(TEXT("Initial disk write"), bInitialWrite))
    {
        // Clean up only the slot created specifically for this test.
        if (UGameplayStatics::DoesSaveGameExist(Slot, 0))
            UGameplayStatics::DeleteGameInSlot(Slot, 0);
        return false;
    }

    bool bAllValid = true;
    UTSTSSSaveGame* Loaded = UTSTSSPersistence::LoadProgress(Slot);
    bAllValid &= TestNotNull(TEXT("Reloaded initial disk payload"), Loaded);
    if (Loaded)
    {
        bAllValid &= TestEqual(TEXT("Initial party size"), Loaded->PartyRoster.Num(), 1);
        bAllValid &= TestEqual(TEXT("Initial story beat"), Loaded->FirstWakeBeat,
            ETSTSSFirstWakeBeat::BoardedAureateWake);

        UTSTSSFirstWakeState* Story = NewObject<UTSTSSFirstWakeState>();
        const bool bRestored = Story && Story->Restore(
            true, ETSTSSFirstWakeBeat::EngineeringChecked, 0x07);
        bAllValid &= TestTrue(TEXT("New inspected story is valid"), bRestored);
        if (bRestored)
        {
            const bool bCaptured = Loaded->CaptureFirstWake(Story);
            bAllValid &= TestTrue(TEXT("Capture story without replacing party"), bCaptured);
            if (bCaptured)
                bAllValid &= TestTrue(TEXT("Write updated payload to same test slot"),
                    UTSTSSPersistence::SaveProgress(Slot, Loaded));
        }
    }

    UTSTSSSaveGame* Reloaded = UTSTSSPersistence::LoadProgress(Slot);
    bAllValid &= TestNotNull(TEXT("Reloaded updated disk payload"), Reloaded);
    if (Reloaded)
    {
        bAllValid &= TestEqual(TEXT("Current schema retained"), Reloaded->SchemaVersion,
            UTSTSSSaveGame::CurrentVersion);
        bAllValid &= TestEqual(TEXT("Updated story persisted"), Reloaded->FirstWakeBeat,
            ETSTSSFirstWakeBeat::EngineeringChecked);
        bAllValid &= TestEqual(TEXT("All three inspections persisted"),
            Reloaded->InspectionMask, static_cast<uint8>(7));
        if (TestEqual(TEXT("Party retained after second disk write"),
            Reloaded->PartyRoster.Num(), 1))
        {
            const FTSTSSCombatant& Member = Reloaded->PartyRoster[0];
            bAllValid &= TestEqual(TEXT("Character identity retained"), Member.CharacterId,
                FName(TEXT("Ender")));
            bAllValid &= TestEqual(TEXT("Health retained"), Member.Health, 13);
            bAllValid &= TestEqual(TEXT("Max health retained"), Member.MaxHealth, 25);
            bAllValid &= TestEqual(TEXT("Resource retained"), Member.Resource, 4);
            bAllValid &= TestEqual(TEXT("Max resource retained"), Member.MaxResource, 12);
            bAllValid &= TestEqual(TEXT("Attack retained"), Member.Attack, 7);
            bAllValid &= TestEqual(TEXT("Defense retained"), Member.Defense, 3);
        }
        else
        {
            bAllValid = false;
        }
    }

    bAllValid &= TestTrue(TEXT("Temporary slot removed"),
        UGameplayStatics::DeleteGameInSlot(Slot, 0));
    return bAllValid;
}
#endif
