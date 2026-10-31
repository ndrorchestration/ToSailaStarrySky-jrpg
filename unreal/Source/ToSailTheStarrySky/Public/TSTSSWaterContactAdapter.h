#pragma once
#include "CoreMinimal.h"
#include "GameFramework/Actor.h"
#include "TSTSSWaterLandingGate.h"
#include "TSTSSWaterContactAdapter.generated.h"

// Prototype observer: a physics-enabled hull mesh must overlap a separately
// configured water-volume actor tagged TSTSSWaterVolume.
UCLASS()
class TOSAILTHESTARRYSKY_API ATSTSSWaterContactAdapter : public AActor
{
    GENERATED_BODY()
public:
    ATSTSSWaterContactAdapter();
    virtual void BeginPlay() override;
    virtual void Tick(float DeltaSeconds) override;

    UFUNCTION(BlueprintCallable, Category="TSTSS|Water")
    void BindStory(UTSTSSFirstWakeState* InStory);

    UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="TSTSS|Water")
    TObjectPtr<class UStaticMeshComponent> Hull;

protected:
    UPROPERTY(Transient) TObjectPtr<UTSTSSFirstWakeState> Story;
    UPROPERTY(Transient) TObjectPtr<UTSTSSWaterLandingGate> Gate;
    UPROPERTY(EditAnywhere, Category="TSTSS|Water")
    FName WaterVolumeTag = TEXT("TSTSSWaterVolume");
};
