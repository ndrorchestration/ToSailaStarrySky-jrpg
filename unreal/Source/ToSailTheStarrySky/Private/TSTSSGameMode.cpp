#include "TSTSSGameMode.h"
#include "TSTSSExplorerCharacter.h"

ATSTSSGameMode::ATSTSSGameMode()
{
    DefaultPawnClass = ATSTSSExplorerCharacter::StaticClass();
}
