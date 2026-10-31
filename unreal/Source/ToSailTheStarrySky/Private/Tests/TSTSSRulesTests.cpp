#include "Misc/AutomationTest.h"
#include "TSTSSFirstWakeState.h"
#include "TSTSSCombatRules.h"
#include "TSTSSSaveGame.h"
#include "TSTSSPersistence.h"

#if WITH_DEV_AUTOMATION_TESTS

IMPLEMENT_SIMPLE_AUTOMATION_TEST(FTSTSSFirstWakeOrderTest,
    "TSTSS.FirstWake.RequiresOrderedMilestones",
    EAutomationTestFlags::EditorContext | EAutomationTestFlags::EngineFilter)
bool FTSTSSFirstWakeOrderTest::RunTest(const FString& Parameters)
{
    UTSTSSFirstWakeState* State = NewObject<UTSTSSFirstWakeState>();
    TestFalse(TEXT("Cannot skip directly to boarding"), State->AdvanceTo(ETSTSSFirstWakeBeat::BoardedAureateWake));
    TestTrue(TEXT("Starts with flyer"), State->AdvanceTo(ETSTSSFirstWakeBeat::FlyerDiscovered));
    TestFalse(TEXT("Cannot repeat flyer"), State->AdvanceTo(ETSTSSFirstWakeBeat::FlyerDiscovered));
    TestTrue(TEXT("Ionia hired next"), State->AdvanceTo(ETSTSSFirstWakeBeat::IoniaHired));
    TestFalse(TEXT("Cannot skip checks and launch"), State->AdvanceTo(ETSTSSFirstWakeBeat::SeaContact));
    State->Reset();
    TestFalse(TEXT("Reset clears started state"), State->HasStarted());
    return true;
}

IMPLEMENT_SIMPLE_AUTOMATION_TEST(FTSTSSCombatAtomicTest,
    "TSTSS.Combat.TransactionalActions",
    EAutomationTestFlags::EditorContext | EAutomationTestFlags::EngineFilter)
bool FTSTSSCombatAtomicTest::RunTest(const FString& Parameters)
{
    FTSTSSCombatant Ender;
    Ender.CharacterId = TEXT("Ender");
    Ender.Health = 6; Ender.MaxHealth = 20;
    Ender.Resource = 5; Ender.MaxResource = 10;
    Ender.Attack = 4;
    FTSTSSCombatant Ionia;
    Ionia.CharacterId = TEXT("Ionia");
    Ionia.Health = 15; Ionia.MaxHealth = 20;
    Ionia.Resource = 4; Ionia.MaxResource = 10;
    Ionia.Attack = 3; Ionia.Defense = 2;
    const TArray<FTSTSSCombatant> Initial{Ender, Ionia};
    TArray<FTSTSSCombatant> After;
    FTSTSSCombatAction Action;
    Action.ActorId = TEXT("Ender");
    Action.TargetId = TEXT("Ender");
    Action.ResourceCost = 2;
    Action.Power = 3;
    Action.bHealing = true;
    TestTrue(TEXT("Self-heal is legal"), UTSTSSCombatRules::TryApplyAction(Initial, Action, After));
    TestEqual(TEXT("Self-heal applies resource"), After[0].Resource, 3);
    TestEqual(TEXT("Self-heal applies healing"), After[0].Health, 13);
    TestEqual(TEXT("Initial remains untouched"), Initial[0].Health, 6);
    Action.ResourceCost = 99;
    const int32 PriorHealth = After[0].Health;
    TestFalse(TEXT("Unaffordable action rejected"), UTSTSSCombatRules::TryApplyAction(Initial, Action, After));
    TestEqual(TEXT("Rejected action leaves output unchanged"), After[0].Health, PriorHealth);
    Action.ResourceCost = 1;
    Action.bHealing = false;
    Action.TargetId = TEXT("Ionia");
    TestTrue(TEXT("Valid damage"), UTSTSSCombatRules::TryApplyAction(Initial, Action, After));
    TestEqual(TEXT("Defense accounted for"), After[1].Health, 10);
    return true;
}

// Regression coverage for the UE-side atomic resolver migrated from the Godot study.
IMPLEMENT_SIMPLE_AUTOMATION_TEST(FTSTSSCombatRejectionTest,
    "TSTSS.Combat.RejectsInvalidActionsWithoutMutation",
    EAutomationTestFlags::EditorContext | EAutomationTestFlags::EngineFilter)
