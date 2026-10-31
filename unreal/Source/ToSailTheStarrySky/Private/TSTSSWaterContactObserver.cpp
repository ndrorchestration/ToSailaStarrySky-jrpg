#include "TSTSSWaterContactObserver.h"
#include "TSTSSExplorerCharacter.h"
#include "TSTSSFirstWakeState.h"
#include "Components/BoxComponent.h"
#include "Components/PrimitiveComponent.h"

ATSTSSWaterContactObserver::ATSTSSWaterContactObserver()
{
    PrimaryActorTick.bCanEverTick = true;
    ContactVolume = CreateDefaultSubobject<UBoxComponent>(TEXT("WaterContactVolume"));
    SetRootComponent(ContactVolume);
    ContactVolume->SetCollisionEnabled(ECollisionEnabled::QueryOnly);
    ContactVolume->SetCollisionResponseToAllChannels(ECR_Ignore);
    ContactVolume->SetCollisionResponseToChannel(ECC_PhysicsBody, ECR_Overlap);
    ContactVolume->SetCollisionResponseToChannel(ECC_WorldDynamic, ECR_Overlap);
    ContactVolume->SetGenerateOverlapEvents(true);
}

void ATSTSSWaterContactObserver::BeginPlay()
{
    Super::BeginPlay();
    // A designer must supply a real simulating ship component and player.
    // Do not automatically find a ship by name or promote decorative overlap.
    if (!IsValid(VesselBody) || !IsValid(Explorer))
    {
        SetActorTickEnabled(false);
    }
}

bool ATSTSSWaterContactObserver::IsStableSample(
    const bool bOverlapping, const bool bSimulatingPhysics,
    const float VerticalSpeedCmPerSecond, const float MaximumVerticalSpeed)
{
    return bOverlapping && bSimulatingPhysics &&
        FMath::IsFinite(VerticalSpeedCmPerSecond) &&
        FMath::IsFinite(MaximumVerticalSpeed) &&
        MaximumVerticalSpeed > 0.f &&
        FMath::Abs(VerticalSpeedCmPerSecond) <= MaximumVerticalSpeed;
}

void ATSTSSWaterContactObserver::Tick(float DeltaSeconds)
{
    Super::Tick(DeltaSeconds);

    if (!IsValid(VesselBody) || !IsValid(Explorer) || !IsValid(ContactVolume) ||
        !FMath::IsFinite(DeltaSeconds) || DeltaSeconds <= 0.f || DeltaSeconds > 0.25f)
    {
        StableElapsedSeconds = 0.f;
        return;
    }

    UTSTSSFirstWakeState* State = Explorer->GetFirstWakeState();
    const bool bOverlap = ContactVolume->IsOverlappingComponent(VesselBody);
    const bool bPhysics = VesselBody->IsSimulatingPhysics();

    if (!IsValid(State) || !State->HasStarted() || !bOverlap || !bPhysics)
    {
        StableElapsedSeconds = 0.f;
        return;
    }

    if (State->GetCurrentBeat() == ETSTSSFirstWakeBeat::Launched)
    {
        // The state transition is triggered by observed vessel-water overlap.
        if (!State->AdvanceFromWaterObservation(ETSTSSFirstWakeBeat::SeaContact))
        {
            StableElapsedSeconds = 0.f;
            return;
        }
    }
    if (State->GetCurrentBeat() != ETSTSSFirstWakeBeat::SeaContact)
    {
        StableElapsedSeconds = 0.f;
        return;
    }

    const float VerticalSpeed = VesselBody->GetPhysicsLinearVelocity().Z;
    if (!IsStableSample(bOverlap, bPhysics, VerticalSpeed, MaximumVerticalSpeedCmPerSecond))
    {
        StableElapsedSeconds = 0.f;
        return;
    }

    // A continuously overlapping, low-vertical-speed rigid body is a minimal
    // flotation proxy, NOT yet a production buoyancy solver.
    StableElapsedSeconds += DeltaSeconds;
    if (StableElapsedSeconds >= FMath::Max(0.25f, RequiredStableSeconds))
    {
        if (State->AdvanceFromWaterObservation(ETSTSSFirstWakeBeat::FlotationConfirmed))
        {
            SetActorTickEnabled(false);
        }
    }
}
