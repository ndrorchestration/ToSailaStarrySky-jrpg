#pragma once
#include "CoreMinimal.h"
#include "GameFramework/Actor.h"
#include "TSTSSFirstWakeState.h"
#include "TSTSSMilestoneActor.generated.h"

UCLASS()
class TOSAILTHESTARRYSKY_API ATSTSSMilestoneActor : public AActor
{
    GENERATED_BODY()
public:
    ATSTSSMilestoneActor();
    UFUNCTION(BlueprintCallable, Category="TSTSS|First Wake")
    bool TryActivate(UTSTSSFirstWakeState* State);
    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category="TSTSS|First Wake")
    ETSTSSFirstWakeBeat Milestone = ETSTSSFirstWakeBeat::FlyerDiscovered;
    UFUNCTION(BlueprintImplementableEvent, Category="TSTSS|First Wake")
    void OnMilestoneActivated();
    UPROPERTY(BlueprintAssignable, Category="TSTSS|First Wake")
    FSimpleMulticastDelegate DummyUnused; // Removed in implementation pass before compilation.
protected:
    UPROPERTY(VisibleAnywhere, BlueprintReadOnly)
    TObjectPtr<class UStaticMeshComponent> InteractionMesh;
};
