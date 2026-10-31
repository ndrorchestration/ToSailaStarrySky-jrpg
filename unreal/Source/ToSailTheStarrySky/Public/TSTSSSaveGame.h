#pragma once

#include "CoreMinimal.h"
#include "GameFramework/SaveGame.h"
#include "TSTSSCombatRules.h"
#include "TSTSSFirstWakeState.h"
#include "TSTSSSaveGame.generated.h"

// Versioned save payload; do not silently load unknown future versions.
UCLASS(BlueprintType)
class TOSAILTHESTARRYSKY_API UTSTSSSaveGame : public USaveGame
{
    GENERATED_BODY()
public:
    static constexpr int32 CurrentVersion = 2;

    UPROPERTY(VisibleAnywhere, BlueprintReadOnly, SaveGame, Category="TSTSS|Save")
    int32 SchemaVersion = CurrentVersion;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, SaveGame, Category="TSTSS|Save")
    bool bFirstWakeStarted = false;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, SaveGame, Category="TSTSS|Save")
    ETSTSSFirstWakeBeat FirstWakeBeat = ETSTSSFirstWakeBeat::FlyerDiscovered;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, SaveGame, Category="TSTSS|Save")
    TArray<FTSTSSCombatant> PartyRoster;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, SaveGame, Category="TSTSS|Save")
    uint8 InspectionMask = 0;

    UFUNCTION(BlueprintPure, Category="TSTSS|Save")
    bool IsSupportedVersion() const { return SchemaVersion == CurrentVersion; }

    UFUNCTION(BlueprintPure, Category="TSTSS|Save")
    bool IsStructurallyValid() const;

    // Update only story fields, retaining existing party stats and future payload data.
    // Reject invalid source state without modifying this save.
    bool CaptureFirstWake(const UTSTSSFirstWakeState* State);

    // Validate an explicitly provided live roster before replacing stored stats.
    bool CapturePartyRoster(const TArray<FTSTSSCombatant>& Roster);

    // Story checkpoints require either an explicitly initialized live party
    // or an existing valid saved party. Never create an empty-party checkpoint.
    bool CanCheckpointParty(bool bLivePartyInitialized) const;

    // Validates creator-supplied opening stats; does not choose balance values.
    static bool IsValidFirstWakeStartingEnder(const FTSTSSCombatant& StartingEnder);
};
