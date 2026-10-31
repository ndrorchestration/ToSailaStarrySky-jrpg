#include "Misc/AutomationTest.h"
#include "TSTSSFirstWakeHUD.h"
#include "TSTSSGameMode.h"
#include "TSTSSExplorerCharacter.h"

#if WITH_DEV_AUTOMATION_TESTS
IMPLEMENT_SIMPLE_AUTOMATION_TEST(FTSTSSFirstWakeHUDWiringTest,
    "TSTSS.FirstWake.DefaultHUDWiring",
    EAutomationTestFlags::EditorContext | EAutomationTestFlags::EngineFilter)

bool FTSTSSFirstWakeHUDWiringTest::RunTest(const FString& Parameters)
{
    const ATSTSSGameMode* Mode = GetDefault<ATSTSSGameMode>();
    if (!TestNotNull(TEXT("Default game mode"), Mode)) return false;
    TestTrue(TEXT("Native objective HUD selected"),
        Mode->HUDClass == ATSTSSFirstWakeHUD::StaticClass());
    TestTrue(TEXT("Explorer pawn remains selected"),
        Mode->DefaultPawnClass == ATSTSSExplorerCharacter::StaticClass());

    const ATSTSSFirstWakeHUD* HUD = GetDefault<ATSTSSFirstWakeHUD>();
    if (!TestNotNull(TEXT("Native objective HUD class"), HUD)) return false;
    TestTrue(TEXT("Objective HUD visible by default"), HUD->bShowObjective);
    TestTrue(TEXT("Legible objective scale set"), HUD->ObjectiveScale >= 1.f);
    return true;
}
#endif
