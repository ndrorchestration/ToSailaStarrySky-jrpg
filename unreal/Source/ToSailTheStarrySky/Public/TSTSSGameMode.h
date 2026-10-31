#pragma once
#include "CoreMinimal.h"
#include "GameFramework/GameModeBase.h"
class UTSTSSOpeningPartyData;
class ATSTSSExplorerCharacter;
#include "TSTSSGameMode.generated.h"

UCLASS()
class TOSAILTHESTARRYSKY_API ATSTSSGameMode : public AGameModeBase
{
    GENERATED_BODY()
public:
    ATSTSSGameMode();

    UFUNCTION(BlueprintCallable, Category="TSTSS|Opening Party")
    bool TryInitializeNewExplorer(ATSTSSExplorerCharacter* Explorer) const;

protected:
    UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category="TSTSS|Opening Party")
    TObjectPtr<UTSTSSOpeningPartyData> OpeningPartyData;
};
