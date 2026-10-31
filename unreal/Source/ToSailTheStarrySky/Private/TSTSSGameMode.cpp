#include "TSTSSGameMode.h"
#include "TSTSSExplorerCharacter.h"
#include "TSTSSFirstWakeHUD.h"

ATSTSSGameMode::ATSTSSGameMode()
{
    DefaultPawnClass = ATSTSSExplorerCharacter::StaticClass();
    HUDClass = ATSTSSFirstWakeHUD::StaticClass();
}
