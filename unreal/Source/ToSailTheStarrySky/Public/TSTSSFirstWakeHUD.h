#pragma once

#include "CoreMinimal.h"
#include "GameFramework/HUD.h"
#include "TSTSSFirstWakeHUD.generated.h"

// Native temporary objective overlay for the First Wake vertical slice.
// A later UMG HUD may replace its presentation while reusing the same state API.
UCLASS()
class TOSAILTHESTARRYSKY_API ATSTSSFirstWakeHUD : public AHUD
{
    GENERATED_BODY()

public:
    virtual void DrawHUD() override;

    UPROPERTY(EditDefaultsOnly, Category="TSTSS|First Wake|UX", meta=(ClampMin="0.5", ClampMax="3.0"))
    float ObjectiveScale = 1.25f;

    UPROPERTY(EditDefaultsOnly, Category="TSTSS|First Wake|UX")
    bool bShowObjective = true;
};
