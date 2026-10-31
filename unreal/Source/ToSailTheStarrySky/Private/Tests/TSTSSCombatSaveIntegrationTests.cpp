#include "Misc/AutomationTest.h"
#include "Misc/Guid.h"
#include "Kismet/GameplayStatics.h"
#include "TSTSSPartyCombatBridge.h"
#include "TSTSSPersistence.h"
#include "TSTSSSaveGame.h"
#include "TSTSSFirstWakeState.h"

#if WITH_DEV_AUTOMATION_TESTS
IMPLEMENT_SIMPLE_AUTOMATION_TEST(FTSTSSCombatSaveRoundTripTest,
    "TSTSS.Integration.CombatThenCheckpointThenReload",
    EAutomationTestFlags::EditorContext | EAutomationTestFlags::EngineFilter)

bool FTSTSSCombatSaveRoundTripTest::RunTest(const FString& Parameters)
{
    // Unique test-owned slot; a collision means abort, never overwrite.
    const FString Slot = TEXT("tstss_qa_") + FGuid::NewGuid().ToString(EGuidFormats::Digits);
    if (!TestTrue(TEXT("Test slot name valid"), UTSTSSPersistence::IsValidSlotName(Slot)) ||
        !TestFalse(TEXT("Test slot unoccupied"), UGameplayStatics::DoesSaveGameExist(Slot, 0)))
    {
        return false;
    }

    FTSTSSCombatant Ender;
    Ender.CharacterId = TEXT("Ender");
    Ender.Health = 14; Ender.MaxHealth = 20;
    Ender.Resource = 7; Ender.MaxResource = 10;
    Ender.Attack = 4; Ender.Defense = 1;
    FTSTSSCombatant Ionia;
    Ionia.CharacterId = TEXT("Ionia");
    Ionia.Health = 16; Ionia.MaxHealth = 24;
    Ionia.Resource = 3; Ionia.MaxResource = 8;
    Ionia.Attack = 3; Ionia.Defense = 2;
    const TArray<FTSTSSCombatant> Initial{Ender, Ionia};

    FTSTSSCombatAction Heal;
    Heal.ActorId = TEXT("Ender");
    Heal.TargetId = TEXT("Ionia");
    Heal.ResourceCost = 2;
    Heal.Power = 2;
    Heal.bHealing = true;

    TArray<FTSTSSCombatant> AfterCombat;
    if (!TestTrue(TEXT("Authoritative combat action applied"),
        UTSTSSPartyCombatBridge::TryApplyValidatedAction(Initial, Heal, AfterCombat)))
    {
        return false;
    }
    if (!TestEqual(TEXT("Party remains complete"), AfterCombat.Num(), 2))
    {
        return false;
    }
    bool bPass = true;
    bPass &= TestEqual(TEXT("Ender's live resource reduced"), AfterCombat[0].Resource, 5);
    bPass &= TestEqual(TEXT("Ionia's live health restored"), AfterCombat[1].Health, 22);
    bPass &= TestEqual(TEXT("Original Ender resource unchanged"), Initial[0].Resource, 7);
    bPass &= TestEqual(TEXT("Original Ionia health unchanged"), Initial[1].Health, 16);

    FTSTSSCombatAction Invalid = Heal;
    Invalid.ResourceCost = 99;
    TArray<FTSTSSCombatant> RejectedOutput = AfterCombat;
    bPass &= TestFalse(TEXT("Unaffordable action rejected"),
        UTSTSSPartyCombatBridge::TryApplyValidatedAction(AfterCombat, Invalid, RejectedOutput));
    bPass &= TestEqual(TEXT("Rejected action does not mutate target health"),
        RejectedOutput[1].Health, 22);
    bPass &= TestEqual(TEXT("Rejected action does not alter resource"),
        RejectedOutput[0].Resource, 5);

    UTSTSSFirstWakeState* Story = NewObject<UTSTSSFirstWakeState>();
    UTSTSSSaveGame* Snapshot = NewObject<UTSTSSSaveGame>();
    if (!TestNotNull(TEXT("Story fixture"), Story) ||
        !TestNotNull(TEXT("Save fixture"), Snapshot))
    {
        return false;
    }
    if (!TestTrue(TEXT("Restore valid boarding checkpoint"),
            Story->Restore(true, ETSTSSFirstWakeBeat::BoardedAureateWake, 0x01)) ||
        !TestTrue(TEXT("Capture story checkpoint"), Snapshot->CaptureFirstWake(Story)) ||
        !TestTrue(TEXT("Capture post-combat roster"), Snapshot->CapturePartyRoster(AfterCombat)))
    {
        return false;
    }

    bool bWroteSlot = UTSTSSPersistence::SaveProgress(Slot, Snapshot);
    bPass &= TestTrue(TEXT("Post-combat checkpoint written to disk"), bWroteSlot);
    if (bWroteSlot)
    {
        const UTSTSSSaveGame* Reloaded = UTSTSSPersistence::LoadProgress(Slot);
        if (TestNotNull(TEXT("Checkpoint reloaded"), Reloaded))
        {
            bPass &= TestEqual(TEXT("Save schema preserved"), Reloaded->SchemaVersion,
                UTSTSSSaveGame::CurrentVersion);
            bPass &= TestEqual(TEXT("First Wake beat preserved"), Reloaded->FirstWakeBeat,
                ETSTSSFirstWakeBeat::BoardedAureateWake);
            bPass &= TestEqual(TEXT("Inspection evidence preserved"), Reloaded->InspectionMask,
                static_cast<uint8>(1));
            if (TestEqual(TEXT("Two party members persisted"), Reloaded->PartyRoster.Num(), 2))
            {
                bPass &= TestEqual(TEXT("Ender identity"), Reloaded->PartyRoster[0].CharacterId,
                    FName(TEXT("Ender")));
                bPass &= TestEqual(TEXT("Ionia identity"), Reloaded->PartyRoster[1].CharacterId,
                    FName(TEXT("Ionia")));
                bPass &= TestEqual(TEXT("Ender resource after combat persisted"),
                    Reloaded->PartyRoster[0].Resource, 5);
                bPass &= TestEqual(TEXT("Ionia healing persisted"),
                    Reloaded->PartyRoster[1].Health, 22);
                bPass &= TestEqual(TEXT("Ionia max health preserved"),
                    Reloaded->PartyRoster[1].MaxHealth, 24);
            }
            else
            {
                bPass = false;
            }
        }
        else
        {
            bPass = false;
        }
    }

    // A failed write may have created a partial file. Delete only this
    // generated unique slot, and check cleanup if one exists.
    if (UGameplayStatics::DoesSaveGameExist(Slot, 0))
    {
        bPass &= TestTrue(TEXT("Owned temporary slot deleted"),
            UGameplayStatics::DeleteGameInSlot(Slot, 0));
    }
    bPass &= TestFalse(TEXT("Temporary slot absent after cleanup"),
        UGameplayStatics::DoesSaveGameExist(Slot, 0));
    return bPass;
}
#endif
