#pragma once

#include "CoreMinimal.h"
#include "UObject/Object.h"
#include "TSTSSFirstWakeState.generated.h"

// Ordered story milestones. A debug map may drive these without claiming canonical completion.
UENUM(BlueprintType)
enum class ETSTSSFirstWakeBeat : uint8
{
    FlyerDiscovered,
    IoniaHired,
    BoardedAureateWake,
    EngineeringChecked,
    Launched,
    SeaContact,
    FlotationConfirmed,
    EmptyReserveInspected,
    ReturnedToBerth
};

UCLASS(BlueprintType)
class TOSAILTHESTARRYSKY_API UTSTSSFirstWakeState : public UObject
{
    GENERATED_BODY()
public:
    UFUNCTION(BlueprintCallable, Category="TSTSS|First Wake")
    bool AdvanceTo(ETSTSSFirstWakeBeat RequestedBeat);

    UFUNCTION(BlueprintPure, Category="TSTSS|First Wake")
    ETSTSSFirstWakeBeat GetCurrentBeat() const { return CurrentBeat; }

    UFUNCTION(BlueprintPure, Category="TSTSS|First Wake")
    bool HasStarted() const { return bStarted; }

    UFUNCTION(BlueprintCallable, Category="TSTSS|First Wake")
    void Reset();

    // Restores only in-range states; avoids replaying milestone side effects.
    UFUNCTION(BlueprintCallable, Category="TSTSS|First Wake")
    bool Restore(bool bWasStarted, ETSTSSFirstWakeBeat SavedBeat);

private:
    UPROPERTY(VisibleAnywhere, Category="TSTSS|First Wake")
    ETSTSSFirstWakeBeat CurrentBeat = ETSTSSFirstWakeBeat::FlyerDiscovered;

    UPROPERTY(VisibleAnywhere, Category="TSTSS|First Wake")
    bool bStarted = false;
};
