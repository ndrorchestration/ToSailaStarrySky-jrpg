#pragma once

#include "CoreMinimal.h"
#include "GameFramework/Actor.h"
#include "TSTSSWaterContactObserver.generated.h"

class UBoxComponent;
class UPrimitiveComponent;
class ATSTSSExplorerCharacter;

// Prototype bridge: an actual overlapping, simulating vessel component supplies
// evidence to the existing First Wake state. No tick means no artificial progress.
UCLASS()
class TOSAILTHESTARRYSKY_API ATSTSSWaterContactObserver : public AActor
{
    GENERATED_BODY()

public:
    ATSTSSWaterContactObserver();
    virtual void BeginPlay() override;
    virtual void Tick(float DeltaSeconds) override;

    UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="TSTSS|First Wake|Water")
    TObjectPtr<UBoxComponent> ContactVolume;

    // Must be the real ship physics primitive, not a decorative mesh/scene proxy.
    UPROPERTY(EditInstanceOnly, BlueprintReadOnly, Category="TSTSS|First Wake|Water")
    TObjectPtr<UPrimitiveComponent> VesselBody;

    UPROPERTY(EditInstanceOnly, BlueprintReadOnly, Category="TSTSS|First Wake|Water")
    TObjectPtr<ATSTSSExplorerCharacter> Explorer;

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category="TSTSS|First Wake|Water",
        meta=(ClampMin="0.25", ClampMax="10.0"))
    float RequiredStableSeconds = 1.5f;

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category="TSTSS|First Wake|Water",
        meta=(ClampMin="1.0"))
    float MaximumVerticalSpeedCmPerSecond = 35.f;

    // Bounded provisional vessel-center proximity to the water-volume top.
    // This is not a buoyancy displacement or seabed-clearance measurement.
    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category="TSTSS|First Wake|Water",
        meta=(ClampMin="1.0"))
    float MaximumCenterDistanceFromWaterlineCm = 150.f;

    static bool IsNearWaterSurface(float VesselCenterZ, float SurfaceZ,
        float MaximumCenterDistance);

    // Unit-testable policy: called only after overlap, physics and state checks.
    static bool IsStableSample(bool bOverlapping, bool bSimulatingPhysics,
        float VerticalSpeedCmPerSecond, float MaximumVerticalSpeed);

private:
    float StableElapsedSeconds = 0.f;
};
