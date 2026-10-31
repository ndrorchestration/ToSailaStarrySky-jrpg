#include "Misc/AutomationTest.h"
#include "TSTSSPartyCombatBridge.h"

#if WITH_DEV_AUTOMATION_TESTS
IMPLEMENT_SIMPLE_AUTOMATION_TEST(FTSTSSLivePartyCombatBridgeTest,
    "TSTSS.Combat.LivePartyBridgeTransactions",
    EAutomationTestFlags::EditorContext | EAutomationTestFlags::EngineFilter)
bool FTSTSSLivePartyCombatBridgeTest::RunTest(const FString& Parameters)
{
    FTSTSSCombatant Ender;
    Ender.CharacterId = TEXT("Ender");
    Ender.Health = 12; Ender.MaxHealth = 20;
    Ender.Resource = 5; Ender.MaxResource = 10;
    Ender.Attack = 4;
    FTSTSSCombatant Ionia;
    Ionia.CharacterId = TEXT("Ionia");
    Ionia.Health = 18; Ionia.MaxHealth = 20;
    Ionia.Resource = 4; Ionia.MaxResource = 10;
    Ionia.Defense = 2;
    const TArray<FTSTSSCombatant> Initial{Ender, Ionia};
    TArray<FTSTSSCombatant> Output = Initial;

    FTSTSSCombatAction Action;
    Action.ActorId = TEXT("Ender");
    Action.TargetId = TEXT("Ionia");
    Action.Power = 3;
    Action.ResourceCost = 2;
    if (!TestTrue(TEXT("Valid action accepted"),
        UTSTSSPartyCombatBridge::TryApplyValidatedAction(Initial, Action, Output))) return false;
    if (!TestEqual(TEXT("Complete roster retained"), Output.Num(), 2)) return false;
    TestEqual(TEXT("Ender's resource spent"), Output[0].Resource, 3);
    TestEqual(TEXT("Ionia takes bounded damage"), Output[1].Health, 13);
    TestEqual(TEXT("Original roster remains unchanged"), Initial[1].Health, 18);

    Action.ResourceCost = 99;
    TestFalse(TEXT("Unaffordable action rejected"),
        UTSTSSPartyCombatBridge::TryApplyValidatedAction(Initial, Action, Output));
    TestEqual(TEXT("Failure leaves prior successful output unchanged"), Output[1].Health, 13);
    TestEqual(TEXT("Rejected action doesn't refund previous resource"), Output[0].Resource, 3);

    Action.ResourceCost = 0;
    Action.TargetId = TEXT("Missing");
    TestFalse(TEXT("Unknown target rejected"),
        UTSTSSPartyCombatBridge::TryApplyValidatedAction(Initial, Action, Output));
    TestEqual(TEXT("Unknown target leaves output unchanged"), Output[1].Health, 13);
    return true;
}
#endif