bool FTSTSSCombatRejectionTest::RunTest(const FString& Parameters)
{
    FTSTSSCombatant Ender;
    Ender.CharacterId = TEXT("Ender");
    Ender.Health = 12; Ender.MaxHealth = 20;
    Ender.Resource = 3; Ender.MaxResource = 5;
    Ender.Attack = 2;

    FTSTSSCombatant Foe;
    Foe.CharacterId = TEXT("Foe");
    Foe.Health = 10; Foe.MaxHealth = 10;
    Foe.Resource = 0; Foe.MaxResource = 0;
    const TArray<FTSTSSCombatant> Initial{Ender, Foe};
    TArray<FTSTSSCombatant> Output = Initial;
    FTSTSSCombatAction Action;
    Action.ActorId = TEXT("Ender");
    Action.TargetId = TEXT("Foe");
    Action.Power = 2;

    Action.ResourceCost = 4;
    TestFalse(TEXT("Unaffordable action is rejected"), UTSTSSCombatRules::TryApplyAction(Initial, Action, Output));
    TestEqual(TEXT("Rejected action preserves output HP"), Output[1].Health, 10);
    TestEqual(TEXT("Rejected action preserves output resources"), Output[0].Resource, 3);

    Action.ResourceCost = 0;
    Action.TargetId = TEXT("Missing");
    TestFalse(TEXT("Unknown target is rejected"), UTSTSSCombatRules::TryApplyAction(Initial, Action, Output));
    TestEqual(TEXT("Unknown target preserves output"), Output[1].Health, 10);

    Action.TargetId = TEXT("Foe");
    Action.Power = -1;
    TestFalse(TEXT("Negative power is rejected"), UTSTSSCombatRules::TryApplyAction(Initial, Action, Output));
    Action.Power = 2;

    TArray<FTSTSSCombatant> Duplicates{Ender, Ender, Foe};
    TestFalse(TEXT("Duplicate roster IDs are rejected"), UTSTSSCombatRules::TryApplyAction(Duplicates, Action, Output));
    TestEqual(TEXT("Duplicate roster rejection preserves output size"), Output.Num(), 2);
    TestEqual(TEXT("Input roster remains unchanged"), Initial[1].Health, 10);
    return true;
}

IMPLEMENT_SIMPLE_AUTOMATION_TEST(FTSTSSSaveValidationTest,
    "TSTSS.Save.RejectsUnsupportedSchema",
    EAutomationTestFlags::EditorContext | EAutomationTestFlags::EngineFilter)
bool FTSTSSSaveValidationTest::RunTest(const FString& Parameters)
{
    UTSTSSSaveGame* Save = NewObject<UTSTSSSaveGame>();
    TestTrue(TEXT("Default save is structurally valid"), Save->IsStructurallyValid());
    Save->SchemaVersion = 999;
    TestFalse(TEXT("Future schema is rejected"), Save->IsStructurallyValid());
    Save->SchemaVersion = UTSTSSSaveGame::CurrentVersion;
    Save->FirstWakeBeat = ETSTSSFirstWakeBeat::Launched;
    TestFalse(TEXT("Unstarted late milestone is rejected"), Save->IsStructurallyValid());
    return true;
}
IMPLEMENT_SIMPLE_AUTOMATION_TEST(FTSTSSSaveSlotGuardTest,
    "TSTSS.Save.RejectsUnsafeSlots",
    EAutomationTestFlags::EditorContext | EAutomationTestFlags::EngineFilter)
bool FTSTSSSaveSlotGuardTest::RunTest(const FString& Parameters)
{
    TestTrue(TEXT("Safe slot accepted"), UTSTSSPersistence::IsValidSlotName(TEXT("first_wake_01")));
    TestFalse(TEXT("Path traversal rejected"), UTSTSSPersistence::IsValidSlotName(TEXT("../escape")));
    TestFalse(TEXT("Empty slot rejected"), UTSTSSPersistence::IsValidSlotName(TEXT("")));
    TestFalse(TEXT("Slash rejected"), UTSTSSPersistence::IsValidSlotName(TEXT("a/b")));
    TestFalse(TEXT("Spaces rejected"), UTSTSSPersistence::IsValidSlotName(TEXT("my save")));
    TestTrue(TEXT("Missing invalid slot returns null"), UTSTSSPersistence::LoadProgress(TEXT("../escape")) == nullptr);
    UTSTSSSaveGame* Save = NewObject<UTSTSSSaveGame>();
    Save->SchemaVersion = 99;
    TestFalse(TEXT("Invalid payload write rejected"), UTSTSSPersistence::SaveProgress(TEXT("test_slot"), Save));
    return true;
}
#endif
