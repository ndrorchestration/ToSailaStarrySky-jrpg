#pragma once
#include "CoreMinimal.h"
#include "Kismet/BlueprintFunctionLibrary.h"
#include "TSTSSCombatRules.h"
#include "TSTSSPartyCombatBridge.generated.h"

// Uses the existing deterministic combat resolver and save's roster validation.
// Never mutate a caller's party on failure.
UCLASS()
class TOSAILTHESTARRYSKY_API UTSTSSPartyCombatBridge : public UBlueprintFunctionLibrary
{
    GENERATED_BODY()
public:
    static bool TryApplyValidatedAction(const TArray<FTSTSSCombatant>& Current,
        const FTSTSSCombatAction& Action, TArray<FTSTSSCombatant>& OutNext);
};
