#pragma once
#include "CoreMinimal.h"
#include "Engine/DataAsset.h"
#include "TSTSSCombatRules.h"
#include "TSTSSOpeningPartyData.generated.h"

// Author-controlled First Wake balance data. No numeric canon is embedded in code.
UCLASS(BlueprintType)
class TOSAILTHESTARRYSKY_API UTSTSSOpeningPartyData : public UDataAsset
{
    GENERATED_BODY()
public:
    // Explicit review flag: default Unreal struct values are never enough.
    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category="TSTSS|Opening Party")
    bool bReviewedForPrototype = false;

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category="TSTSS|Opening Party")
    FTSTSSCombatant StartingEnder;

    UFUNCTION(BlueprintPure, Category="TSTSS|Opening Party")
    bool IsReady() const;
};
