#pragma once
#include "CoreMinimal.h"
#include "Components/ActorComponent.h"
#include "TSTSSFirstWakeState.h"
#include "AureateWakeWaterObserverComponent.generated.h"

class AAureateWakePreviewActor;

/** Opt-in observer. No simulated contact or synthetic flotation receipts. */
UCLASS(ClassGroup=(TSTSS), meta=(BlueprintSpawnableComponent))
class TOSAILTHESTARRYSKY_API UAureateWakeWaterObserverComponent : public UActorComponent
{
    GENERATED_BODY()
public:
    UAureateWakeWaterObserverComponent();
    virtual void BeginPlay() override;
    virtual void TickComponent(float DeltaTime, ELevelTick TickType, FActorComponentTickFunction* Function) override;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="Aureate Wake|Water")
    TObjectPtr<AAureateWakePreviewActor> VisualShip;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="Aureate Wake|Water")
    TObjectPtr<UTSTSSFirstWakeState> Story;

};
