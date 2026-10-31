#include "Misc/AutomationTest.h"
#include "TSTSSCombatAbilities.h"

#if WITH_DEV_AUTOMATION_TESTS
IMPLEMENT_SIMPLE_AUTOMATION_TEST(FTSTSSAbilityGateTest,
    "TSTSS.Combat.AbilityAuthorization",
    EAutomationTestFlags::EditorContext | EAutomationTestFlags::EngineFilter)
bool FTSTSSAbilityGateTest::RunTest(const FString& Parameters)
{
    FTSTSSCombatant Ender;
    Ender.CharacterId = TEXT("Ender"); Ender.Health = 10; Ender.MaxHealth = 20;
    Ender.Resource = 5; Ender.MaxResource = 5;
    FTSTSSCombatant Foe = Ender;
    Foe.CharacterId = TEXT("Foe"); Foe.Health = 8; Foe.MaxHealth = 8;
    FTSTSSCombatTurnState State;
    TestTrue(TEXT("Begin"), FTSTSSCombatTurns::TryBegin(
        {Ender, Foe}, {TEXT("Ender"), TEXT("Foe")}, State));
    FTSTSSAbilitySpec Strike;
    Strike.AbilityId = TEXT("Strike"); Strike.Power = 3; Strike.Cost = 2;
    Strike.Target = FTSTSSAbilitySpec::ETarget::Enemy;
    TMap<FName, FTSTSSAbilitySpec> Catalog;
    Catalog.Add(Strike.AbilityId, Strike);
    TMap<FName, TSet<FName>> Learned;
    TMap<FName, FName> Teams;
    Teams.Add(TEXT("Ender"), TEXT("crew")); Teams.Add(TEXT("Foe"), TEXT("enemy"));
    FTSTSSCombatTurnState Output;
    TestFalse(TEXT("Unlearned blocked"), FTSTSSCombatAbilities::TryUse(
        State, TEXT("Ender"), TEXT("Foe"), TEXT("Strike"), Catalog, Learned, Teams, Output));
    Learned.Add(TEXT("Ender"), TSet<FName>{TEXT("Strike")});
    TestFalse(TEXT("Enemy skill cannot target ally"), FTSTSSCombatAbilities::TryUse(
        State, TEXT("Ender"), TEXT("Ender"), TEXT("Strike"), Catalog, Learned, Teams, Output));
    TestTrue(TEXT("Learned enemy skill accepted"), FTSTSSCombatAbilities::TryUse(
        State, TEXT("Ender"), TEXT("Foe"), TEXT("Strike"), Catalog, Learned, Teams, Output));
    TestEqual(TEXT("Target damaged"), Output.Roster[1].Health, 4);
    TestEqual(TEXT("Resource spent"), Output.Roster[0].Resource, 3);
    TestEqual(TEXT("Input preserved"), State.Roster[1].Health, 8);
    return true;
}
#endif
